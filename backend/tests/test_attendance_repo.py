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
