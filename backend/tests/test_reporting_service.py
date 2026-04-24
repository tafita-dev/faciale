import pytest
from unittest.mock import AsyncMock, MagicMock
from app.services.reporting_service import ReportingService
from datetime import datetime, time, timezone

@pytest.mark.asyncio
async def test_get_today_stats():
    mock_attendance_repo = AsyncMock()
    mock_employee_repo = AsyncMock()
    
    service = ReportingService(mock_attendance_repo, mock_employee_repo)
    
    mock_employee_repo.count_employees.return_value = 20
    mock_attendance_repo.get_today_stats.return_value = {
        "present": 12,
        "late": 3
    }
    
    org_id = "test_org"
    stats = await service.get_today_stats(org_id)
    
    assert stats["present"] == 12
    assert stats["late"] == 3
    assert stats["absent"] == 8
    assert stats["total"] == 20
    
    mock_employee_repo.count_employees.assert_called_once_with(org_id)
    # Check that get_today_stats was called with correct org_id
    args, _ = mock_attendance_repo.get_today_stats.call_args
    assert args[0] == org_id
    assert isinstance(args[1], datetime) # start_of_today
    assert isinstance(args[2], datetime) # late_threshold

@pytest.mark.asyncio
async def test_get_logs_service():
    mock_attendance_repo = AsyncMock()
    mock_employee_repo = AsyncMock()
    service = ReportingService(attendance_repo=mock_attendance_repo, employee_repo=mock_employee_repo)
    
    mock_attendance_repo.get_logs_with_employee_info.return_value = ([], 0)
    
    await service.get_logs(org_id="org1", page=2, size=5, start_date="2023-01-01")
    
    mock_attendance_repo.get_logs_with_employee_info.assert_called_once_with(
        org_id="org1",
        page=2,
        size=5,
        start_date="2023-01-01",
        end_date=None,
        dept_id=None
    )

@pytest.mark.asyncio
async def test_get_today_stats_no_data():
    mock_attendance_repo = AsyncMock()
    mock_employee_repo = AsyncMock()
    
    service = ReportingService(mock_attendance_repo, mock_employee_repo)
    
    mock_employee_repo.count_employees.return_value = 0
    mock_attendance_repo.get_today_stats.return_value = {
        "present": 0,
        "late": 0
    }
    
    stats = await service.get_today_stats("empty_org")
    
    assert stats["present"] == 0
    assert stats["late"] == 0
    assert stats["absent"] == 0
    assert stats["total"] == 0
