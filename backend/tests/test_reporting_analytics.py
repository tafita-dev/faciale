import pytest
from datetime import datetime, timezone, timedelta
from unittest.mock import AsyncMock, MagicMock
from app.services.reporting_service import ReportingService
from app.repositories.attendance import AttendanceRepository
from app.repositories.employee import EmployeeRepository
from app.repositories.org import OrgRepository

@pytest.fixture
def mock_repos():
    return {
        "attendance": MagicMock(spec=AttendanceRepository),
        "employee": MagicMock(spec=EmployeeRepository),
        "org": MagicMock(spec=OrgRepository)
    }

@pytest.fixture
def reporting_service(mock_repos):
    return ReportingService(
        attendance_repo=mock_repos["attendance"],
        employee_repo=mock_repos["employee"],
        org_repo=mock_repos["org"]
    )

@pytest.mark.asyncio
async def test_get_advanced_analytics_success(reporting_service, mock_repos):
    org_id = "org_123"
    start_date = "2023-01-01"
    end_date = "2023-01-31"
    
    # Mock Org
    mock_org = {
        "_id": org_id,
        "name": "Test Org",
        "settings": {
            "start_time": "09:00",
            "late_buffer_minutes": 15
        }
    }
    mock_repos["org"].get_org = AsyncMock(return_value=mock_org)
    
    # Mock Attendance Logs
    # 2023-01-01: emp1 present (08:50), emp2 late (09:30)
    # 2023-01-02: emp1 present (09:05)
    logs = [
        {
            "employee_id": "emp1",
            "timestamp": datetime(2023, 1, 1, 8, 50, tzinfo=timezone.utc),
            "status": "present",
            "attendance_type": "entry"
        },
        {
            "employee_id": "emp2",
            "timestamp": datetime(2023, 1, 1, 9, 30, tzinfo=timezone.utc),
            "status": "late",
            "attendance_type": "entry"
        },
        {
            "employee_id": "emp1",
            "timestamp": datetime(2023, 1, 1, 17, 0, tzinfo=timezone.utc),
            "status": "success",
            "attendance_type": "exit"
        },
        {
            "employee_id": "emp1",
            "timestamp": datetime(2023, 1, 2, 9, 5, tzinfo=timezone.utc),
            "status": "present",
            "attendance_type": "entry"
        }
    ]
    
    # We'll mock the specific aggregation calls that ReportingService will make
    # Since ReportingService will likely use attendance_repo for these, let's define what we expect
    
    mock_repos["attendance"].get_analytics_data = AsyncMock(return_value={
        "avg_punctuality": 66.67, # 2 present, 1 late out of 3 entries
        "peak_arrival_time": "09:00",
        "total_hours_worked": 8.17, # emp1 worked from 08:50 to 17:00 = 8h10m = 8.166h
        "daily_trends": [
            {"date": "2023-01-01", "count": 2},
            {"date": "2023-01-02", "count": 1}
        ],
        "status_breakdown": {
            "present": 2,
            "late": 1,
            "absent": 5 # total_employees * days - present - late
        }
    })
    
    # Total employees in org
    mock_repos["employee"].count_employees = AsyncMock(return_value=2)
    
    analytics = await reporting_service.get_advanced_analytics(
        org_id=org_id,
        start_date=start_date,
        end_date=end_date
    )
    
    # Verify repository call
    mock_repos["attendance"].get_analytics_data.assert_called_once()
    args, kwargs = mock_repos["attendance"].get_analytics_data.call_args
    assert kwargs["org_id"] == org_id
    assert "late_threshold_time" not in kwargs

    assert analytics["avg_punctuality"] == 66.67
    assert analytics["peak_arrival_time"] == "09:00"
    assert analytics["total_hours_worked"] == 8.17
    assert len(analytics["daily_trends"]) == 2
    assert analytics["status_breakdown"]["present"] == 2
    assert analytics["status_breakdown"]["late"] == 1
