import pytest
import numpy as np
from unittest.mock import MagicMock, patch, AsyncMock
from app.services.recognition import RecognitionService

@pytest.fixture
def recognition_service():
    RecognitionService._instance = None
    with patch("app.services.recognition.FaceAnalysis") as mock_face_analysis:
        # Create a mock instance that will be returned when FaceAnalysis() is called
        mock_app_instance = MagicMock()
        mock_face_analysis.return_value = mock_app_instance
        
        with patch("app.services.recognition.LivenessService") as MockLiveness:
            with patch("app.services.recognition.VectorRepository") as MockVectorRepo:
                with patch("app.services.recognition.OrgRepository") as MockOrgRepo:
                    # Configure default mocks
                    mock_org_repo_instance = MockOrgRepo.return_value
                    mock_org_repo_instance.get_org = AsyncMock(return_value=None)
                    
                    mock_vector_repo_instance = MockVectorRepo.return_value
                    mock_vector_repo_instance.search_embedding = AsyncMock(return_value=None)
                    
                    mock_liveness_instance = MockLiveness.return_value
                    service = RecognitionService()
                    return service, mock_app_instance, mock_liveness_instance

def test_extract_embedding_single_face(recognition_service):
    service, mock_app_instance, _ = recognition_service
    
    # Mock face object from insightface
    mock_face = MagicMock()
    mock_face.embedding = np.random.rand(512).astype(np.float32)
    
    mock_app_instance.get.return_value = [mock_face]
    
    # Create a fake image (e.g., 100x100 RGB)
    fake_img = np.zeros((100, 100, 3), dtype=np.uint8)
    
    embedding = service.extract_embedding(fake_img)
    
    assert embedding.shape == (512,)
    assert isinstance(embedding, np.ndarray)
    assert embedding.dtype == np.float32
    mock_app_instance.get.assert_called_once()

def test_extract_embedding_no_face(recognition_service):
    service, mock_app_instance, _ = recognition_service
    
    mock_app_instance.get.return_value = [] # No face detected
    
    fake_img = np.zeros((100, 100, 3), dtype=np.uint8)
    
    with pytest.raises(ValueError, match="No face detected in the image"):
        service.extract_embedding(fake_img)

def test_extract_embedding_multiple_faces(recognition_service):
    service, mock_app_instance, _ = recognition_service
    
    mock_app_instance.get.return_value = [MagicMock(), MagicMock()] # 2 faces detected
    
    fake_img = np.zeros((100, 100, 3), dtype=np.uint8)
    
    with pytest.raises(ValueError, match="Multiple faces detected"):
        service.extract_embedding(fake_img)

@pytest.mark.asyncio
async def test_verify_liveness_success(recognition_service):
    service, mock_app_instance, mock_liveness_instance = recognition_service
    
    # Fake image bytes
    fake_img_bytes = b"fake_image_data"
    
    # Mock decode_image_from_bytes to return a fake numpy array
    fake_img = np.zeros((100, 100, 3), dtype=np.uint8)
    
    # Mock face with bbox
    mock_face = MagicMock()
    mock_face.bbox = np.array([10, 10, 50, 50])
    mock_app_instance.get.return_value = [mock_face]
    
    mock_liveness_instance.is_live.return_value = {"is_live": True, "score": 0.95}
    
    with patch.object(service, "decode_image_from_bytes", return_value=fake_img):
        result = await service.verify_liveness(fake_img_bytes)
        
        assert result["is_live"] is True
        assert result["score"] == 0.95
        mock_liveness_instance.is_live.assert_called_once_with(fake_img, [10.0, 10.0, 50.0, 50.0])

@pytest.mark.asyncio
async def test_verify_liveness_spoof(recognition_service):
    service, mock_app_instance, mock_liveness_instance = recognition_service
    fake_img_bytes = b"spoof_image_data"
    fake_img = np.zeros((100, 100, 3), dtype=np.uint8)
    
    # Mock face with bbox
    mock_face = MagicMock()
    mock_face.bbox = np.array([10, 10, 50, 50])
    mock_app_instance.get.return_value = [mock_face]
    
    mock_liveness_instance.is_live.return_value = {"is_live": False, "score": 0.2}
    
    with patch.object(service, "decode_image_from_bytes", return_value=fake_img):
        result = await service.verify_liveness(fake_img_bytes)
        
        assert result["is_live"] is False
        assert result["score"] == 0.2
        mock_liveness_instance.is_live.assert_called_once_with(fake_img, [10.0, 10.0, 50.0, 50.0])

