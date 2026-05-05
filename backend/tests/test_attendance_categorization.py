import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from app.services.attendance import AttendanceService
from datetime import datetime, timezone, time

@pytest.fixture
def mock_repos():
    recognition_service = MagicMock()
    attendance_repo = MagicMock()
    org_repo = MagicMock()
    
    recognition_service.process_recognition = AsyncMock()
    attendance_repo.find_open_log = AsyncMock()
    attendance_repo.create_log = AsyncMock()
    attendance_repo.update_log = AsyncMock()
    org_repo.get_org = AsyncMock()
    
    return recognition_service, attendance_repo, org_repo

@pytest.mark.asyncio
async def test_process_attendance_categorizes_present(mock_repos):
    recognition_service, attendance_repo, org_repo = mock_repos
    # Note: We expect AttendanceService to take org_repo now
    service = AttendanceService(recognition_service, attendance_repo, org_repo)
    
    org_id = "org123"
    emp_id = "emp456"
    
    # Mock Org Settings: 09:00 start, 15m buffer
    org_mock = MagicMock()
    org_mock.settings = MagicMock()
    org_mock.settings.start_time = "09:00"
    org_mock.settings.late_buffer_minutes = 15
    org_repo.get_org.return_value = org_mock
    
    recognition_service.process_recognition.return_value = {
        "is_live": True,
        "match": True,
        "employee_id": emp_id,
        "score": 0.95
    }
    
    attendance_repo.find_open_log.return_value = None # It's an entry
    
    # Mock time to 09:10 UTC (Before 09:15)
    mock_now = datetime.combine(datetime.now(timezone.utc).date(), time(9, 10)).replace(tzinfo=timezone.utc)
    
    with patch('app.services.attendance.datetime') as mock_datetime:
        mock_datetime.now.return_value = mock_now
        mock_datetime.combine = datetime.combine
        mock_datetime.fromisoformat = datetime.fromisoformat
        mock_datetime.timezone = timezone
        
        await service.process_attendance(org_id, b"dummy")
        
    # Verify create_log was called with status="present"
    args, kwargs = attendance_repo.create_log.call_args
    log = args[0]
    assert log.status == "present"

@pytest.mark.asyncio
async def test_process_attendance_categorizes_late(mock_repos):
    recognition_service, attendance_repo, org_repo = mock_repos
    service = AttendanceService(recognition_service, attendance_repo, org_repo)
    
    org_id = "org123"
    emp_id = "emp456"
    
    # Mock Org Settings: 09:00 start, 15m buffer
    org_mock = MagicMock()
    org_mock.settings = MagicMock()
    org_mock.settings.start_time = "09:00"
    org_mock.settings.late_buffer_minutes = 15
    org_repo.get_org.return_value = org_mock
    
    recognition_service.process_recognition.return_value = {
        "is_live": True,
        "match": True,
        "employee_id": emp_id,
        "score": 0.95
    }
    
    attendance_repo.find_open_log.return_value = None # It's an entry
    
    # Mock time to 09:16 UTC (After 09:15)
    mock_now = datetime.combine(datetime.now(timezone.utc).date(), time(9, 16)).replace(tzinfo=timezone.utc)
    
    with patch('app.services.attendance.datetime') as mock_datetime:
        mock_datetime.now.return_value = mock_now
        mock_datetime.combine = datetime.combine
        mock_datetime.fromisoformat = datetime.fromisoformat
        mock_datetime.timezone = timezone
        
        await service.process_attendance(org_id, b"dummy")
        
    # Verify create_log was called with status="late"
    args, kwargs = attendance_repo.create_log.call_args
    log = args[0]
    assert log.status == "late"

@pytest.mark.asyncio
async def test_process_attendance_fallback_to_present(mock_repos):
    recognition_service, attendance_repo, org_repo = mock_repos
    service = AttendanceService(recognition_service, attendance_repo, org_repo)
    
    org_id = "org123"
    emp_id = "emp456"
    
    # Mock Org with NO settings
    org_repo.get_org.return_value = None
    
    recognition_service.process_recognition.return_value = {
        "is_live": True,
        "match": True,
        "employee_id": emp_id,
        "score": 0.95
    }
    
    attendance_repo.find_open_log.return_value = None
    
    await service.process_attendance(org_id, b"dummy")
    
    args, kwargs = attendance_repo.create_log.call_args
    log = args[0]
    assert log.status == "present"
