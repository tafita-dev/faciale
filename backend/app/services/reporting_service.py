import io
from app.repositories.attendance import AttendanceRepository
from app.repositories.employee import EmployeeRepository
from app.repositories.org import OrgRepository
from datetime import datetime, time, timezone
from typing import Optional
from reportlab.lib.pagesizes import letter
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet

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
        db = self.org_repo.collection.database
        total_organizations = await self.org_repo.count_all()
        total_admins = await db["users"].count_documents({"role": "admin"})
        total_users = await db["users"].count_documents({"role": "user"})
        total_employees = await self.employee_repo.collection.count_documents({})
        
        return {
            "total_organizations": total_organizations,
            "total_admins": total_admins,
            "total_users": total_users,
            "total_employees": total_employees
        }

    async def get_today_stats(self, org_id: str, user_id: Optional[str] = None) -> dict:
        # Get start and end of today in UTC
        now = datetime.now(timezone.utc)
        start_of_today = datetime.combine(now.date(), time.min).replace(tzinfo=timezone.utc)
        
        # Fetch Org settings
        org = await self.org_repo.get_org(org_id)
        start_time_str = "09:00"
        late_buffer = 15
        
        if org and hasattr(org, 'settings') and org.settings:
            start_time_str = org.settings.start_time
            late_buffer = org.settings.late_buffer_minutes
        elif org and isinstance(org, dict) and "settings" in org:
            # Handle if org is returned as a dict (e.g. from some repo implementations)
            settings = org["settings"]
            start_time_str = settings.get("start_time", "09:00")
            late_buffer = settings.get("late_buffer_minutes", 15)
            
        h, m = map(int, start_time_str.split(':'))
        # Add late buffer to start_time to get late_threshold
        total_minutes = h * 60 + m + late_buffer
        threshold_h = (total_minutes // 60) % 24
        threshold_m = total_minutes % 60
        
        late_threshold_time = time(threshold_h, threshold_m)
        late_threshold = datetime.combine(now.date(), late_threshold_time).replace(tzinfo=timezone.utc)

        # Additional stats for Admin
        # Safely handle db access if repos are mocked
        org_users_count = 0
        if not user_id:
            try:
                db = self.employee_repo.collection.database
                org_users_count = await db["users"].count_documents({"org_id": org_id, "role": "user"})
            except (AttributeError, TypeError):
                # Fallback for tests or incomplete mocks
                org_users_count = 0

        # Get total employees in org (isolated if user_id provided)
        if user_id:
            # For a user, we only care about THEIR employees
            total_employees = await self.employee_repo.collection.count_documents({"org_id": org_id, "created_by": user_id})
        else:
            total_employees = await self.employee_repo.count_employees(org_id)
        
        # Get today's attendance stats using aggregation
        stats = await self.attendance_repo.get_today_stats(org_id, start_of_today, late_threshold, user_id=user_id)
        
        present = stats.get("present", 0)
        late = stats.get("late", 0)
        absent = max(0, total_employees - present)

        result = {
            "present": present,
            "late": late,
            "absent": absent,
            "total_employees": total_employees,
            "attendance_rate": (present / total_employees * 100) if total_employees > 0 else 0
        }
        
        if not user_id:
            result["total_users"] = org_users_count
            
        return result

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

    async def export_logs(self, org_id: str, user_id: Optional[str] = None, format: str = "csv", start_date: Optional[str] = None, end_date: Optional[str] = None):
        cursor = await self.attendance_repo.get_logs_cursor(org_id, user_id=user_id, start_date=start_date, end_date=end_date)
        
        if format == "csv":
            async def generate_csv():
                yield "Date,Time,Employee Name,Department,Status,Confidence Score\n"
                async for doc in cursor:
                    ts = doc["timestamp"]
                    date_str = ts.strftime("%Y-%m-%d")
                    time_str = ts.strftime("%H:%M:%S")
                    line = f"{date_str},{time_str},{doc['employee_name']},{doc['department_name']},{doc['status']},{doc['confidence']}\n"
                    yield line
            return generate_csv()
        
        elif format == "pdf":
            # Fetch Org info for header
            org = await self.org_repo.get_org(org_id)
            org_name = org.name if org else "Faciale Organization"
            
            data = [["Date", "Time", "Employee Name", "Department", "Status", "Score"]]
            async for doc in cursor:
                ts = doc["timestamp"]
                data.append([
                    ts.strftime("%Y-%m-%d"),
                    ts.strftime("%H:%M:%S"),
                    doc["employee_name"],
                    doc["department_name"],
                    doc["status"],
                    f"{doc['confidence']:.2f}"
                ])
            
            def generate_pdf():
                buffer = io.BytesIO()
                doc = SimpleDocTemplate(buffer, pagesize=letter)
                elements = []
                
                styles = getSampleStyleSheet()
                elements.append(Paragraph(f"Attendance Report: {org_name}", styles['Title']))
                
                date_range_str = "All Time"
                if start_date and end_date:
                    date_range_str = f"From {start_date} To {end_date}"
                elif start_date:
                    date_range_str = f"From {start_date}"
                elif end_date:
                    date_range_str = f"Until {end_date}"
                
                elements.append(Paragraph(f"Period: {date_range_str}", styles['Heading3']))
                elements.append(Paragraph(f"Generated on: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}", styles['Normal']))
                elements.append(Spacer(1, 12))
                
                # Create Table
                t = Table(data)
                t.setStyle(TableStyle([
                    ('BACKGROUND', (0, 0), (-1, 0), colors.deepskyblue),
                    ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
                    ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
                    ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
                    ('FONTSIZE', (0, 0), (-1, 0), 12),
                    ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
                    ('BACKGROUND', (0, 1), (-1, -1), colors.beige),
                    ('GRID', (0, 0), (-1, -1), 1, colors.black)
                ]))
                elements.append(t)
                
                doc.build(elements)
                pdf_data = buffer.getvalue()
                buffer.close()
                return pdf_data

            async def stream_pdf():
                yield generate_pdf()
            
            return stream_pdf()

    async def get_advanced_analytics(
        self,
        org_id: str,
        start_date: str,
        end_date: str,
        dept_id: Optional[str] = None
    ) -> dict:
        # Convert string dates to datetime objects
        try:
            start_dt = datetime.fromisoformat(start_date.replace("Z", "+00:00"))
        except ValueError:
            # Fallback to date only
            start_dt = datetime.combine(datetime.fromisoformat(start_date).date(), time.min).replace(tzinfo=timezone.utc)
            
        try:
            end_dt = datetime.fromisoformat(end_date.replace("Z", "+00:00"))
        except ValueError:
            # Fallback to date only, include end of day
            end_dt = datetime.combine(datetime.fromisoformat(end_date).date(), time.max).replace(tzinfo=timezone.utc)

        # Fetch Org settings for late threshold (passed to repo if needed, but repo currently does its own match)
        org = await self.org_repo.get_org(org_id)
        start_time_str = "09:00"
        late_buffer = 15
        
        if org:
            if hasattr(org, 'settings') and org.settings:
                start_time_str = org.settings.start_time
                late_buffer = org.settings.late_buffer_minutes
            elif isinstance(org, dict) and "settings" in org:
                settings = org["settings"]
                start_time_str = settings.get("start_time", "09:00")
                late_buffer = settings.get("late_buffer_minutes", 15)

        h, m = map(int, start_time_str.split(':'))
        total_minutes = h * 60 + m + late_buffer
        threshold_h = (total_minutes // 60) % 24
        threshold_m = total_minutes % 60
        late_threshold_time = f"{threshold_h:02d}:{threshold_m:02d}"

        # Fetch metrics from repository
        analytics = await self.attendance_repo.get_analytics_data(
            org_id=org_id,
            start_date=start_dt,
            end_date=end_dt,
            dept_id=dept_id
        )

        # Calculate absent counts for the breakdown
        total_employees = await self.employee_repo.count_employees(org_id, dept_id=dept_id)
        
        # Approximate number of working days in the range
        days_diff = (end_dt.date() - start_dt.date()).days + 1
        # In a real app, we'd subtract weekends/holidays, but for now we keep it simple
        total_possible_attendances = total_employees * days_diff
        
        present_count = analytics["status_breakdown"]["present"]
        late_count = analytics["status_breakdown"]["late"]
        
        analytics["status_breakdown"]["absent"] = max(0, total_possible_attendances - present_count - late_count)

        return analytics
