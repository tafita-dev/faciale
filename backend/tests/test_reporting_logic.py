import pytest
from unittest.mock import AsyncMock, MagicMock
from app.services.reporting_service import ReportingService
from datetime import datetime, time, timezone

@pytest.fixture
def mock_repos():
    attendance_repo = MagicMock()
    employee_repo = MagicMock()
    org_repo = MagicMock()
    
    attendance_repo.get_today_stats = AsyncMock()
    employee_repo.count_employees = AsyncMock()
    org_repo.get_org = AsyncMock()
    
    return attendance_repo, employee_repo, org_repo

@pytest.mark.asyncio
async def test_get_today_stats_uses_org_settings(mock_repos):
    attendance_repo, employee_repo, org_repo = mock_repos
    service = ReportingService(attendance_repo, employee_repo, org_repo)
    
    org_id = "org123"
    
    # Mock Org with custom settings: 10:00 AM start, 0 buffer
    org_mock = MagicMock()
    org_mock.settings = MagicMock()
    org_mock.settings.start_time = "10:00"
    org_mock.settings.late_buffer_minutes = 0
    org_repo.get_org.return_value = org_mock
    
    employee_repo.count_employees.return_value = 10
    attendance_repo.get_today_stats.return_value = {"present": 5, "late": 2}
    
    await service.get_today_stats(org_id)
    
    # Verify that get_today_stats was called with a threshold around 10:00 AM
    args, kwargs = attendance_repo.get_today_stats.call_args
    late_threshold = args[2]
    assert late_threshold.hour == 10
    assert late_threshold.minute == 0

@pytest.mark.asyncio
async def test_get_today_stats_uses_late_buffer(mock_repos):
    attendance_repo, employee_repo, org_repo = mock_repos
    service = ReportingService(attendance_repo, employee_repo, org_repo)
    
    org_id = "org123"
    
    # Mock Org: 08:30 AM start, 15 min buffer -> 08:45 AM threshold
    org_mock = MagicMock()
    org_mock.settings = MagicMock()
    org_mock.settings.start_time = "08:30"
    org_mock.settings.late_buffer_minutes = 15
    org_repo.get_org.return_value = org_mock
    
    employee_repo.count_employees.return_value = 10
    attendance_repo.get_today_stats.return_value = {"present": 5, "late": 1}
    
    await service.get_today_stats(org_id)
    
    args, kwargs = attendance_repo.get_today_stats.call_args
    late_threshold = args[2]
    assert late_threshold.hour == 8
    assert late_threshold.minute == 45
