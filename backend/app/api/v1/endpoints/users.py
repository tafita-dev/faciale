from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException, status
from app.api import deps
from app.db.mongodb import get_database
from app.models.user import User, UserCreate
from app.core import security
import uuid
from datetime import datetime, timezone

router = APIRouter()

@router.post("/", response_model=User, status_code=status.HTTP_201_CREATED)
async def create_user(
    *,
    db: Any = Depends(get_database),
    user_in: UserCreate,
    current_user: dict = Depends(deps.check_org_admin)
) -> Any:
    """
    Create a new user within the organization.
    """
    existing_user = await db["users"].find_one({"email": user_in.email})
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="A user with this email already exists.",
        )
    
    user_obj = {
        "_id": str(uuid.uuid4()),
        "email": user_in.email,
        "name": user_in.name,
        "password_hash": security.get_password_hash(user_in.password),
        "role": "user",
        "org_id": current_user["org_id"],
        "created_at": datetime.now(timezone.utc)
    }
    
    await db["users"].insert_one(user_obj)
    return user_obj

@router.get("/", response_model=List[User])
async def list_users(
    *,
    db: Any = Depends(get_database),
    current_user: dict = Depends(deps.check_org_admin)
) -> Any:
    """
    List users in the organization.
    """
    cursor = db["users"].find({"org_id": current_user["org_id"]})
    users = await cursor.to_list(length=100)
    return users
