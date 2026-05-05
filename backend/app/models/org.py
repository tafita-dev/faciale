from datetime import datetime, timezone
from enum import Enum
from pydantic import BaseModel, Field, ConfigDict, field_validator
from typing import Optional
import uuid
import re

class OrgType(str, Enum):
    school = "school"
    company = "company"

class OrgSettings(BaseModel):
    start_time: str = Field(default="09:00", description="HH:MM format")
    late_buffer_minutes: int = Field(default=15, ge=0)

    @field_validator('start_time')
    @classmethod
    def validate_start_time(cls, v: str) -> str:
        if not re.match(r'^([01]\d|2[0-3]):([0-5]\d)$', v):
            raise ValueError('Invalid time format. Must be HH:MM')
        return v

class OrgBase(BaseModel):
    name: str
    type: OrgType
    admin_email: Optional[str] = None
    logo_url: Optional[str] = None
    recognition_threshold: Optional[float] = Field(None, ge=0.0, le=1.0)
    settings: Optional[OrgSettings] = Field(default_factory=OrgSettings)

class OrgCreate(OrgBase):
    admin_email: str
    admin_password: str
    admin_name: str

class OrgUpdate(BaseModel):
    name: Optional[str] = None
    type: Optional[OrgType] = None
    logo_url: Optional[str] = None
    recognition_threshold: Optional[float] = Field(None, ge=0.0, le=1.0)
    settings: Optional[OrgSettings] = None

class OrgInDB(OrgBase):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()), alias="_id")
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

    model_config = ConfigDict(
        populate_by_name=True,
    )

class Org(OrgInDB):
    pass
