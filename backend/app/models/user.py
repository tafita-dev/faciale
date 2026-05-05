from pydantic import BaseModel, EmailStr, ConfigDict, Field
from typing import Optional, List
import uuid
from datetime import datetime, timezone

class UserBase(BaseModel):
    email: EmailStr
    name: Optional[str] = None
    role: str = "user" # superadmin, admin, user
    org_id: Optional[str] = None
    photo_url: Optional[str] = None
    fcm_tokens: List[str] = []

class UserCreate(BaseModel):
    email: EmailStr
    password: str
    name: str

class UserResponse(UserBase):
    id: str = Field(alias="_id")
    created_at: datetime

    model_config = ConfigDict(
        populate_by_name=True,
    )

class User(UserResponse):
    pass
