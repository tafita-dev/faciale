import pytest
from unittest.mock import patch, MagicMock, AsyncMock
from app.db.mongodb import connect_to_mongo, close_mongo_connection, get_database
from app.db.qdrant import connect_to_qdrant, close_qdrant_connection, get_qdrant_client
from motor.motor_asyncio import AsyncIOMotorClient
from qdrant_client import AsyncQdrantClient

@pytest.mark.asyncio
async def test_mongodb_connection():
    with patch("app.db.mongodb.AsyncIOMotorClient") as mock_client:
        await connect_to_mongo()
        mock_client.assert_called_once()
        assert get_database() is not None
        await close_mongo_connection()

@pytest.mark.asyncio
async def test_qdrant_connection():
    mock_instance = AsyncMock(spec=AsyncQdrantClient)
    with patch("app.db.qdrant.AsyncQdrantClient", return_value=mock_instance) as mock_class:
        await connect_to_qdrant()
        mock_class.assert_called_once()
        assert get_qdrant_client() is mock_instance
        await close_qdrant_connection()
        mock_instance.close.assert_called_once()
