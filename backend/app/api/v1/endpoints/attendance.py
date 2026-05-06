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
    force_type: str | None = None,
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
    
    # 0. Validate force_type
    if force_type and force_type not in ["entry", "exit"]:
        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            content={
                "success": False,
                "message": "force_type doit être 'entry' ou 'exit'",
                "ui": {"color": "red"}
            }
        )
    
    # 1. Basic validation
    if file.content_type not in ["image/jpeg", "image/png"]:
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content={
                "success": False,
                "message": "Type de fichier invalide. Seuls JPEG et PNG sont autorisés.",
                "ui": {"color": "red"}
            }
        )
    
    # 2. Size validation (max 5MB)
    MAX_SIZE = 5 * 1024 * 1024
    # Read a bit to check size without reading everything into memory if possible
    # but for UploadFile we usually have to read it.
    contents = await file.read()
    if len(contents) > MAX_SIZE:
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content={
                "success": False,
                "message": "Fichier trop volumineux (max 5Mo)",
                "ui": {"color": "red"}
            }
        )
    
    # 3. Process attendance (Liveness + Matching + Logging)
    try:
        result = await attendance_service.process_attendance(org_id, contents, user_id=user_id, force_type=force_type)
    except ValueError as e:
        error_msg = str(e)
        message = "Erreur de traitement"
        if "No face detected" in error_msg:
            message = "Aucun visage détecté"
        elif "Multiple faces detected" in error_msg:
            message = "Plusieurs visages détectés"

        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content={
                "success": False,
                "message": message,
                "ui": {"color": "red"}
            }
        )

    # Handle service-level failures (Spoofing or No Match)
    if result.get("status") == "failed":
        reason = result.get("reason")
        message = "Échec du pointage"
        if reason == "spoof_detected":
            message = "Vérification échouée"
        elif reason == "no_match":
            message = "Utilisateur non reconnu"

        return {
            "success": False,
            "message": message,
            "ui": {"color": "red"},
            "data": {"score": result.get("score", 0)}
        }

    # Success handling
    employee_id = result.get("employee_id")
    # Fetch employee name for the response
    employee = await employee_repo.get_employee(employee_id)
    employee_name = employee.name if employee else "Inconnu"

    # Determine the action type (defaulting to entry)
    action_type = result.get("type", "entry")

    # Message based on type
    if action_type == "entry":
        message = f"Bienvenue {employee_name}"
        ui = {"color": "green", "icon": "login"}
    else:
        message = f"Au revoir {employee_name}"
        ui = {"color": "blue", "icon": "logout"}

    return {
        "success": True,
        "message": message,
        "ui": ui,
        "data": {
            "employee_id": employee_id,
            "employee_name": employee_name,
            "type": action_type, 
            "score": result.get("score"),
            "timestamp": datetime.now(timezone.utc)
        }
    }