import pytest
import numpy as np
from unittest.mock import AsyncMock, MagicMock, patch
from app.services.enrollment import start_enrollment_pipeline
from fastapi import UploadFile
import io

@pytest.mark.asyncio
async def test_start_enrollment_pipeline_success(tmp_path):
    employee_id = "emp123"
    org_id = "org_a"
    upload_dir = tmp_path / "enrollments"
    
    # Mock file
    file_content = b"fake image content"
    file = UploadFile(filename="test.jpg", file=io.BytesIO(file_content))
    
    # Mock RecognitionService
    mock_recognition_service = MagicMock()
    mock_recognition_service.decode_image_from_bytes.return_value = np.zeros((100, 100, 3), dtype=np.uint8)
    mock_recognition_service.extract_embedding.return_value = np.random.rand(512).astype(np.float32)
    
    # Mock MongoDB
    mock_db = MagicMock()
    mock_employees_coll = AsyncMock()
    mock_db.__getitem__.return_value = mock_employees_coll
    mock_employees_coll.find_one.return_value = {"_id": employee_id, "org_id": org_id}
    mock_employees_coll.update_one = AsyncMock()
    
    # Mock Qdrant Repository and Storage Service
    with patch("app.services.enrollment.RecognitionService", return_value=mock_recognition_service), \
         patch("app.services.enrollment.get_database", return_value=mock_db), \
         patch("app.services.enrollment.VectorRepository") as MockVectorRepo, \
         patch("app.services.enrollment.StorageService") as MockStorageService, \
         patch("app.services.enrollment.settings") as mock_settings:
        
        mock_settings.UPLOAD_DIR = str(upload_dir)
        mock_vector_repo = MockVectorRepo.return_value
        mock_vector_repo.upsert_embedding = AsyncMock()
        
        mock_storage_service = MockStorageService.return_value
        mock_storage_service.save_enrollment_photo = AsyncMock(return_value="uploads/test.jpg")
        
        await start_enrollment_pipeline(employee_id, file)
        
        # Verify recognition service calls
        mock_recognition_service.decode_image_from_bytes.assert_called_once_with(file_content)
        mock_recognition_service.extract_embedding.assert_called_once()
        
        # Verify Qdrant storage
        mock_vector_repo.upsert_embedding.assert_called_once()
        args, kwargs = mock_vector_repo.upsert_embedding.call_args
        assert args[0] == employee_id
        assert args[1] == org_id
        
        # Verify MongoDB update
        mock_employees_coll.update_one.assert_called_once()
        update_args = mock_employees_coll.update_one.call_args[0][1]
        assert update_args["$set"]["is_enrolled"] is True
        assert "image_path" in update_args["$set"]
        assert update_args["$set"]["image_path"].endswith(".jpg")

@pytest.mark.asyncio
async def test_start_enrollment_pipeline_saves_file(tmp_path):
    employee_id = "emp123"
    org_id = "org_a"
    
    # Mock settings.UPLOAD_DIR to a temp path
    upload_dir = tmp_path / "enrollments"
    
    # Mock file
    file_content = b"fake image content"
    file = UploadFile(filename="test.jpg", file=io.BytesIO(file_content))
    
    # Mock RecognitionService
    mock_recognition_service = MagicMock()
    mock_recognition_service.decode_image_from_bytes.return_value = np.zeros((100, 100, 3), dtype=np.uint8)
    mock_recognition_service.extract_embedding.return_value = np.random.rand(512).astype(np.float32)
    
    # Mock MongoDB
    mock_db = MagicMock()
    mock_employees_coll = AsyncMock()
    mock_db.__getitem__.return_value = mock_employees_coll
    mock_employees_coll.find_one.return_value = {"_id": employee_id, "org_id": org_id}
    
    with patch("app.services.enrollment.RecognitionService", return_value=mock_recognition_service), \
         patch("app.services.enrollment.get_database", return_value=mock_db), \
         patch("app.services.enrollment.VectorRepository") as MockVectorRepo, \
         patch("app.services.enrollment.StorageService") as MockStorageService, \
         patch("app.services.enrollment.settings") as mock_settings:
        
        mock_settings.UPLOAD_DIR = str(upload_dir)
        mock_vector_repo = MockVectorRepo.return_value
        mock_vector_repo.upsert_embedding = AsyncMock()
        
        # Mock storage to actually save a file for this test
        mock_storage_service = MockStorageService.return_value
        async def fake_save(file):
            upload_dir.mkdir(parents=True, exist_ok=True)
            saved_file = upload_dir / "test.jpg"
            saved_file.write_bytes(file_content)
            return str(saved_file)
        mock_storage_service.save_enrollment_photo = AsyncMock(side_effect=fake_save)
        
        await start_enrollment_pipeline(employee_id, file)
        
        # Verify file is saved
        files = list(upload_dir.glob("*.jpg"))
        assert len(files) == 1
        assert files[0].read_bytes() == file_content

