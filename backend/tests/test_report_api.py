import pytest
from fastapi.testclient import TestClient
from unittest.mock import AsyncMock, patch
from app.main import app
from app.api import deps

client = TestClient(app)

@pytest.fixture
def mock_user():
    return {
        "_id": "user123",
        "email": "admin@org.com",
        "org_id": "org_a",
        "role": "org_admin"
    }

@pytest.fixture
def mock_reporting_service():
    return AsyncMock()

@pytest.fixture
def override_deps(mock_user, mock_reporting_service):
    app.dependency_overrides[deps.get_current_user] = lambda: mock_user
    # We will add get_reporting_service to deps later
    app.dependency_overrides[deps.get_reporting_service] = lambda: mock_reporting_service
    yield
    app.dependency_overrides.clear()

@pytest.mark.asyncio
async def test_get_attendance_stats_success(override_deps, mock_reporting_service):
    mock_reporting_service.get_today_stats.return_value = {
        "present": 10,
        "late": 2,
        "absent": 5,
        "total": 15
    }
    
    response = client.get("/api/v1/reports/stats")
    
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["data"]["present"] == 10
    assert data["data"]["late"] == 2
    assert data["data"]["absent"] == 5
    assert data["data"]["total"] == 15

@pytest.mark.asyncio
async def test_get_attendance_stats_unauthorized():
    # No override_deps here means get_current_user will use oauth2_scheme which fails without token
    response = client.get("/api/v1/reports/stats")
    assert response.status_code == 401

@pytest.mark.asyncio
async def test_get_attendance_logs_success(override_deps, mock_reporting_service):
    mock_reporting_service.get_logs.return_value = {
        "items": [
            {
                "id": "log1",
                "employee_name": "John Doe",
                "timestamp": "2023-01-01T09:00:00Z",
                "status": "success"
            }
        ],
        "total": 1,
        "page": 1,
        "size": 10
    }
    
    response = client.get("/api/v1/reports/logs?page=1&size=10")
    
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert len(data["data"]["items"]) == 1
    assert data["data"]["total"] == 1

@pytest.mark.asyncio
async def test_get_attendance_logs_filter_date(override_deps, mock_reporting_service):
    mock_reporting_service.get_logs.return_value = {"items": [], "total": 0, "page": 1, "size": 10}
    
    response = client.get("/api/v1/reports/logs?start_date=2023-01-01&end_date=2023-01-31")
    
    assert response.status_code == 200
    mock_reporting_service.get_logs.assert_called_once()
    args, kwargs = mock_reporting_service.get_logs.call_args
    assert kwargs["start_date"] == "2023-01-01"
    assert kwargs["end_date"] == "2023-01-31"

@pytest.mark.asyncio
async def test_get_attendance_logs_filter_dept(override_deps, mock_reporting_service):
    mock_reporting_service.get_logs.return_value = {"items": [], "total": 0, "page": 1, "size": 10}
    
    response = client.get("/api/v1/reports/logs?dept_id=dept123")
    
    assert response.status_code == 200
    mock_reporting_service.get_logs.assert_called_once()
    args, kwargs = mock_reporting_service.get_logs.call_args
    assert kwargs["dept_id"] == "dept123"

@pytest.mark.asyncio
async def test_export_attendance_logs_csv_success(override_deps, mock_reporting_service):
    async def mock_generator():
        yield "Date,Time,Employee Name,Department,Status,Confidence Score\n"
        yield "2023-01-01,09:00,John Doe,HR,success,0.95\n"
        
    mock_reporting_service.export_logs.return_value = mock_generator()
    
    response = client.get("/api/v1/reports/export?format=csv")
    
    assert response.status_code == 200
    assert response.headers["Content-Type"] == "text/csv; charset=utf-8"
    assert "attachment; filename=attendance_logs_" in response.headers["Content-Disposition"]
    assert "Date,Time,Employee Name,Department,Status,Confidence Score" in response.text
    assert "John Doe,HR,success,0.95" in response.text
