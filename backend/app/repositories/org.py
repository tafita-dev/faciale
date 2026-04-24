from motor.motor_asyncio import AsyncIOMotorDatabase
from app.db.mongodb import get_database
from app.models.org import OrgInDB
from typing import Optional

class OrgRepository:
    def __init__(self, db: AsyncIOMotorDatabase = None):
        self.db = db or get_database()
        self.collection = self.db["organizations"]

    async def get_org(self, org_id: str) -> Optional[OrgInDB]:
        doc = await self.collection.find_one({"_id": org_id})
        if doc:
            return OrgInDB(**doc)
        return None
