from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import StreamingResponse
from app.api import deps
from app.services.reporting_service import ReportingService
from typing import Any, Optional
from datetime import datetime

router = APIRouter()

@router.get("/stats", response_model=dict)
async def get_attendance_stats(
    user_id: Optional[str] = Query(None),
    current_user: dict = Depends(deps.check_org_user),
    reporting_service: ReportingService = Depends(deps.get_reporting_service)
) -> Any:
    """
    Get today's attendance statistics for the organization.
    Isolation: admin sees all (or filtered by user_id), user sees only their own.
    """
    if current_user["role"] == "user":
        effective_user_id = current_user["_id"]
    else:
        effective_user_id = user_id
        
    stats = await reporting_service.get_today_stats(current_user["org_id"], user_id=effective_user_id)
    return {
        "success": True,
        "data": stats
    }

@router.get("/logs", response_model=dict)
async def get_attendance_logs(
    page: int = Query(1, ge=1),
    size: int = Query(10, ge=1, le=100),
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    dept_id: Optional[str] = None,
    user_id: Optional[str] = Query(None),
    current_user: dict = Depends(deps.check_org_user),
    reporting_service: ReportingService = Depends(deps.get_reporting_service)
) -> Any:
    """
    Get paginated attendance logs with filtering.
    Isolation: admin sees all (or filtered by user_id), user sees only their own.
    """
    if current_user["role"] == "user":
        effective_user_id = current_user["_id"]
    else:
        effective_user_id = user_id
    
    logs = await reporting_service.get_logs(
        org_id=current_user["org_id"],
        page=page,
        size=size,
        start_date=start_date,
        end_date=end_date,
        dept_id=dept_id,
        user_id=effective_user_id
    )
    return {
        "success": True,
        "data": logs
    }

@router.get("/export")
async def export_attendance_logs(
    format: str = Query("csv", pattern="^(csv|pdf)$"),
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    user_id: Optional[str] = Query(None),
    current_user: dict = Depends(deps.check_org_user),
    reporting_service: ReportingService = Depends(deps.get_reporting_service)
) -> Any:
    """
    Export attendance logs as CSV or PDF.
    Isolation: admin sees all (or filtered by user_id), user sees only their own.
    """
    if current_user["role"] == "user":
        effective_user_id = current_user["_id"]
    else:
        effective_user_id = user_id
        
    generator = await reporting_service.export_logs(
        current_user["org_id"], 
        user_id=effective_user_id,
        format=format,
        start_date=start_date,
        end_date=end_date
    )
    
    filename = f"attendance_logs_{datetime.now().strftime('%Y%m%d_%H%M%S')}.{format}"
    media_type = "text/csv" if format == "csv" else "application/pdf"
    
    return StreamingResponse(
        generator,
        media_type=media_type,
        headers={
            "Content-Disposition": f"attachment; filename={filename}"
        }
    )

@router.get("/system-stats", response_model=dict)
async def get_system_stats(
    current_user: dict = Depends(deps.check_superadmin),
    reporting_service: ReportingService = Depends(deps.get_reporting_service)
) -> Any:
    """
    Get system-wide statistics.
    Only accessible by Super Admin.
    """
    stats = await reporting_service.get_system_stats()
    return {
        "success": True,
        "data": stats
    }
