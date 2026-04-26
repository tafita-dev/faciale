import pytest
import numpy as np
import time
import uuid
from qdrant_client import AsyncQdrantClient
from qdrant_client.http import models
from app.repositories.vector_db import VectorRepository
from app.core.config import settings

@pytest.mark.asyncio
async def test_vector_db_scalability():
    """
    Scenario: Bulk Insertion and Search with 1,000+ Vectors.
    - Populate a collection with 1,000 mock facial embeddings.
    - Measure search time (target < 100ms).
    - Verify accuracy (target score > 0.85 for exact match).
    """
    # Override QDRANT_URL to localhost for tests running outside docker network
    qdrant_url = "http://localhost:6333"
    client = AsyncQdrantClient(url=qdrant_url, api_key=settings.QDRANT_API_KEY)
    collection_name = "scalability_test"
    
    # 1. Setup: Create temporary collection
    await client.recreate_collection(
        collection_name=collection_name,
        vectors_config=models.VectorParams(size=512, distance=models.Distance.COSINE)
    )
    
    repo = VectorRepository(client=client)
    repo.collection_name = collection_name
    
    num_vectors = 1000
    org_id = "scale_org_1"
    
    print(f"\nPopulating {num_vectors} vectors...")
    
    # Prepare bulk data
    points = []
    for i in range(num_vectors):
        employee_id = f"scale_emp_{i}"
        # Generate random normalized vector
        vec = np.random.rand(512).astype(np.float32)
        vec /= np.linalg.norm(vec)
        
        points.append(
            models.PointStruct(
                id=str(uuid.uuid4()),
                vector=vec.tolist(),
                payload={
                    "employee_id": employee_id,
                    "org_id": org_id
                }
            )
        )
    
    # Bulk upsert
    start_upsert = time.time()
    await client.upsert(collection_name=collection_name, points=points)
    upsert_duration = time.time() - start_upsert
    print(f"Bulk upsert of {num_vectors} took {upsert_duration:.4f}s")

    # 2. Accuracy and Performance Check
    # Add one known face to search for
    target_emp_id = "target_employee"
    target_vec = np.random.rand(512).astype(np.float32)
    target_vec /= np.linalg.norm(target_vec)
    
    await repo.upsert_embedding(target_emp_id, org_id, target_vec)
    
    print("Performing search...")
    iterations = 10
    search_times = []
    
    for _ in range(iterations):
        start_search = time.time()
        result = await repo.search_embedding(org_id, target_vec)
        search_times.append(time.time() - start_search)
        
        assert result is not None
        assert result["employee_id"] == target_emp_id
        assert result["score"] > 0.99  # Should be very close to 1.0 for exact match

    avg_search_time = sum(search_times) / iterations
    print(f"Average search time over {num_vectors} vectors: {avg_search_time*1000:.2f}ms")
    
    # Acceptance Criteria Verification
    assert avg_search_time < 0.1, f"Search time too slow: {avg_search_time*1000:.2f}ms"

    # 3. Accuracy with Noise (Maintain correct identification)
    print("Testing accuracy with noisy vector...")
    noise = np.random.normal(0, 0.01, 512).astype(np.float32)
    noisy_target = target_vec + noise
    noisy_target /= np.linalg.norm(noisy_target)
    
    result = await repo.search_embedding(org_id, noisy_target)
    assert result is not None
    assert result["employee_id"] == target_emp_id
    assert result["score"] > 0.85, f"Accuracy dropped in large vector space: {result['score']}"
    print(f"Noisy match score: {result['score']:.4f}")
    
    # 4. Cleanup
    await client.delete_collection(collection_name)
    await client.close()
