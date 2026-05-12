import pytest
from fastapi.testclient import TestClient
from unittest.mock import AsyncMock, patch
from app.main import app
from app.api import deps

@pytest.fixture
def mock_user():
    return {
        "_id": "user123",
        "email": "admin@org.com",
        "org_id": "org_a",
        "role": "admin"
    }

@pytest.fixture
def mock_reporting_service():
    return AsyncMock()

@pytest.fixture
def override_deps(mock_user, mock_reporting_service):
    app.dependency_overrides[deps.get_current_user] = lambda: mock_user
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
    
    with TestClient(app) as client:
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
    with TestClient(app) as client:
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
    
    with TestClient(app) as client:
        response = client.get("/api/v1/reports/logs?page=1&size=10")
    
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert len(data["data"]["items"]) == 1
    assert data["data"]["total"] == 1

@pytest.mark.asyncio
async def test_get_attendance_logs_filter_date(override_deps, mock_reporting_service):
    mock_reporting_service.get_logs.return_value = {"items": [], "total": 0, "page": 1, "size": 10}
    
    with TestClient(app) as client:
        response = client.get("/api/v1/reports/logs?start_date=2023-01-01&end_date=2023-01-31")
    
    assert response.status_code == 200
    mock_reporting_service.get_logs.assert_called_once()
    args, kwargs = mock_reporting_service.get_logs.call_args
    assert kwargs["start_date"] == "2023-01-01"
    assert kwargs["end_date"] == "2023-01-31"

@pytest.mark.asyncio
async def test_get_attendance_logs_filter_dept(override_deps, mock_reporting_service):
    mock_reporting_service.get_logs.return_value = {"items": [], "total": 0, "page": 1, "size": 10}
    
    with TestClient(app) as client:
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
    
    with TestClient(app) as client:
        response = client.get("/api/v1/reports/export?format=csv")
    
    assert response.status_code == 200
    assert response.headers["Content-Type"] == "text/csv; charset=utf-8"
    assert "attachment; filename=attendance_logs_" in response.headers["Content-Disposition"]
    assert "Date,Time,Employee Name,Department,Status,Confidence Score" in response.text
    assert "John Doe,HR,success,0.95" in response.text

@pytest.mark.asyncio
async def test_export_attendance_logs_pdf_success(override_deps, mock_reporting_service):
    async def mock_generator():
        yield b"%PDF-1.4\n"
        yield b"mock pdf content\n"
        
    mock_reporting_service.export_logs.return_value = mock_generator()
    
    with TestClient(app) as client:
        response = client.get("/api/v1/reports/export?format=pdf")
    
    assert response.status_code == 200
    assert response.headers["Content-Type"] == "application/pdf"
    assert "attachment; filename=attendance_logs_" in response.headers["Content-Disposition"]
    assert ".pdf" in response.headers["Content-Disposition"]
    assert b"%PDF-1.4" in response.content

@pytest.fixture
def mock_superadmin():
    return {
        "_id": "super123",
        "email": "superadmin@faciale.com",
        "role": "superadmin"
    }

@pytest.mark.asyncio
async def test_get_system_stats_success(mock_superadmin, mock_reporting_service):
    app.dependency_overrides[deps.check_superadmin] = lambda: mock_superadmin
    app.dependency_overrides[deps.get_reporting_service] = lambda: mock_reporting_service
    
    mock_reporting_service.get_system_stats.return_value = {
        "total_organizations": 5,
        "total_users": 100
    }
    
    with TestClient(app) as client:
        response = client.get("/api/v1/reports/system-stats")
    
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["data"]["total_organizations"] == 5
    assert data["data"]["total_users"] == 100
    
    app.dependency_overrides.clear()

@pytest.mark.asyncio
async def test_get_system_stats_unauthorized(override_deps, mock_reporting_service):
    # override_deps sets user as admin
    with TestClient(app) as client:
        response = client.get("/api/v1/reports/system-stats")
    
    # Since check_superadmin depends on get_current_user, it should fail
    assert response.status_code == 403
    app.dependency_overrides.clear()

@pytest.mark.asyncio
async def test_get_advanced_analytics_success(override_deps, mock_reporting_service):
    mock_reporting_service.get_advanced_analytics.return_value = {
        "avg_punctuality": 85.5,
        "peak_arrival_time": "08:30",
        "total_hours_worked": 120.5,
        "daily_trends": [{"date": "2023-01-01", "count": 10}],
        "status_breakdown": {"present": 10, "late": 2, "absent": 5}
    }
    
    with TestClient(app) as client:
        response = client.get("/api/v1/reports/analytics?start_date=2023-01-01&end_date=2023-01-31")
    
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["data"]["avg_punctuality"] == 85.5
    assert data["data"]["peak_arrival_time"] == "08:30"
    mock_reporting_service.get_advanced_analytics.assert_called_once()
    args, kwargs = mock_reporting_service.get_advanced_analytics.call_args
    assert kwargs["start_date"] == "2023-01-01"
    assert kwargs["end_date"] == "2023-01-31"
