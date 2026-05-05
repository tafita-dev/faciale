import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from app.services.attendance import AttendanceService
from app.models.attendance import AttendanceStatus, AttendanceLog
from datetime import datetime, timezone

@pytest.mark.asyncio
async def test_process_attendance_triggers_late_notification():
    # Mock dependencies
    recognition_service = MagicMock()
    recognition_service.process_recognition = AsyncMock(return_value={
        "is_live": True,
        "match": True,
        "employee_id": "emp123",
        "score": 0.95
    })
    
    attendance_repo = MagicMock()
    attendance_repo.find_open_log = AsyncMock(return_value=None)
    attendance_repo.create_log = AsyncMock(return_value=MagicMock(id="log123"))
    
    org_repo = MagicMock()
    mock_org = MagicMock()
    mock_org.name = "Test Org"
    org_repo.get_org = AsyncMock(return_value=mock_org)
    
    user_repo = MagicMock()
    user_repo.get_org_admins = AsyncMock(return_value=[
        {"email": "admin@test.com", "fcm_tokens": ["token1", "token2"]}
    ])
    
    employee_repo = MagicMock()
    mock_employee = MagicMock()
    mock_employee.name = "John Doe"
    employee_repo.get_employee = AsyncMock(return_value=mock_employee)
    
    notification_service = MagicMock()
    notification_service.notify_late_arrival = AsyncMock()
    
    service = AttendanceService(
        recognition_service=recognition_service,
        attendance_repo=attendance_repo,
        org_repo=org_repo,
        user_repo=user_repo,
        employee_repo=employee_repo,
        notification_service=notification_service
    )
    
    # Mock _get_entry_status to return late
    service._get_entry_status = AsyncMock(return_value=AttendanceStatus.late)
    
    await service.process_attendance("org123", b"fake_img")
    
    # Verify notification was called
    notification_service.notify_late_arrival.assert_called_once_with(
        admin_tokens=["token1", "token2"],
        employee_name="John Doe",
        org_name="Test Org",
        log_id="log123"
    )

@pytest.mark.asyncio
async def test_process_attendance_no_notification_if_not_late():
    recognition_service = MagicMock()
    recognition_service.process_recognition = AsyncMock(return_value={
        "is_live": True,
        "match": True,
        "employee_id": "emp123",
        "score": 0.95
    })
    
    attendance_repo = MagicMock()
    attendance_repo.find_open_log = AsyncMock(return_value=None)
    attendance_repo.create_log = AsyncMock(return_value=MagicMock(id="log123"))
    
    notification_service = MagicMock()
    notification_service.notify_late_arrival = AsyncMock()
    
    service = AttendanceService(
        recognition_service=recognition_service,
        attendance_repo=attendance_repo,
        org_repo=MagicMock(),
        user_repo=MagicMock(),
        employee_repo=MagicMock(),
        notification_service=notification_service
    )
    
    # Mock _get_entry_status to return present
    service._get_entry_status = AsyncMock(return_value=AttendanceStatus.present)
    
    await service.process_attendance("org123", b"fake_img")
    
    # Verify notification was NOT called
    notification_service.notify_late_arrival.assert_not_called()
