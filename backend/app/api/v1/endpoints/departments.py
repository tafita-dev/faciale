from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException, status
from app.api import deps
from app.db.mongodb import get_database
from app.models.department import Department, DepartmentCreate
import uuid
from datetime import datetime, timezone

router = APIRouter()

@router.post("/", response_model=Department, status_code=status.HTTP_201_CREATED)
async def create_department(
    *,
    db: Any = Depends(get_database),
    department_in: DepartmentCreate,
    current_user: dict = Depends(deps.check_org_admin)
) -> Any:
    """
    Create new department.
    """
    org_id = current_user.get("org_id")
    
    existing_dept = await db["departments"].find_one({
        "name": department_in.name,
        "org_id": org_id
    })
    if existing_dept:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Department with this name already exists in your organization.",
        )
    
    dept_obj = {
        "_id": str(uuid.uuid4()),
        "name": department_in.name,
        "org_id": org_id,
        "created_at": datetime.now(timezone.utc)
    }
    
    await db["departments"].insert_one(dept_obj)
    return dept_obj

@router.get("/", response_model=List[Department])
async def list_departments(
    *,
    db: Any = Depends(get_database),
    current_user: dict = Depends(deps.check_org_user)
) -> Any:
    """
    List departments for the current organization.
    """
    org_id = current_user.get("org_id")
    
    cursor = db["departments"].find({"org_id": org_id})
    departments = await cursor.to_list(length=100)
    return departments
