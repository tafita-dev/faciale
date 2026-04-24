from datetime import datetime, timezone
from pydantic import BaseModel, Field, ConfigDict
from typing import Optional
import uuid

class EmployeeBase(BaseModel):
    name: str
    dept_id: str

class EmployeeCreate(EmployeeBase):
    pass

class EmployeeUpdate(BaseModel):
    name: Optional[str] = None
    dept_id: Optional[str] = None
    is_active: Optional[bool] = None

class EmployeeInDB(EmployeeBase):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()), alias="_id")
    org_id: str
    is_active: bool = True
    is_enrolled: bool = False
    image_path: Optional[str] = None
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

    model_config = ConfigDict(
        populate_by_name=True,
    )

class Employee(EmployeeInDB):
    pass
