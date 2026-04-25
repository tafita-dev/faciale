from motor.motor_asyncio import AsyncIOMotorDatabase
from app.db.mongodb import get_database
from app.models.department import DepartmentInDB
from typing import Optional

class DepartmentRepository:
    def __init__(self, db: AsyncIOMotorDatabase = None):
        self.db = db or get_database()
        self.collection = self.db["departments"]

    async def get_department(self, dept_id: str) -> Optional[DepartmentInDB]:
        doc = await self.collection.find_one({"_id": dept_id})
        if doc:
            return DepartmentInDB(**doc)
        return None
