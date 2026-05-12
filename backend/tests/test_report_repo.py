import pytest
from unittest.mock import AsyncMock, MagicMock
from app.repositories.attendance import AttendanceRepository
from app.models.attendance import AttendanceLog, AttendanceStatus
from datetime import datetime, time, timezone, timedelta

@pytest.mark.asyncio
async def test_attendance_stats_aggregation_mocked():
    mock_db = MagicMock()
    mock_collection = MagicMock()
    mock_db.__getitem__.return_value = mock_collection
    
    attendance_repo = AttendanceRepository(db=mock_db)
    
    org_id = "test_org"
    now = datetime.now(timezone.utc)
    start_of_today = datetime.combine(now.date(), time.min).replace(tzinfo=timezone.utc)
    late_threshold = datetime.combine(now.date(), time(9, 0)).replace(tzinfo=timezone.utc)
    
    # Mock aggregate result
    mock_cursor = MagicMock()
    mock_cursor.to_list = AsyncMock(return_value=[{
        "present": [{"count": 10}],
        "late": [{"count": 3}]
    }])
    mock_collection.aggregate.return_value = mock_cursor
    
    stats = await attendance_repo.get_today_stats(org_id, start_of_today, late_threshold)
    
    assert stats["present"] == 10
    assert stats["late"] == 3
    
    mock_collection.aggregate.assert_called_once()
    pipeline = mock_collection.aggregate.call_args[0][0]
    
    # Verify pipeline structure
    assert pipeline[0]["$match"]["org_id"] == org_id
    assert pipeline[1]["$group"]["_id"] == "$employee_id"
    assert "$facet" in pipeline[2]

@pytest.mark.asyncio
async def test_attendance_stats_aggregation_empty_mocked():
    mock_db = MagicMock()
    mock_collection = MagicMock()
    mock_db.__getitem__.return_value = mock_collection
    
    attendance_repo = AttendanceRepository(db=mock_db)
    
    # Mock empty aggregate result
    mock_cursor = MagicMock()
    mock_cursor.to_list = AsyncMock(return_value=[{
        "present": [],
        "late": []
    }])
    mock_collection.aggregate.return_value = mock_cursor
    
    stats = await attendance_repo.get_today_stats("empty_org", datetime.now(), datetime.now())
    
    assert stats["present"] == 0
    assert stats["late"] == 0

@pytest.mark.asyncio
async def test_get_analytics_data_mocked():
    mock_db = MagicMock()
    mock_collection = MagicMock()
    mock_db.__getitem__.return_value = mock_collection
    
    attendance_repo = AttendanceRepository(db=mock_db)
    
    org_id = "test_org"
    start_date = datetime(2023, 1, 1, tzinfo=timezone.utc)
    end_date = datetime(2023, 1, 31, tzinfo=timezone.utc)
    
    # Mock aggregate result
    mock_cursor = MagicMock()
    mock_cursor.to_list = AsyncMock(return_value=[{
        "status_counts": [{"_id": "present", "count": 10}, {"_id": "late", "count": 2}],
        "daily_trends": [{"date": "2023-01-01", "count": 5}],
        "punctuality": [{"total": 12, "present": 10}],
        "peak_arrival": [{"_id": "08:30", "count": 5}],
        "hours_worked": [{"total_ms": 36000000}] # 10 hours
    }])
    mock_collection.aggregate.return_value = mock_cursor
    
    analytics = await attendance_repo.get_analytics_data(org_id, start_date, end_date)
    
    assert analytics["avg_punctuality"] == 83.33
    assert analytics["peak_arrival_time"] == "08:30"
    assert analytics["total_hours_worked"] == 10.0
    assert len(analytics["daily_trends"]) == 1
    assert analytics["status_breakdown"]["present"] == 10
    assert analytics["status_breakdown"]["late"] == 2
