import logging
from qdrant_client import AsyncQdrantClient
from qdrant_client.http import models
from app.core.config import settings

logger = logging.getLogger(__name__)

class QdrantDB:
    client: AsyncQdrantClient = None

qdrant_obj = QdrantDB()

async def connect_to_qdrant():
    logger.info("Connecting to Qdrant...")
    qdrant_obj.client = AsyncQdrantClient(
        url=settings.QDRANT_URL,
        api_key=settings.QDRANT_API_KEY
    )
    
    # Initialize collection if not exists
    collection_name = "embeddings"
    try:
        collections = await qdrant_obj.client.get_collections()
        collection_names = [c.name for c in collections.collections]
        if collection_name not in collection_names:
            logger.info(f"Creating collection '{collection_name}'...")
            await qdrant_obj.client.create_collection(
                collection_name=collection_name,
                vectors_config=models.VectorParams(
                    size=512,
                    distance=models.Distance.COSINE
                )
            )
            logger.info(f"Collection '{collection_name}' created")
    except Exception as e:
        logger.error(f"Failed to initialize Qdrant collection: {e}")

    logger.info("Connected to Qdrant")

async def close_qdrant_connection():
    logger.info("Closing Qdrant connection...")
    if qdrant_obj.client:
        await qdrant_obj.client.close()
    logger.info("Qdrant connection closed")

def get_qdrant_client() -> AsyncQdrantClient:
    return qdrant_obj.client
