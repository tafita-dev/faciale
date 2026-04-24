import pytest
import numpy as np
from unittest.mock import AsyncMock, MagicMock, patch
from app.services.attendance import AttendanceService
from app.models.attendance import AttendanceStatus, AttendanceReason

@pytest.fixture
def attendance_service():
    with patch("app.services.attendance.RecognitionService") as MockRecognition, \
         patch("app.services.attendance.AttendanceRepository") as MockRepo:
        mock_recognition = MockRecognition.return_value
        mock_repo = MockRepo.return_value
        mock_repo.create_log = AsyncMock()
        service = AttendanceService(recognition_service=mock_recognition, attendance_repo=mock_repo)
        return service, mock_recognition, mock_repo

@pytest.mark.asyncio
async def test_process_attendance_success(attendance_service):
    service, mock_recognition, mock_repo = attendance_service
    
    org_id = "org_a"
    img_bytes = b"fake_image"
    embedding = np.random.rand(512).astype(np.float32)
    
    # Scenario 1: Successful match
    mock_recognition.verify_liveness = AsyncMock(return_value={"is_live": True, "score": 0.99})
    mock_recognition.extract_embedding = MagicMock(return_value=embedding)
    mock_recognition.match_face = AsyncMock(return_value={"match": True, "employee_id": "emp123", "score": 0.95})
    
    result = await service.process_attendance(org_id, img_bytes)
    
    assert result["status"] == "success"
    assert result["employee_id"] == "emp123"
    
    # Verify log saved
    mock_repo.create_log.assert_called_once()
    args, _ = mock_repo.create_log.call_args
    log = args[0]
    assert log.status == AttendanceStatus.success
    assert log.employee_id == "emp123"
    assert log.org_id == org_id
    assert log.confidence_score == 0.95

@pytest.mark.asyncio
async def test_process_attendance_no_match(attendance_service):
    service, mock_recognition, mock_repo = attendance_service
    
    org_id = "org_a"
    img_bytes = b"fake_image"
    embedding = np.random.rand(512).astype(np.float32)
    
    # Scenario 2: Failed match
    mock_recognition.verify_liveness = AsyncMock(return_value={"is_live": True, "score": 0.99})
    mock_recognition.extract_embedding = MagicMock(return_value=embedding)
    mock_recognition.match_face = AsyncMock(return_value={"match": False, "employee_id": None, "score": 0.70})
    
    result = await service.process_attendance(org_id, img_bytes)
    
    assert result["status"] == "failed"
    assert result["reason"] == "no_match"
    
    # Verify log saved
    mock_repo.create_log.assert_called_once()
    args, _ = mock_repo.create_log.call_args
    log = args[0]
    assert log.status == AttendanceStatus.failed
    assert log.reason == AttendanceReason.no_match
    assert log.employee_id is None
    assert log.org_id == org_id
    assert log.confidence_score == 0.70

@pytest.mark.asyncio
async def test_process_attendance_spoof(attendance_service):
    service, mock_recognition, mock_repo = attendance_service
    
    org_id = "org_a"
    img_bytes = b"fake_image"
    
    # Scenario 3: Spoof detected
    mock_recognition.verify_liveness = AsyncMock(return_value={"is_live": False, "score": 0.10})
    
    result = await service.process_attendance(org_id, img_bytes)
    
    assert result["status"] == "failed"
    assert result["reason"] == "spoof_detected"
    
    # Verify log saved
    mock_repo.create_log.assert_called_once()
    args, _ = mock_repo.create_log.call_args
    log = args[0]
    assert log.status == AttendanceStatus.failed
    assert log.reason == AttendanceReason.spoof_detected
    assert log.org_id == org_id
    assert log.confidence_score == 0.10
