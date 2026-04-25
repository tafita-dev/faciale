from app.services.recognition import RecognitionService
from app.repositories.attendance import AttendanceRepository
from app.models.attendance import AttendanceLog, AttendanceStatus, AttendanceReason
import numpy as np
from datetime import datetime, timezone

class AttendanceService:
    def __init__(self, recognition_service: RecognitionService = None, attendance_repo: AttendanceRepository = None):
        self.recognition_service = recognition_service or RecognitionService()
        self.attendance_repo = attendance_repo or AttendanceRepository()

    async def process_attendance(self, org_id: str, img_bytes: bytes, user_id: str = None) -> dict:
        """
        Processes an attendance attempt:
        1. Verify liveness.
        2. If live, extract embedding and match face.
        3. Log the result.
        """
        # 1. Verify liveness
        liveness_result = await self.recognition_service.verify_liveness(img_bytes)
        
        if not liveness_result["is_live"]:
            log = AttendanceLog(
                org_id=org_id,
                user_id=user_id,
                status=AttendanceStatus.failed,
                reason=AttendanceReason.spoof_detected,
                confidence_score=liveness_result["score"]
            )
            await self.attendance_repo.create_log(log)
            return {
                "status": "failed",
                "reason": "spoof_detected",
                "score": liveness_result["score"]
            }

        # 2. Extract embedding and match face
        img = self.recognition_service.decode_image_from_bytes(img_bytes)
        embedding = self.recognition_service.extract_embedding(img)
        match_result = await self.recognition_service.match_face(org_id, embedding)

        if match_result["match"]:
            employee_id = match_result["employee_id"]
            
            # Check for open session
            open_log = await self.attendance_repo.find_open_log(org_id, employee_id)
            
            if open_log:
                # Close session (Exit)
                await self.attendance_repo.update_log(open_log.id, {
                    "check_out": datetime.now(timezone.utc),
                    "timestamp": datetime.now(timezone.utc), # Update timestamp for recent activity
                    "user_id": user_id
                })
                return {
                    "status": "success",
                    "type": "exit",
                    "employee_id": employee_id,
                    "score": match_result["score"]
                }
            else:
                # Open new session (Entry)
                log = AttendanceLog(
                    org_id=org_id,
                    employee_id=employee_id,
                    user_id=user_id,
                    status=AttendanceStatus.success,
                    confidence_score=match_result["score"],
                    check_in=datetime.now(timezone.utc)
                )
                await self.attendance_repo.create_log(log)
                return {
                    "status": "success",
                    "type": "entry",
                    "employee_id": employee_id,
                    "score": match_result["score"]
                }
        else:
            log = AttendanceLog(
                org_id=org_id,
                user_id=user_id,
                status=AttendanceStatus.failed,
                reason=AttendanceReason.no_match,
                confidence_score=match_result["score"]
            )
            await self.attendance_repo.create_log(log)
            return {
                "status": "failed",
                "reason": "no_match",
                "score": match_result["score"]
            }
