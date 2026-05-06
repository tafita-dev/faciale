import pytest
import httpx
from unittest.mock import AsyncMock, patch
from app.api import deps
from app.models.attendance import AttendanceType, AttendanceStatus
from app.main import app

import pytest_asyncio

@pytest_asyncio.fixture
async def client():
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://testserver") as c:
        yield c

@pytest.fixture
def mock_user():
    return {
        "_id": "user123",
        "org_id": "org123",
        "role": "admin"
    }

@pytest.fixture
def mock_attendance_service():
    return AsyncMock()

@pytest.fixture
def mock_employee_repo():
    repo = AsyncMock()
    repo.get_employee.return_value = AsyncMock(name="Test Employee")
    repo.get_employee.return_value.name = "John Doe"
    return repo

@pytest.mark.asyncio
async def test_check_in_success_entry(client, mock_user, mock_attendance_service, mock_employee_repo):
    # Setup mocks
    mock_attendance_service.process_attendance.return_value = {
        "status": "present",
        "type": AttendanceType.entry,
        "employee_id": "emp456",
        "score": 0.92
    }
    
    app.dependency_overrides[deps.check_only_user] = lambda: mock_user
    app.dependency_overrides[deps.get_attendance_service] = lambda: mock_attendance_service
    app.dependency_overrides[deps.get_employee_repository] = lambda: mock_employee_repo
    
    app.dependency_overrides[deps.get_attendance_repository] = lambda: AsyncMock()
    
    # Execute
    with open("tests/real_face.jpg", "rb") as f:
        response = await client.post(
            "/api/v1/attendance/check-in",
            files={"file": ("test.jpg", f, "image/jpeg")}
        )
    
    # Verify
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["message"] == "Bienvenue John Doe"
    assert data["data"]["type"] == "entry"
    assert data["ui"]["color"] == "green"
    assert data["ui"]["icon"] == "login"
    
    app.dependency_overrides.clear()

@pytest.mark.asyncio
async def test_check_in_success_exit(client, mock_user, mock_attendance_service, mock_employee_repo):
    # Setup mocks
    mock_attendance_service.process_attendance.return_value = {
        "status": "success",
        "type": AttendanceType.exit,
        "employee_id": "emp456",
        "score": 0.88
    }
    
    app.dependency_overrides[deps.check_only_user] = lambda: mock_user
    app.dependency_overrides[deps.get_attendance_service] = lambda: mock_attendance_service
    app.dependency_overrides[deps.get_employee_repository] = lambda: mock_employee_repo
    
    app.dependency_overrides[deps.get_attendance_repository] = lambda: AsyncMock()
    
    # Execute
    with open("tests/real_face.jpg", "rb") as f:
        response = await client.post(
            "/api/v1/attendance/check-in",
            files={"file": ("test.jpg", f, "image/jpeg")}
        )
    
    # Verify
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["message"] == "Au revoir John Doe"
    assert data["data"]["type"] == "exit"
    assert data["ui"]["color"] == "blue"
    assert data["ui"]["icon"] == "logout"
    
    app.dependency_overrides.clear()

@pytest.mark.asyncio
async def test_check_in_no_face_detected(client, mock_user, mock_attendance_service):
    # Setup mocks
    # Service raises ValueError if no face detected
    mock_attendance_service.process_attendance.side_effect = ValueError("No face detected")
    
    app.dependency_overrides[deps.check_only_user] = lambda: mock_user
    app.dependency_overrides[deps.get_attendance_service] = lambda: mock_attendance_service
    app.dependency_overrides[deps.get_employee_repository] = lambda: mock_employee_repo
    app.dependency_overrides[deps.get_attendance_repository] = lambda: AsyncMock()
    
    # Execute
    with open("tests/real_face.jpg", "rb") as f:
        response = await client.post(
            "/api/v1/attendance/check-in",
            files={"file": ("test.jpg", f, "image/jpeg")}
        )
    
    # Verify
    assert response.status_code == 400
    data = response.json()
    assert data["success"] is False
    assert data["message"] == "Aucun visage détecté"
    
    app.dependency_overrides.clear()

