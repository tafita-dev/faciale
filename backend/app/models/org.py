from datetime import datetime, timezone
from enum import Enum
from pydantic import BaseModel, Field, ConfigDict
from typing import Optional
import uuid

class OrgType(str, Enum):
    school = "school"
    company = "company"

class OrgBase(BaseModel):
    name: str
    type: OrgType
    recognition_threshold: Optional[float] = Field(None, ge=0.0, le=1.0)

class OrgCreate(OrgBase):
    pass

class OrgUpdate(BaseModel):
    name: Optional[str] = None
    type: Optional[OrgType] = None
    recognition_threshold: Optional[float] = Field(None, ge=0.0, le=1.0)

class OrgInDB(OrgBase):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()), alias="_id")
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

    model_config = ConfigDict(
        populate_by_name=True,
    )

class Org(OrgInDB):
    pass
