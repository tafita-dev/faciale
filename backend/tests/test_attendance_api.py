import pytest
from fastapi.testclient import TestClient
from unittest.mock import AsyncMock, patch, MagicMock
from app.main import app
from app.api import deps
from datetime import datetime, timezone, timedelta

client = TestClient(app)

@pytest.fixture
def mock_user():
    return {
        "_id": "user123",
        "email": "scanner@org.com",
        "org_id": "org_a",
        "role": "scanner"
    }

@pytest.fixture
def mock_attendance_service():
    return AsyncMock()

@pytest.fixture
def mock_employee_repo():
    return AsyncMock()

@pytest.fixture
def mock_attendance_repo():
    return AsyncMock()

@pytest.fixture
def override_deps(mock_user, mock_attendance_service, mock_employee_repo, mock_attendance_repo):
    app.dependency_overrides[deps.get_current_user] = lambda: mock_user
    app.dependency_overrides[deps.get_attendance_service] = lambda: mock_attendance_service
    app.dependency_overrides[deps.get_employee_repository] = lambda: mock_employee_repo
    app.dependency_overrides[deps.get_attendance_repository] = lambda: mock_attendance_repo
    yield
    app.dependency_overrides.clear()

@pytest.mark.asyncio
async def test_check_in_success(override_deps, mock_attendance_service, mock_employee_repo, mock_attendance_repo):
    mock_attendance_service.process_attendance.return_value = {
        "status": "success",
        "employee_id": "emp123",
        "score": 0.95
    }
    
    mock_employee = MagicMock()
    mock_employee.name = "John Doe"
    mock_employee_repo.get_employee.return_value = mock_employee
    
    mock_attendance_repo.get_last_success_log.return_value = None
    
    file_content = b"fake image content"
    response = client.post(
        "/api/v1/attendance/check-in",
        files={"file": ("test.jpg", file_content, "image/jpeg")}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert "John Doe" in data["message"]
    assert "timestamp" in data["data"]

@pytest.mark.asyncio
async def test_check_in_debouncing(override_deps, mock_attendance_service, mock_employee_repo, mock_attendance_repo):
    mock_attendance_service.process_attendance.return_value = {
        "status": "success",
        "employee_id": "emp123",
        "score": 0.95
    }
    
    mock_employee = MagicMock()
    mock_employee.name = "John Doe"
    mock_employee_repo.get_employee.return_value = mock_employee
    
    # Mock recent log
    recent_log = MagicMock()
    recent_log.timestamp = datetime.now(timezone.utc) - timedelta(seconds=30)
    mock_attendance_repo.get_last_success_log.return_value = recent_log
    
    file_content = b"fake image content"
    response = client.post(
        "/api/v1/attendance/check-in",
        files={"file": ("test.jpg", file_content, "image/jpeg")}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is False
    assert "already checked in" in data["message"].lower()

@pytest.mark.asyncio
async def test_check_in_no_file(override_deps):
    response = client.post("/api/v1/attendance/check-in")
    assert response.status_code == 422 # FastAPI validation error for missing file

@pytest.mark.asyncio
async def test_check_in_invalid_file_type(override_deps):
    file_content = b"fake pdf content"
    response = client.post(
        "/api/v1/attendance/check-in",
        files={"file": ("test.pdf", file_content, "application/pdf")}
    )
    assert response.status_code == 400
    assert "Invalid file type" in response.json()["error"]["message"]

@pytest.mark.asyncio
async def test_check_in_corrupted_image(override_deps, mock_attendance_service):
    mock_attendance_service.process_attendance.side_effect = ValueError("Failed to decode image from bytes")
    
    file_content = b"corrupted data"
    response = client.post(
        "/api/v1/attendance/check-in",
        files={"file": ("test.jpg", file_content, "image/jpeg")}
    )
    
    assert response.status_code == 400
    assert "Invalid image data" in response.json()["error"]["message"]
