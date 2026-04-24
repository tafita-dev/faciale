from datetime import datetime, timezone
from pydantic import BaseModel, Field, ConfigDict
from typing import Optional
import uuid

class DepartmentBase(BaseModel):
    name: str

class DepartmentCreate(DepartmentBase):
    pass

class DepartmentUpdate(BaseModel):
    name: Optional[str] = None

class DepartmentInDB(DepartmentBase):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()), alias="_id")
    org_id: str
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

    model_config = ConfigDict(
        populate_by_name=True,
    )

class Department(DepartmentInDB):
    pass
