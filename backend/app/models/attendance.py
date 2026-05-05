from datetime import datetime, timezone
from enum import Enum
from pydantic import BaseModel, Field, ConfigDict
from typing import Optional
import uuid

class AttendanceStatus(str, Enum):
    success = "success"
    failed = "failed"
    present = "present"
    late = "late"

class AttendanceType(str, Enum):
    entry = "entry"
    exit = "exit"

class AttendanceReason(str, Enum):
    no_match = "no_match"
    spoof_detected = "spoof_detected"

class AttendanceLog(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()), alias="_id")
    org_id: str
    employee_id: Optional[str] = None
    user_id: Optional[str] = None # The user who recorded the pointage
    status: AttendanceStatus
    attendance_type: Optional[AttendanceType] = None # entry or exit
    reason: Optional[AttendanceReason] = None
    confidence_score: float = 0.0
    timestamp: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    # For paired entry/exit records (legacy support or internal grouping)
    check_in: Optional[datetime] = None
    check_out: Optional[datetime] = None

    model_config = ConfigDict(
        populate_by_name=True,
        json_schema_extra={
            "example": {
                "org_id": "org_123",
                "employee_id": "emp_456",
                "status": "success",
                "confidence_score": 0.92,
                "timestamp": "2024-01-01T00:00:00Z"
            }
        }
    )
