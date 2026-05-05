import pytest
from unittest.mock import AsyncMock, MagicMock
from datetime import datetime, timezone, timedelta
from app.services.attendance import AttendanceService
from app.models.attendance import AttendanceLog, AttendanceStatus, AttendanceType
from app.models.org import Org, OrgSettings

@pytest.fixture
def mock_deps():
    return {
        "recognition_service": AsyncMock(),
        "attendance_repo": AsyncMock(),
        "org_repo": AsyncMock(),
        "user_repo": AsyncMock(),
        "employee_repo": AsyncMock(),
        "notification_service": AsyncMock()
    }

@pytest.fixture
def attendance_service(mock_deps):
    return AttendanceService(**mock_deps)

@pytest.mark.asyncio
async def test_toggle_entry_exit_first_scan(attendance_service, mock_deps):
    org_id = "org123"
    emp_id = "emp456"
    img_bytes = b"fake_img"
    
    # Mock recognition success
    mock_deps["recognition_service"].process_recognition.return_value = {
        "is_live": True,
        "match": True,
        "employee_id": emp_id,
        "score": 0.95
    }
    
    # Scenario 1: First scan today
    mock_deps["attendance_repo"].count_logs_today.return_value = 0
    mock_deps["org_repo"].get_org.return_value = Org(
        id=org_id, name="Test Org", type="company", created_at=datetime.now()
    )
    mock_deps["attendance_repo"].create_log.return_value = AttendanceLog(
        org_id=org_id, employee_id=emp_id, status=AttendanceStatus.present
    )

    result = await attendance_service.process_attendance(org_id, img_bytes)
    
    assert result["type"] == AttendanceType.entry
    mock_deps["attendance_repo"].create_log.assert_called_once()
    log = mock_deps["attendance_repo"].create_log.call_args[0][0]
    assert log.attendance_type == AttendanceType.entry

@pytest.mark.asyncio
async def test_toggle_entry_exit_second_scan(attendance_service, mock_deps):
    org_id = "org123"
    emp_id = "emp456"
    img_bytes = b"fake_img"
    
    mock_deps["recognition_service"].process_recognition.return_value = {
        "is_live": True,
        "match": True,
        "employee_id": emp_id,
        "score": 0.95
    }
    
    # Scenario 2: Second scan today (already 1 log)
    mock_deps["attendance_repo"].count_logs_today.return_value = 1
    mock_deps["attendance_repo"].create_log.return_value = AttendanceLog(
        org_id=org_id, employee_id=emp_id, status=AttendanceStatus.success
    )

    result = await attendance_service.process_attendance(org_id, img_bytes)
    
    assert result["type"] == AttendanceType.exit
    log = mock_deps["attendance_repo"].create_log.call_args[0][0]
    assert log.attendance_type == AttendanceType.exit

@pytest.mark.asyncio
async def test_toggle_entry_exit_third_scan(attendance_service, mock_deps):
    org_id = "org123"
    emp_id = "emp456"
    img_bytes = b"fake_img"
    
    mock_deps["recognition_service"].process_recognition.return_value = {
        "is_live": True,
        "match": True,
        "employee_id": emp_id,
        "score": 0.95
    }
    
    # Scenario 3: Third scan today (already 2 logs: entry, exit)
    mock_deps["attendance_repo"].count_logs_today.return_value = 2
    mock_deps["org_repo"].get_org.return_value = Org(
        id=org_id, name="Test Org", type="company", created_at=datetime.now()
    )
    mock_deps["attendance_repo"].create_log.return_value = AttendanceLog(
        org_id=org_id, employee_id=emp_id, status=AttendanceStatus.present
    )

    result = await attendance_service.process_attendance(org_id, img_bytes)
    
    assert result["type"] == AttendanceType.entry
    log = mock_deps["attendance_repo"].create_log.call_args[0][0]
    assert log.attendance_type == AttendanceType.entry

@pytest.mark.asyncio
async def test_date_boundary_reset(attendance_service, mock_deps):
    """Scenario 3: Date boundary check. Should ignore yesterday's status."""
    org_id = "org123"
    emp_id = "emp456"
    img_bytes = b"fake_img"
    
    mock_deps["recognition_service"].process_recognition.return_value = {
        "is_live": True,
        "match": True,
        "employee_id": emp_id,
        "score": 0.95
    }
    
    # Yesterday they had an 'entry' (or whatever)
    # Today they have 0 logs
    mock_deps["attendance_repo"].count_logs_today.return_value = 0
    mock_deps["org_repo"].get_org.return_value = Org(
        id=org_id, name="Test Org", type="company", created_at=datetime.now()
    )
    mock_deps["attendance_repo"].create_log.return_value = AttendanceLog(
        org_id=org_id, employee_id=emp_id, status=AttendanceStatus.present
    )

    result = await attendance_service.process_attendance(org_id, img_bytes)
    
    assert result["type"] == AttendanceType.entry
    log = mock_deps["attendance_repo"].create_log.call_args[0][0]
    assert log.attendance_type == AttendanceType.entry

@pytest.mark.asyncio
async def test_infinite_toggle_today(attendance_service, mock_deps):
    """Scenario 2: Infinite toggle today."""
    org_id = "org123"
    emp_id = "emp456"
    img_bytes = b"fake_img"
    
    mock_deps["recognition_service"].process_recognition.return_value = {
        "is_live": True,
        "match": True,
        "employee_id": emp_id,
        "score": 0.95
    }
    
    # 1. First scan (count=0) -> entry
    mock_deps["attendance_repo"].count_logs_today.return_value = 0
    mock_deps["org_repo"].get_org.return_value = Org(
        id=org_id, name="Test Org", type="company", created_at=datetime.now()
    )
    result = await attendance_service.process_attendance(org_id, img_bytes)
    assert result["type"] == AttendanceType.entry
    
    # 2. Second scan (count=1) -> exit
    mock_deps["attendance_repo"].count_logs_today.return_value = 1
    result = await attendance_service.process_attendance(org_id, img_bytes)
    assert result["type"] == AttendanceType.exit
    
    # 3. Third scan (count=2) -> entry
    mock_deps["attendance_repo"].count_logs_today.return_value = 2
    result = await attendance_service.process_attendance(org_id, img_bytes)
    assert result["type"] == AttendanceType.entry
