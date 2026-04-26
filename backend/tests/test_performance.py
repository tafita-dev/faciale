import pytest
import time
import os
import cv2
import numpy as np
from unittest.mock import MagicMock, AsyncMock, patch
from app.services.recognition import RecognitionService

@pytest.fixture
def recognition_service():
    # Save original instance if any
    old_instance = RecognitionService._instance
    # Force reset to allow re-initialization with patches
    RecognitionService._instance = None
    
    with patch("app.repositories.org.get_database"), \
         patch("app.repositories.org.OrgRepository.__init__", return_value=None), \
         patch("app.repositories.vector_db.get_qdrant_client"):
        service = RecognitionService()
        service.org_repo = MagicMock()
        service.org_repo.get_org = AsyncMock(return_value=MagicMock(recognition_threshold=0.6))
        service.vector_repo = MagicMock()
        service.vector_repo.search_embedding = AsyncMock(return_value={"employee_id": "emp123", "score": 0.9})
        yield service
    
    # Restore or reset
    RecognitionService._instance = old_instance

@pytest.fixture
def sample_image_path():
    # Priority: real_face.jpg copied from uploads
    real_path = "tests/real_face.jpg"
    if os.path.exists(real_path):
        return real_path

    # Check uploads directory (might be relative to project root)
    upload_dir = "../uploads"
    if os.path.exists(upload_dir):
        files = [f for f in os.listdir(upload_dir) if f.endswith(".jpg") or f.endswith(".png")]
        if files:
            return os.path.join(upload_dir, files[0])
    
    # Fallback: create a dummy white image with a rectangle (unlikely to work for real face detection)
    dummy_path = "tests/dummy_face.jpg"
    if not os.path.exists("tests"):
        os.makedirs("tests")
    img = np.zeros((640, 640, 3), dtype=np.uint8)
    cv2.rectangle(img, (200, 200), (440, 440), (255, 255, 255), -1)
    cv2.imwrite(dummy_path, img)
    return dummy_path

@pytest.mark.asyncio
async def test_optimized_recognition_performance(recognition_service, sample_image_path):
    iterations = 5
    print(f"\nBenchmarking image: {sample_image_path} over {iterations} iterations")
    
    with open(sample_image_path, "rb") as f:
        img_bytes = f.read()

    # Warm-up
    try:
        await recognition_service.process_recognition("org123", img_bytes)
    except Exception as e:
        print(f"  Warm-up failed (expected if image has no face): {e}")

    times = []
    for i in range(iterations):
        start_time = time.time()
        result = await recognition_service.process_recognition("org123", img_bytes)
        end_to_end_time = time.time() - start_time
        times.append(end_to_end_time)
        print(f"  Iteration {i+1}: {end_to_end_time:.4f}s")
    
    avg_time = sum(times) / iterations
    print(f"  Average Optimized End-to-End Time: {avg_time:.4f}s")
    print(f"  Last Result: {result}")
    
    assert avg_time < 2.0, f"Average performance too slow: {avg_time:.4f}s"

@pytest.mark.asyncio
async def test_recognition_performance_breakdown(recognition_service, sample_image_path):
    iterations = 3
    print(f"\nDetailed Breakdown (Average over {iterations} iterations):")
    
    with open(sample_image_path, "rb") as f:
        img_bytes = f.read()

    stats = {
        "decode": [],
        "detect_extract": [],
        "liveness": [],
        "search": []
    }

    for i in range(iterations):
        # 1. Decode Image
        start_time = time.time()
        img = recognition_service.decode_image_from_bytes(img_bytes)
        stats["decode"].append(time.time() - start_time)

        # 2. Single Pass Face Detection + Embedding
        start_time = time.time()
        faces = recognition_service.app.get(img)
        if not faces:
            print(f"  Iteration {i+1}: SKIPPING remaining steps: No face detected")
            continue
        face = faces[0]
        bbox = face.bbox.tolist()
        embedding = face.embedding
        stats["detect_extract"].append(time.time() - start_time)

        # 3. Liveness Detection (using existing bbox)
        start_time = time.time()
        liveness_res = recognition_service.liveness_service.is_live(img, bbox)
        stats["liveness"].append(time.time() - start_time)

        # 4. Vector Search
        start_time = time.time()
        await recognition_service.match_face("org123", embedding)
        stats["search"].append(time.time() - start_time)

    avg_decode = sum(stats["decode"]) / len(stats["decode"]) if stats["decode"] else 0
    avg_detect = sum(stats["detect_extract"]) / len(stats["detect_extract"]) if stats["detect_extract"] else 0
    avg_liveness = sum(stats["liveness"]) / len(stats["liveness"]) if stats["liveness"] else 0
    avg_search = sum(stats["search"]) / len(stats["search"]) if stats["search"] else 0

    print(f"  Step 1: Decode Image: {avg_decode:.4f}s")
    print(f"  Step 2: Detect & Extract: {avg_detect:.4f}s")
    print(f"  Step 3: Liveness Detection: {avg_liveness:.4f}s")
    print(f"  Step 4: Vector Search (Mocked DB): {avg_search:.4f}s")

    total_avg_time = avg_decode + avg_detect + avg_liveness + avg_search
    print(f"\nTOTAL AVERAGE END-TO-END TIME: {total_avg_time:.4f}s")
    
    assert total_avg_time < 2.0, f"Average performance too slow: {total_avg_time:.4f}s"
