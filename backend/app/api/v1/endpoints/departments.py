from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException, status
from app.api import deps
from app.db.mongodb import get_database
from app.models.department import Department, DepartmentCreate, DepartmentUpdate
import uuid
from datetime import datetime, timezone

router = APIRouter()

@router.post("/", response_model=Department, status_code=status.HTTP_201_CREATED, response_model_by_alias=True)
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

@router.get("/", response_model=List[Department], response_model_by_alias=True)
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

@router.put("/{dept_id}", response_model=Department, response_model_by_alias=True)
async def update_department(
    *,
    db: Any = Depends(get_database),
    dept_id: str,
    department_in: DepartmentUpdate,
    current_user: dict = Depends(deps.check_org_admin)
) -> Any:
    """
    Update a department.
    """
    org_id = current_user.get("org_id")
    
    existing_dept = await db["departments"].find_one({
        "_id": dept_id,
        "org_id": org_id
    })
    if not existing_dept:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Department not found.",
        )
    
    if department_in.name:
        # Check if new name already exists in org
        duplicate = await db["departments"].find_one({
            "name": department_in.name,
            "org_id": org_id,
            "_id": {"$ne": dept_id}
        })
        if duplicate:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Department with this name already exists in your organization.",
            )
        existing_dept["name"] = department_in.name

    await db["departments"].update_one(
        {"_id": dept_id},
        {"$set": {"name": existing_dept["name"]}}
    )
    
    return existing_dept

@router.delete("/{dept_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_department(
    *,
    db: Any = Depends(get_database),
    dept_id: str,
    current_user: dict = Depends(deps.check_org_admin)
):
    """
    Delete a department.
    """
    org_id = current_user.get("org_id")
    
    existing_dept = await db["departments"].find_one({
        "_id": dept_id,
        "org_id": org_id
    })
    if not existing_dept:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Department not found.",
        )
    
    # Check if department has employees
    employee = await db["employees"].find_one({"dept_id": dept_id})
    if employee:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Department still has employees. Please reassign them before deleting.",
        )
    
    await db["departments"].delete_one({"_id": dept_id, "org_id": org_id})
