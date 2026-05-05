from typing import Any
from fastapi import APIRouter, Depends, HTTPException, status, File, UploadFile
from fastapi.responses import JSONResponse
from app.api import deps
from app.services.attendance import AttendanceService
from app.repositories.employee import EmployeeRepository
from app.repositories.attendance import AttendanceRepository
from datetime import datetime, timezone

router = APIRouter()

@router.post("/check-in")
async def check_in(
    *,
    file: UploadFile = File(...),
    current_user: dict = Depends(deps.check_only_user),
    attendance_service: AttendanceService = Depends(deps.get_attendance_service),
    employee_repo: EmployeeRepository = Depends(deps.get_employee_repository),
    attendance_repo: AttendanceRepository = Depends(deps.get_attendance_repository)
) -> Any:
    """
    Unified check-in endpoint for mobile clients.
    Performs liveness detection, facial matching, and logging in one call.
    Includes debouncing logic (60s).
    """
    org_id = current_user.get("org_id")
    user_id = current_user.get("_id")
    
    # 1. Basic file validation
    if file.content_type not in ["image/jpeg", "image/png"]:
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content={
                "success": False,
                "error": {
                    "code": "INVALID_FILE_TYPE",
                    "message": "Invalid file type. Only JPEG and PNG are allowed."
                }
            }
        )
    
    # 2. Process attendance (Liveness + Matching + Logging)
    contents = await file.read()
    try:
        result = await attendance_service.process_attendance(org_id, contents, user_id=user_id)
    except ValueError as e:
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content={
                "success": False,
                "error": {
                    "code": "INVALID_IMAGE_DATA",
                    "message": f"Invalid image data: {str(e)}"
                }
            }
        )
    
    # Handle service-level failures (Spoofing or No Match)
    if result.get("status") == "failed":
        reason = result.get("reason")
        message = "Attendance failed."
        if reason == "spoof_detected":
            message = "Liveness failed. Please try again."
        elif reason == "no_match":
            message = "User not found."
            
        return {
            "success": False,
            "message": message,
            "data": {"score": result.get("score", 0)}
        }
            
    # Fetch employee name for the response
    employee = await employee_repo.get_employee(employee_id)
    employee_name = employee.name if employee else "Unknown"

    # Determine the action type (defaulting to entry)
    action_type = result.get("type", "entry")

    # Message based on type
    if action_type == "entry":
        message = f"Bienvenue {employee_name}"
    else:
        message = f"Au revoir {employee_name}"

    return {
        "success": True,
        "message": message,
        "data": {
            "employee_id": employee_id,
            "employee_name": employee_name,
            "type": action_type, 
            "score": result.get("score"),
            "timestamp": datetime.now(timezone.utc)
        }
    }