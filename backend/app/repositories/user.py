from typing import List, Optional
from app.db.mongodb import get_database
from app.models.user import User

class UserRepository:
    def __init__(self, db=None):
        self.db = db or get_database()
        self.collection = self.db["users"]

    async def get_org_admins(self, org_id: str) -> List[dict]:
        """
        Retrieves all users with the role 'admin' for a specific organization.
        """
        cursor = self.collection.find({"org_id": org_id, "role": "admin"})
        return await cursor.to_list(length=100)

    async def add_fcm_token(self, email: str, token: str):
        """
        Adds an FCM token to a user's list of tokens.
        """
        await self.collection.update_one(
            {"email": email},
            {"$addToSet": {"fcm_tokens": token}}
        )

    async def remove_fcm_token(self, email: str, token: str):
        """
        Removes an FCM token from a user's list of tokens.
        """
        await self.collection.update_one(
            {"email": email},
            {"$pull": {"fcm_tokens": token}}
        )
