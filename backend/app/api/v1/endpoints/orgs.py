from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException, status, File, UploadFile
from app.api import deps
from app.db.mongodb import get_database
from app.models.org import Org, OrgCreate, OrgUpdate
from app.services.storage import StorageService, StorageServiceError, InvalidImageError
from app.core import security
import uuid
from datetime import datetime, timezone

router = APIRouter()

@router.post("/", response_model=Org, status_code=status.HTTP_201_CREATED, response_model_by_alias=True)
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
        "admin_email": org_in.admin_email,
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

@router.patch("/settings", response_model=Org, response_model_by_alias=True)
async def update_org_settings(
    *,
    db: Any = Depends(get_database),
    org_in: OrgUpdate,
    current_user: dict = Depends(deps.get_current_user)
) -> Any:
    """
    Update organization settings. Accessible by Org Admin.
    """
    org_id = current_user.get("org_id")
    if not org_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User is not associated with an organization",
        )
    
    org = await db["organizations"].find_one({"_id": org_id})
    if not org:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Organization not found",
        )
    
    update_data = org_in.model_dump(exclude_unset=True)
    if update_data:
        # If settings are provided, nested update might be needed depending on how we want to merge
        # For simplicity, we overwrite the settings if provided
        await db["organizations"].update_one({"_id": org_id}, {"$set": update_data})
    
    updated_org = await db["organizations"].find_one({"_id": org_id})
    return updated_org

@router.get("/", response_model=List[Org], response_model_by_alias=True)
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

@router.get("/{org_id}", response_model=Org, response_model_by_alias=True)
async def get_org(
    *,
    db: Any = Depends(get_database),
    org_id: str,
    current_user: dict = Depends(deps.get_current_user)
) -> Any:
    """
    Get organization details.
    """
    if current_user["role"] != "superadmin":
        if current_user.get("org_id") != org_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not enough permissions",
            )
    
    org = await db["organizations"].find_one({"_id": org_id})
    if not org:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Organization not found",
        )
    return org

@router.patch("/{org_id}", response_model=Org, response_model_by_alias=True)
async def update_org(
    *,
    db: Any = Depends(get_database),
    org_id: str,
    org_in: OrgUpdate,
    current_user: dict = Depends(deps.check_superadmin)
) -> Any:
    """
    Update an organization.
    """
    org = await db["organizations"].find_one({"_id": org_id})
    if not org:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Organization not found",
        )
    
    update_data = org_in.model_dump(exclude_unset=True)
    if update_data:
        await db["organizations"].update_one({"_id": org_id}, {"$set": update_data})
    
    updated_org = await db["organizations"].find_one({"_id": org_id})
    return updated_org

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

@router.post("/{org_id}/logo", response_model=Org, response_model_by_alias=True)
async def upload_org_logo(
    *,
    db: Any = Depends(get_database),
    org_id: str,
    file: UploadFile = File(...),
    current_user: dict = Depends(deps.get_current_user)
) -> Any:
    """
    Upload organization logo.
    """
    # Permission check: Superadmin or Org Admin of that org
    if current_user["role"] != "superadmin":
        if current_user.get("org_id") != org_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not enough permissions",
            )

    org = await db["organizations"].find_one({"_id": org_id})
    if not org:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Organization not found",
        )

    storage_service = StorageService()
    try:
        filename = await storage_service.save_logo(file)
    except (InvalidImageError, StorageServiceError) as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST if isinstance(e, InvalidImageError) else status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e),
        )

    logo_url = f"/uploads/{filename}"
    await db["organizations"].update_one({"_id": org_id}, {"$set": {"logo_url": logo_url}})
    
    updated_org = await db["organizations"].find_one({"_id": org_id})
    return updated_org
