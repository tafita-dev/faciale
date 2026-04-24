import logging
from motor.motor_asyncio import AsyncIOMotorClient
from app.core.config import settings

logger = logging.getLogger(__name__)

class MongoDB:
    client: AsyncIOMotorClient = None
    db = None

db_obj = MongoDB()

async def connect_to_mongo():
    logger.info("Connecting to MongoDB...")
    db_obj.client = AsyncIOMotorClient(settings.MONGODB_URL)
    db_obj.db = db_obj.client[settings.MONGODB_DB_NAME]
    logger.info("Connected to MongoDB")

async def close_mongo_connection():
    logger.info("Closing MongoDB connection...")
    if db_obj.client:
        db_obj.client.close()
    logger.info("MongoDB connection closed")

def get_database():
    return db_obj.db
