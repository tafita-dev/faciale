from typing import Any, List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query, File, UploadFile
from app.api import deps
from app.db.mongodb import get_database
from app.models.employee import Employee, EmployeeCreate
from app.api.v1.endpoints.departments import check_org_admin
from app.services import enrollment
from app.core.config import settings
import uuid
from datetime import datetime, timezone

router = APIRouter()

@router.post("/", response_model=Employee, status_code=status.HTTP_201_CREATED)
async def create_employee(
    *,
    db: Any = Depends(get_database),
    employee_in: EmployeeCreate,
    current_user: dict = Depends(check_org_admin)
) -> Any:
    """
    Create new employee.
    """
    org_id = current_user.get("org_id")
    
    # Verify department exists and belongs to the same organization
    department = await db["departments"].find_one({
        "_id": employee_in.dept_id,
        "org_id": org_id
    })
    
    if not department:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Department not found or does not belong to your organization.",
        )
    
    emp_obj = {
        "_id": str(uuid.uuid4()),
        "name": employee_in.name,
        "dept_id": employee_in.dept_id,
        "org_id": org_id,
        "is_active": True,
        "is_enrolled": False,
        "created_at": datetime.now(timezone.utc)
    }
    
    await db["employees"].insert_one(emp_obj)
    return emp_obj

@router.get("/", response_model=List[Employee])
async def list_employees(
    *,
    db: Any = Depends(get_database),
    dept_id: Optional[str] = Query(None),
    current_user: dict = Depends(check_org_admin)
) -> Any:
    """
    List employees for the current organization, optionally filtered by department.
    """
    org_id = current_user.get("org_id")
    
    query = {"org_id": org_id}
    if dept_id:
        query["dept_id"] = dept_id
        
    cursor = db["employees"].find(query)
    employees = await cursor.to_list(length=100)
    return employees

@router.post("/{employee_id}/enroll", status_code=status.HTTP_202_ACCEPTED)
async def enroll_employee(
    *,
    db: Any = Depends(get_database),
    employee_id: str,
    file: UploadFile = File(...),
    current_user: dict = Depends(check_org_admin)
) -> Any:
    """
    Upload a reference photo for an employee and start the enrollment process.
    """
    org_id = current_user.get("org_id")
    
    # 1. Verify employee exists and belongs to the same organization
    employee = await db["employees"].find_one({
        "_id": employee_id,
        "org_id": org_id
    })
    
    if not employee:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Employee not found in your organization",
        )
    
    # 2. Validate file type
    if file.content_type not in ["image/jpeg", "image/png"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid file type. Only JPEG and PNG are allowed.",
        )
    
    # 3. Limit file size
    contents = await file.read()
    if len(contents) > settings.MAX_CONTENT_LENGTH:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"File too large. Maximum size is {settings.MAX_CONTENT_LENGTH // (1024*1024)}MB.",
        )
    await file.seek(0) # Reset file pointer for the pipeline
    
    # 4. Start enrollment pipeline
    await enrollment.start_enrollment_pipeline(employee_id, file)
    
    return {"message": "Enrollment started", "employee_id": employee_id}
