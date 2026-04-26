import pytest
import numpy as np
import uuid
import json
from unittest.mock import AsyncMock, MagicMock
from app.repositories.vector_db import VectorRepository
from app.core.security import decrypt_data
from app.core.config import settings

@pytest.fixture(autouse=True)
def setup_encryption_key():
    # Ensure ENCRYPTION_KEY is set for tests
    if not settings.ENCRYPTION_KEY:
        from cryptography.fernet import Fernet
        settings.ENCRYPTION_KEY = Fernet.generate_key().decode()

@pytest.mark.asyncio
async def test_upsert_embedding_with_encryption():
    mock_client = AsyncMock()
    repo = VectorRepository(client=mock_client)
    
    employee_id = "emp123"
    org_id = "org_a"
    embedding = np.random.rand(512).astype(np.float32)
    
    await repo.upsert_embedding(employee_id, org_id, embedding)
    
    mock_client.upsert.assert_called_once()
    args, kwargs = mock_client.upsert.call_args
    
    points = kwargs["points"]
    point = points[0]
    
    # Check payload contains encrypted embedding
    assert "encrypted_embedding" in point.payload
    encrypted_val = point.payload["encrypted_embedding"]
    
    # Decrypt and verify
    decrypted_embedding = decrypt_data(encrypted_val, as_json=True)
    assert np.allclose(decrypted_embedding, embedding.tolist(), atol=1e-5)
    
    # Original vector should still be there for search (unencrypted)
    assert point.vector == embedding.tolist()

@pytest.mark.asyncio
async def test_search_embedding_with_decryption():
    mock_client = AsyncMock()
    repo = VectorRepository(client=mock_client)
    
    org_id = "org_a"
    embedding = np.random.rand(512).astype(np.float32)
    
    # Mock return value for search with encrypted payload
    from app.core.security import encrypt_data
    encrypted_embedding = encrypt_data(embedding.tolist())
    
    mock_result = MagicMock()
    mock_result.payload = {
        "employee_id": "emp123",
        "encrypted_embedding": encrypted_embedding
    }
    mock_result.score = 0.92
    mock_client.search.return_value = [mock_result]
    
    result = await repo.search_embedding(org_id, embedding)
    
    assert result is not None
    assert result["employee_id"] == "emp123"
    assert "embedding" in result
    assert np.allclose(result["embedding"], embedding.tolist(), atol=1e-5)
