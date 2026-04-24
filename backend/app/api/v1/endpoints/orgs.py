from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException, status
from app.api import deps
from app.db.mongodb import get_database
from app.models.org import Org, OrgCreate
import uuid
from datetime import datetime, timezone

router = APIRouter()

def check_admin(current_user: dict = Depends(deps.get_current_user)):
    if current_user.get("role") not in ["admin", "superadmin"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="The user doesn't have enough privileges",
        )
    return current_user

@router.post("/", response_model=Org, status_code=status.HTTP_201_CREATED)
async def create_org(
    *,
    db: Any = Depends(get_database),
    org_in: OrgCreate,
    current_user: dict = Depends(check_admin)
) -> Any:
    """
    Create new organization.
    """
    existing_org = await db["organizations"].find_one({"name": org_in.name})
    if existing_org:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Organization with this name already exists.",
        )
    
    org_obj = {
        "_id": str(uuid.uuid4()),
        "name": org_in.name,
        "type": org_in.type,
        "created_at": datetime.now(timezone.utc)
    }
    
    await db["organizations"].insert_one(org_obj)
    return org_obj

@router.get("/", response_model=List[Org])
async def list_orgs(
    *,
    db: Any = Depends(get_database),
    current_user: dict = Depends(check_admin)
) -> Any:
    """
    List organizations.
    """
    cursor = db["organizations"].find()
    orgs = await cursor.to_list(length=100)
    return orgs
