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
    current_user: dict = Depends(deps.check_org_user),
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
    
    if result["status"] == "failed":
        if result["reason"] == "spoof_detected":
            return {
                "success": False,
                "message": "Liveness failed. Please try again.",
                "data": {"score": result["score"]}
            }
        elif result["reason"] == "no_match":
            return {
                "success": False,
                "message": "User not found.",
                "data": {"score": result["score"]}
            }
            
    # 3. Handle success and Debouncing
    employee_id = result["employee_id"]
    
    # Check for recent successful check-in (Debouncing)
    last_log = await attendance_repo.get_last_success_log(org_id, employee_id)
    if last_log:
        now = datetime.now(timezone.utc)
        diff = (now - last_log.timestamp).total_seconds()
        if diff < 60:
            return {
                "success": False,
                "message": f"Already checked in {int(diff)} seconds ago.",
                "data": {
                    "employee_id": employee_id,
                    "timestamp": last_log.timestamp
                }
            }
            
    # Fetch employee name for the response
    employee = await employee_repo.get_employee(employee_id)
    employee_name = employee.name if employee else "Unknown"
    
    action = "checked in" if result.get("type") == "entry" else "checked out"
    
    return {
        "success": True,
        "message": f"Success: {employee_name} {action}.",
        "data": {
            "employee_id": employee_id,
            "employee_name": employee_name,
            "type": result.get("type"),
            "score": result["score"],
            "timestamp": datetime.now(timezone.utc)
        }
    }
