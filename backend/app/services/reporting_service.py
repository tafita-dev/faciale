from app.repositories.attendance import AttendanceRepository
from app.repositories.employee import EmployeeRepository
from app.repositories.org import OrgRepository
from datetime import datetime, time, timezone
from typing import Optional

class ReportingService:
    def __init__(
        self,
        attendance_repo: AttendanceRepository = None,
        employee_repo: EmployeeRepository = None,
        org_repo: OrgRepository = None
    ):
        self.attendance_repo = attendance_repo or AttendanceRepository()
        self.employee_repo = employee_repo or EmployeeRepository()
        self.org_repo = org_repo or OrgRepository()

    async def get_system_stats(self) -> dict:
        total_organizations = await self.org_repo.count_all()
        return {
            "total_organizations": total_organizations
        }

    async def get_today_stats(self, org_id: str, user_id: Optional[str] = None) -> dict:
        # Get start and end of today in UTC
        now = datetime.now(timezone.utc)
        start_of_today = datetime.combine(now.date(), time.min).replace(tzinfo=timezone.utc)
        
        # Default late threshold is 9:00 AM
        late_threshold_time = time(9, 0)
        late_threshold = datetime.combine(now.date(), late_threshold_time).replace(tzinfo=timezone.utc)

        # Get total employees in org (isolated if user_id provided)
        if user_id:
            # For a user, we only care about THEIR employees?
            # Prompt says: "Voit uniquement : ses propres salariés"
            # So total should be their own employees
            total_employees = await self.employee_repo.collection.count_documents({"org_id": org_id, "created_by": user_id})
        else:
            total_employees = await self.employee_repo.count_employees(org_id)
        
        # Get today's attendance stats using aggregation
        stats = await self.attendance_repo.get_today_stats(org_id, start_of_today, late_threshold, user_id=user_id)
        
        present = stats.get("present", 0)
        late = stats.get("late", 0)
        absent = max(0, total_employees - present)

        return {
            "present": present,
            "late": late,
            "absent": absent,
            "total": total_employees
        }

    async def get_logs(
        self,
        org_id: str,
        page: int = 1,
        size: int = 10,
        start_date: Optional[str] = None,
        end_date: Optional[str] = None,
        dept_id: Optional[str] = None,
        user_id: Optional[str] = None
    ) -> dict:
        # Business logic: Fetch logs with details
        logs, total = await self.attendance_repo.get_logs_with_employee_info(
            org_id=org_id,
            page=page,
            size=size,
            start_date=start_date,
            end_date=end_date,
            dept_id=dept_id,
            user_id=user_id
        )

        return {
            "items": logs,
            "total": total,
            "page": page,
            "size": size
        }

    async def export_logs(self, org_id: str, user_id: Optional[str] = None):
        cursor = await self.attendance_repo.get_logs_cursor(org_id, user_id=user_id)
        
        async def generate():
            yield "Date,Time,Employee Name,Department,Status,Confidence Score\n"
            async for doc in cursor:
                ts = doc["timestamp"]
                # Assuming ts is a datetime object
                date_str = ts.strftime("%Y-%m-%d")
                time_str = ts.strftime("%H:%M:%S")
                
                line = f"{date_str},{time_str},{doc['employee_name']},{doc['department_name']},{doc['status']},{doc['confidence']}\n"
                yield line
                
        return generate()
