from motor.motor_asyncio import AsyncIOMotorDatabase
from app.db.mongodb import get_database
from app.models.employee import EmployeeInDB
from typing import Optional

class EmployeeRepository:
    def __init__(self, db: AsyncIOMotorDatabase = None):
        self.db = db or get_database()
        self.collection = self.db["employees"]

    async def get_employee(self, employee_id: str) -> Optional[EmployeeInDB]:
        doc = await self.collection.find_one({"_id": employee_id})
        if doc:
            return EmployeeInDB(**doc)
        return None

    async def count_employees(self, org_id: str) -> int:
        return await self.collection.count_documents({"org_id": org_id})