@pytest.mark.asyncio
async def test_match_face_success(recognition_service):
    service, _, _ = recognition_service
    
    org_id = "org_a"
    embedding = np.random.rand(512).astype(np.float32)
    
    mock_repo = MagicMock()
    mock_repo.search_embedding = AsyncMock(return_value={"employee_id": "emp123", "score": 0.92})
    
    # Manually inject the mock repo
    service.vector_repo = mock_repo
    
    result = await service.match_face(org_id, embedding)
    
    assert result["match"] is True
    assert result["employee_id"] == "emp123"
    assert result["score"] == 0.92
    mock_repo.search_embedding.assert_called_once_with(org_id, embedding)

@pytest.mark.asyncio
async def test_match_face_low_confidence(recognition_service):
    service, _, _ = recognition_service
    
    org_id = "org_a"
    embedding = np.random.rand(512).astype(np.float32)
    
    mock_repo = MagicMock()
    mock_repo.search_embedding = AsyncMock(return_value={"employee_id": "emp123", "score": 0.80})
    service.vector_repo = mock_repo
    
    result = await service.match_face(org_id, embedding)
    
    assert result["match"] is False
    assert result["employee_id"] is None
    assert result["score"] == 0.80

@pytest.mark.asyncio
async def test_match_face_uses_settings_threshold(recognition_service):
    service, _, _ = recognition_service
    from app.core.config import settings
    
    org_id = "org_a"
    embedding = np.random.rand(512).astype(np.float32)
    
    mock_repo = MagicMock()
    # Mock return value score is 0.82
    mock_repo.search_embedding = AsyncMock(return_value={"employee_id": "emp123", "score": 0.82})
    service.vector_repo = mock_repo
    
    # Test with a high threshold from settings mock
    with patch("app.services.recognition.settings") as mock_settings:
        mock_settings.RECOGNITION_THRESHOLD = 0.85
        result = await service.match_face(org_id, embedding, threshold=None)
        assert result["match"] is False
        
        # Test with a low threshold from settings mock
        mock_settings.RECOGNITION_THRESHOLD = 0.80
        result = await service.match_face(org_id, embedding, threshold=None)
        assert result["match"] is True
        assert result["employee_id"] == "emp123"

@pytest.mark.asyncio
async def test_match_face_uses_org_threshold(recognition_service):
    service, _, _ = recognition_service
    
    org_id = "org_a"
    embedding = np.random.rand(512).astype(np.float32)
    
    mock_repo = MagicMock()
    # Mock return value score is 0.82
    mock_repo.search_embedding = AsyncMock(return_value={"employee_id": "emp123", "score": 0.82})
    service.vector_repo = mock_repo
    
    # Mock OrgRepository
    mock_org_repo = MagicMock()
    mock_org = MagicMock()
    mock_org.recognition_threshold = 0.80
    mock_org_repo.get_org = AsyncMock(return_value=mock_org)
    service.org_repo = mock_org_repo
    
    # Even if settings is 0.85, it should use 0.80 from org
    with patch("app.services.recognition.settings") as mock_settings:
        mock_settings.RECOGNITION_THRESHOLD = 0.85
        result = await service.match_face(org_id, embedding, threshold=None)
        assert result["match"] is True
        assert result["employee_id"] == "emp123"
        mock_org_repo.get_org.assert_called_once_with(org_id)

@pytest.mark.asyncio
async def test_match_face_no_result(recognition_service):
    service, _, _ = recognition_service
    
    org_id = "org_a"
    embedding = np.random.rand(512).astype(np.float32)
    
    mock_repo = MagicMock()
    mock_repo.search_embedding = AsyncMock(return_value=None)
    service.vector_repo = mock_repo
    
    result = await service.match_face(org_id, embedding)
    
    assert result["match"] is False
    assert result["employee_id"] is None
    assert result["score"] == 0.0
