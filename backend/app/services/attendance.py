from app.services.recognition import RecognitionService
from app.services.notification import NotificationService
from app.repositories.attendance import AttendanceRepository
from app.repositories.org import OrgRepository
from app.repositories.user import UserRepository
from app.repositories.employee import EmployeeRepository
from app.models.attendance import AttendanceLog, AttendanceStatus, AttendanceReason, AttendanceType
import numpy as np
from datetime import datetime, timezone, time

class AttendanceService:
    def __init__(
        self,
        recognition_service: RecognitionService = None,
        attendance_repo: AttendanceRepository = None,
        org_repo: OrgRepository = None,
        user_repo: UserRepository = None,
        employee_repo: EmployeeRepository = None,
        notification_service: NotificationService = None
    ):
        self.recognition_service = recognition_service or RecognitionService()
        self.attendance_repo = attendance_repo or AttendanceRepository()
        self.org_repo = org_repo or OrgRepository()
        self.user_repo = user_repo or UserRepository()
        self.employee_repo = employee_repo or EmployeeRepository()
        self.notification_service = notification_service or NotificationService()

    async def _get_entry_status(self, org_id: str, timestamp: datetime) -> AttendanceStatus:
        org = await self.org_repo.get_org(org_id)
        if not org or not org.settings:
            return AttendanceStatus.present

        try:
            start_time_str = org.settings.start_time
            late_buffer = org.settings.late_buffer_minutes
            
            h, m = map(int, start_time_str.split(':'))
            # Add late buffer to start_time to get late_threshold
            total_minutes = h * 60 + m + late_buffer
            threshold_h = (total_minutes // 60) % 24
            threshold_m = total_minutes % 60
            
            late_threshold_time = time(threshold_h, threshold_m)
            # Compare only the time part, assuming same day for threshold
            current_time = timestamp.time()
            
            if current_time > late_threshold_time:
                return AttendanceStatus.late
            return AttendanceStatus.present
        except Exception:
            return AttendanceStatus.present

    async def process_attendance(self, org_id: str, img_bytes: bytes, user_id: str = None) -> dict:
        """
        Processes an attendance attempt:
        1. Perform end-to-end recognition (liveness + matching).
        2. Log the result.
        """
        # 1. Unified recognition (Liveness + Face Detection + Embedding + Match)
        rec_result = await self.recognition_service.process_recognition(org_id, img_bytes)
        
        if not rec_result["is_live"]:
            log = AttendanceLog(
                org_id=org_id,
                user_id=user_id,
                status=AttendanceStatus.failed,
                reason=AttendanceReason.spoof_detected,
                confidence_score=rec_result["score"]
            )
            await self.attendance_repo.create_log(log)
            return {
                "status": "failed",
                "reason": "spoof_detected",
                "score": rec_result["score"]
            }

        if rec_result["match"]:
            employee_id = rec_result["employee_id"]
            now = datetime.now(timezone.utc)
            
            # Toggling logic: count successful logs today
            count = await self.attendance_repo.count_logs_today(org_id, employee_id)
            att_type = AttendanceType.entry if count % 2 == 0 else AttendanceType.exit
            
            # Determine status (Entry/Late for entry, success for exit)
            if att_type == AttendanceType.entry:
                status = await self._get_entry_status(org_id, now)
            else:
                status = AttendanceStatus.success

            log = AttendanceLog(
                org_id=org_id,
                employee_id=employee_id,
                user_id=user_id,
                status=status,
                attendance_type=att_type,
                confidence_score=rec_result["score"],
                timestamp=now
            )
            created_log = await self.attendance_repo.create_log(log)

            # Send notification if late (only for entry)
            if att_type == AttendanceType.entry and status == AttendanceStatus.late:
                try:
                    admins = await self.user_repo.get_org_admins(org_id)
                    admin_tokens = []
                    for admin in admins:
                        admin_tokens.extend(admin.get("fcm_tokens", []))
                    
                    if admin_tokens:
                        employee = await self.employee_repo.get_employee(employee_id)
                        org = await self.org_repo.get_org(org_id)
                        
                        await self.notification_service.notify_late_arrival(
                            admin_tokens=admin_tokens,
                            employee_name=employee.name if employee else "Employee",
                            org_name=org.name if org else "Organization",
                            log_id=str(created_log.id)
                        )
                except Exception as e:
                    import logging
                    logging.getLogger(__name__).error(f"Failed to send late notification: {e}")

            return {
                "status": status,
                "type": att_type,
                "employee_id": employee_id,
                "score": rec_result["score"]
            }
        else:
            log = AttendanceLog(
                org_id=org_id,
                user_id=user_id,
                status=AttendanceStatus.failed,
                reason=AttendanceReason.no_match,
                confidence_score=rec_result["score"]
            )
            await self.attendance_repo.create_log(log)
            return {
                "status": "failed",
                "reason": "no_match",
                "score": rec_result["score"]
            }
