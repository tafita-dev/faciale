import pytest
import numpy as np
import uuid
from unittest.mock import AsyncMock, MagicMock
from app.repositories.vector_db import VectorRepository

@pytest.mark.asyncio
async def test_upsert_embedding():
    mock_client = AsyncMock()
    repo = VectorRepository(client=mock_client)
    
    employee_id = "emp123"
    org_id = "org_a"
    embedding = np.random.rand(512).astype(np.float32)
    
    await repo.upsert_embedding(employee_id, org_id, embedding)
    
    # Expected point ID (UUID v5)
    NAMESPACE_FACIALE = uuid.UUID('12345678-1234-5678-1234-567812345678')
    expected_id = str(uuid.uuid5(NAMESPACE_FACIALE, employee_id))
    
    mock_client.upsert.assert_called_once()
    args, kwargs = mock_client.upsert.call_args
    
    assert kwargs["collection_name"] == "embeddings"
    points = kwargs["points"]
    assert len(points) == 1
    point = points[0]
    assert point.id == expected_id
    assert point.vector == embedding.tolist()
    assert point.payload == {"employee_id": employee_id, "org_id": org_id}

@pytest.mark.asyncio
async def test_search_embedding_match():
    mock_client = AsyncMock()
    repo = VectorRepository(client=mock_client)
    
    org_id = "org_a"
    embedding = np.random.rand(512).astype(np.float32)
    
    # Mock return value for search
    mock_result = MagicMock()
    mock_result.payload = {"employee_id": "emp123"}
    mock_result.score = 0.92
    mock_client.search.return_value = [mock_result]
    
    result = await repo.search_embedding(org_id, embedding)
    
    assert result is not None
    assert result["employee_id"] == "emp123"
    assert result["score"] == 0.92
    
    mock_client.search.assert_called_once()
    _, kwargs = mock_client.search.call_args
    assert kwargs["collection_name"] == "embeddings"
    assert kwargs["query_vector"] == embedding.tolist()
    assert kwargs["limit"] == 1
    # Check filter
    assert kwargs["query_filter"].must[0].key == "org_id"
    assert kwargs["query_filter"].must[0].match.value == org_id

@pytest.mark.asyncio
async def test_search_embedding_no_match():
    mock_client = AsyncMock()
    repo = VectorRepository(client=mock_client)
    
    org_id = "org_a"
    embedding = np.random.rand(512).astype(np.float32)
    
    # Mock return value for search (empty list)
    mock_client.search.return_value = []
    
    result = await repo.search_embedding(org_id, embedding)
    
    assert result is None