@pytest.mark.asyncio
async def test_check_in_not_recognized(client, mock_user, mock_attendance_service):
    # Setup mocks
    mock_attendance_service.process_attendance.return_value = {
        "status": "failed",
        "reason": "no_match",
        "score": 0.45
    }
    
    app.dependency_overrides[deps.check_only_user] = lambda: mock_user
    app.dependency_overrides[deps.get_attendance_service] = lambda: mock_attendance_service
    app.dependency_overrides[deps.get_employee_repository] = lambda: mock_employee_repo
    app.dependency_overrides[deps.get_attendance_repository] = lambda: AsyncMock()
    
    # Execute
    with open("tests/real_face.jpg", "rb") as f:
        response = await client.post(
            "/api/v1/attendance/check-in",
            files={"file": ("test.jpg", f, "image/jpeg")}
        )
    
    # Verify
    # AC says "Then the API returns an error with message 'Utilisateur non reconnu' and ui.color is 'red'"
    # It doesn't specify status code for functional failure, but usually 200 with success=False or 400.
    # Given the previous turn, success=False was used.
    assert response.status_code == 200 or response.status_code == 400
    data = response.json()
    assert data["success"] is False
    assert data["message"] == "Utilisateur non reconnu"
    assert data["ui"]["color"] == "red"
    
    app.dependency_overrides.clear()

@pytest.mark.asyncio
async def test_check_in_invalid_format(client, mock_user):
    app.dependency_overrides[deps.check_only_user] = lambda: mock_user
    app.dependency_overrides[deps.get_attendance_service] = lambda: AsyncMock()
    app.dependency_overrides[deps.get_employee_repository] = lambda: AsyncMock()
    app.dependency_overrides[deps.get_attendance_repository] = lambda: AsyncMock()
    
    # Execute with a text file
    response = await client.post(
        "/api/v1/attendance/check-in",
        files={"file": ("test.txt", b"not an image", "text/plain")}
    )
    
    # Verify
    assert response.status_code == 400
    data = response.json()
    assert data["success"] is False
    assert "Type de fichier invalide" in data["message"]
    assert data["ui"]["color"] == "red"
    
    app.dependency_overrides.clear()

@pytest.mark.asyncio
async def test_check_in_too_large(client, mock_user):
    app.dependency_overrides[deps.check_only_user] = lambda: mock_user
    app.dependency_overrides[deps.get_attendance_service] = lambda: AsyncMock()
    app.dependency_overrides[deps.get_employee_repository] = lambda: AsyncMock()
    app.dependency_overrides[deps.get_attendance_repository] = lambda: AsyncMock()
    
    # Execute with a large file (6MB)
    large_content = b"0" * (6 * 1024 * 1024)
    response = await client.post(
        "/api/v1/attendance/check-in",
        files={"file": ("large.jpg", large_content, "image/jpeg")}
    )
    
    # Verify
    assert response.status_code == 400
    data = response.json()
    assert data["success"] is False
    assert "trop volumineux" in data["message"]
    assert data["ui"]["color"] == "red"
    
    app.dependency_overrides.clear()

@pytest.mark.asyncio
async def test_check_in_spoof_detected(client, mock_user, mock_attendance_service):
    # Setup mocks
    mock_attendance_service.process_attendance.return_value = {
        "status": "failed",
        "reason": "spoof_detected",
        "score": 0.12
    }
    
    app.dependency_overrides[deps.check_only_user] = lambda: mock_user
    app.dependency_overrides[deps.get_attendance_service] = lambda: mock_attendance_service
    app.dependency_overrides[deps.get_employee_repository] = lambda: mock_employee_repo
    app.dependency_overrides[deps.get_attendance_repository] = lambda: AsyncMock()
    
    # Execute
    with open("tests/real_face.jpg", "rb") as f:
        response = await client.post(
            "/api/v1/attendance/check-in",
            files={"file": ("test.jpg", f, "image/jpeg")}
        )
    
    # Verify
    data = response.json()
    assert data["success"] is False
    assert data["message"] == "Vérification échouée"
    assert data["ui"]["color"] == "red"
    
    app.dependency_overrides.clear()

@pytest.mark.asyncio
async def test_check_in_threshold_enforcement(client, mock_user, mock_attendance_service):
    # Setup mocks: score is 0.65 (below 0.7)
    mock_attendance_service.process_attendance.return_value = {
        "status": "failed",
        "reason": "no_match",
        "score": 0.65
    }
    
    app.dependency_overrides[deps.check_only_user] = lambda: mock_user
    app.dependency_overrides[deps.get_attendance_service] = lambda: mock_attendance_service
    app.dependency_overrides[deps.get_employee_repository] = lambda: AsyncMock()
    app.dependency_overrides[deps.get_attendance_repository] = lambda: AsyncMock()
    
    # Execute
    with open("tests/real_face.jpg", "rb") as f:
        response = await client.post(
            "/api/v1/attendance/check-in",
            files={"file": ("test.jpg", f, "image/jpeg")}
        )
    
    # Verify
    data = response.json()
    assert data["success"] is False
    assert data["message"] == "Utilisateur non reconnu"
    
    app.dependency_overrides.clear()
