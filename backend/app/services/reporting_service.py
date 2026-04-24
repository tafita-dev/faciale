from app.repositories.attendance import AttendanceRepository
from app.repositories.employee import EmployeeRepository
from datetime import datetime, time, timezone
from typing import Optional

class ReportingService:
    def __init__(
        self,
        attendance_repo: AttendanceRepository = None,
        employee_repo: EmployeeRepository = None
    ):
        self.attendance_repo = attendance_repo or AttendanceRepository()
        self.employee_repo = employee_repo or EmployeeRepository()

    async def get_today_stats(self, org_id: str) -> dict:
        # Get start and end of today in UTC
        now = datetime.now(timezone.utc)
        start_of_today = datetime.combine(now.date(), time.min).replace(tzinfo=timezone.utc)
        
        # Default late threshold is 9:00 AM
        late_threshold_time = time(9, 0)
        late_threshold = datetime.combine(now.date(), late_threshold_time).replace(tzinfo=timezone.utc)

        # Get total employees in org
        total_employees = await self.employee_repo.count_employees(org_id)
        
        # Get today's attendance stats using aggregation
        stats = await self.attendance_repo.get_today_stats(org_id, start_of_today, late_threshold)
        
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
        dept_id: Optional[str] = None
    ) -> dict:
        # Business logic: Fetch logs with details
        logs, total = await self.attendance_repo.get_logs_with_employee_info(
            org_id=org_id,
            page=page,
            size=size,
            start_date=start_date,
            end_date=end_date,
            dept_id=dept_id
        )

        return {
            "items": logs,
            "total": total,
            "page": page,
            "size": size
        }

    async def export_logs(self, org_id: str):
        cursor = await self.attendance_repo.get_logs_cursor(org_id)
        
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
