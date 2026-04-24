from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import StreamingResponse
from app.api import deps
from app.services.reporting_service import ReportingService
from typing import Any, Optional
from datetime import datetime

router = APIRouter()

@router.get("/stats", response_model=dict)
async def get_attendance_stats(
    current_user: dict = Depends(deps.get_current_user),
    reporting_service: ReportingService = Depends(deps.get_reporting_service)
) -> Any:
    """
    Get today's attendance statistics for the organization.
    Only accessible by Org Admin.
    """
    if current_user["role"] != "org_admin":
        raise HTTPException(
            status_code=403,
            detail="Only Org Admins can access reporting statistics"
        )
    
    stats = await reporting_service.get_today_stats(current_user["org_id"])
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
    current_user: dict = Depends(deps.get_current_user),
    reporting_service: ReportingService = Depends(deps.get_reporting_service)
) -> Any:
    """
    Get paginated attendance logs with filtering.
    Only accessible by Org Admin.
    """
    if current_user["role"] != "org_admin":
        raise HTTPException(
            status_code=403,
            detail="Only Org Admins can access reporting logs"
        )
    
    logs = await reporting_service.get_logs(
        org_id=current_user["org_id"],
        page=page,
        size=size,
        start_date=start_date,
        end_date=end_date,
        dept_id=dept_id
    )
    return {
        "success": True,
        "data": logs
    }

@router.get("/export")
async def export_attendance_logs(
    format: str = Query("csv", pattern="^csv$"),
    current_user: dict = Depends(deps.get_current_user),
    reporting_service: ReportingService = Depends(deps.get_reporting_service)
) -> Any:
    """
    Export attendance logs as CSV.
    Only accessible by Org Admin.
    """
    if current_user["role"] != "org_admin":
        raise HTTPException(
            status_code=403,
            detail="Only Org Admins can export reporting logs"
        )
    
    generator = await reporting_service.export_logs(current_user["org_id"])
    
    filename = f"attendance_logs_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv"
    
    return StreamingResponse(
        generator,
        media_type="text/csv",
        headers={
            "Content-Disposition": f"attachment; filename={filename}"
        }
    )
