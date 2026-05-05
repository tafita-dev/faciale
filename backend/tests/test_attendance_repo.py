import pytest
from unittest.mock import AsyncMock, MagicMock
from app.repositories.attendance import AttendanceRepository
from app.models.attendance import AttendanceLog, AttendanceStatus

@pytest.mark.asyncio
async def test_create_log():
    mock_db = MagicMock()
    mock_collection = AsyncMock()
    mock_db.__getitem__.return_value = mock_collection
    
    repo = AttendanceRepository(db=mock_db)
    
    log = AttendanceLog(
        org_id="org_a",
        employee_id="emp123",
        status=AttendanceStatus.success,
        confidence_score=0.95
    )
    
    await repo.create_log(log)
    
    mock_collection.insert_one.assert_called_once()
    args, _ = mock_collection.insert_one.call_args
    inserted_doc = args[0]
    
    assert inserted_doc["org_id"] == "org_a"
    assert inserted_doc["employee_id"] == "emp123"
    assert inserted_doc["status"] == "success"
    assert inserted_doc["confidence_score"] == 0.95
    assert "_id" in inserted_doc
    assert "timestamp" in inserted_doc

@pytest.mark.asyncio
async def test_count_logs_today_query():
    mock_db = MagicMock()
    mock_collection = MagicMock()
    mock_collection.count_documents = AsyncMock(return_value=0)
    mock_db.__getitem__.return_value = mock_collection
    
    from unittest.mock import patch
    from datetime import timezone
    with patch("app.repositories.attendance.get_database", return_value=mock_db):
        repo = AttendanceRepository()
        org_id = "test_org"
        emp_id = "test_emp"
        
        await repo.count_logs_today(org_id, emp_id)
        
        # Verify query
        mock_collection.count_documents.assert_called_once()
        query = mock_collection.count_documents.call_args[0][0]
        
        assert query["org_id"] == org_id
        assert query["employee_id"] == emp_id
        assert "timestamp" in query
        assert "$gte" in query["timestamp"]
        
        # Ensure timestamp is timezone-aware UTC
        start_of_today = query["timestamp"]["$gte"]
        assert start_of_today.tzinfo is not None
        assert start_of_today.tzinfo == timezone.utc

@pytest.mark.asyncio
async def test_get_logs_with_employee_info_type():
    mock_db = MagicMock()
    mock_collection = MagicMock()
    mock_db.__getitem__.return_value = mock_collection
    
    # Mock aggregation result
    mock_cursor = MagicMock()
    mock_cursor.to_list = AsyncMock(return_value=[{
        "metadata": [{"total": 1}],
        "data": [{
            "id": "123",
            "attendance_type": "exit",
            "status": "success",
            "type": "exit"
        }]
    }])
    mock_collection.aggregate.return_value = mock_cursor
    
    from unittest.mock import patch
    with patch("app.repositories.attendance.get_database", return_value=mock_db):
        repo = AttendanceRepository()
        items, total = await repo.get_logs_with_employee_info("org123")
        
        assert len(items) == 1
        assert items[0]["type"] == "exit"
