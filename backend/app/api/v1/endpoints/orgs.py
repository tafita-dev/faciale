from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException, status
from app.api import deps
from app.db.mongodb import get_database
from app.models.org import Org, OrgCreate
from app.core import security
import uuid
from datetime import datetime, timezone

router = APIRouter()

@router.post("/", response_model=Org, status_code=status.HTTP_201_CREATED)
async def create_org(
    *,
    db: Any = Depends(get_database),
    org_in: OrgCreate,
    current_user: dict = Depends(deps.check_superadmin)
) -> Any:
    """
    Create new organization and its admin user.
    """
    existing_org = await db["organizations"].find_one({"name": org_in.name})
    if existing_org:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Organization with this name already exists.",
        )
    
    existing_user = await db["users"].find_one({"email": org_in.admin_email})
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="A user with this email already exists.",
        )
    
    org_id = str(uuid.uuid4())
    org_obj = {
        "_id": org_id,
        "name": org_in.name,
        "type": org_in.type,
        "logo_url": org_in.logo_url,
        "created_at": datetime.now(timezone.utc)
    }
    
    await db["organizations"].insert_one(org_obj)

    # Create Org Admin User
    admin_obj = {
        "_id": str(uuid.uuid4()),
        "email": org_in.admin_email,
        "name": org_in.admin_name,
        "password_hash": security.get_password_hash(org_in.admin_password),
        "role": "admin",
        "org_id": org_id,
        "created_at": datetime.now(timezone.utc)
    }
    await db["users"].insert_one(admin_obj)

    return org_obj

@router.get("/", response_model=List[Org])
async def list_orgs(
    *,
    db: Any = Depends(get_database),
    current_user: dict = Depends(deps.check_superadmin)
) -> Any:
    """
    List organizations.
    """
    cursor = db["organizations"].find()
    orgs = await cursor.to_list(length=100)
    return orgs

@router.delete("/{org_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_org(
    *,
    db: Any = Depends(get_database),
    org_id: str,
    current_user: dict = Depends(deps.check_superadmin)
) -> None:
    """
    Delete an organization.
    """
    org = await db["organizations"].find_one({"_id": org_id})
    if not org:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Organization not found",
        )
    
    await db["organizations"].delete_one({"_id": org_id})
    return None
