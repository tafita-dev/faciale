import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from fastapi.testclient import TestClient
from app.main import app
from app.core.security import create_access_token
from app.db.mongodb import get_database
from app.api.deps import get_current_user
import io

client = TestClient(app)

def get_orgadmin_token(org_id="org_a"):
    return create_access_token({"sub": "orgadmin@example.com", "role": "org_admin", "org_id": org_id})

@pytest.fixture
def mock_db():
    mock_db_instance = MagicMock()
    mock_coll = MagicMock()
    mock_db_instance.__getitem__.return_value = mock_coll
    
    # Setup async methods on collection
    mock_coll.find_one = AsyncMock()
    mock_coll.insert_one = AsyncMock()
    mock_coll.find = MagicMock()
    
    app.dependency_overrides[get_database] = lambda: mock_db_instance
    yield mock_db_instance
    app.dependency_overrides.pop(get_database, None)

@pytest.fixture
def mock_org_admin_user():
    user = {"email": "orgadmin@example.com", "role": "org_admin", "org_id": "org_a"}
    app.dependency_overrides[get_current_user] = lambda: user
    yield user
    app.dependency_overrides.pop(get_current_user, None)

@pytest.mark.asyncio
async def test_enroll_photo_upload_success(mock_db, mock_org_admin_user):
    token = get_orgadmin_token()
    employee_id = "emp123"
    
    # Mock employee exists and belongs to org_a
    mock_db["employees"].find_one.return_value = {"_id": employee_id, "org_id": "org_a"}
    
    file_content = b"fake image content"
    file = io.BytesIO(file_content)
    
    with patch("app.services.enrollment.start_enrollment_pipeline", new_callable=AsyncMock) as mock_pipeline:
        response = client.post(
            f"/api/v1/employees/{employee_id}/enroll",
            headers={"Authorization": f"Bearer {token}"},
            files={"file": ("test.jpg", file, "image/jpeg")}
        )
        
        assert response.status_code == 202
        assert response.json()["message"] == "Enrollment started"
        mock_pipeline.assert_called_once()

@pytest.mark.asyncio
async def test_enroll_photo_upload_unauthorized_org(mock_db, mock_org_admin_user):
    token = get_orgadmin_token()
    employee_id = "emp_other"
    
    # Mock employee not found in org_a
    mock_db["employees"].find_one.return_value = None
    
    file_content = b"fake image content"
    file = io.BytesIO(file_content)
    
    response = client.post(
        f"/api/v1/employees/{employee_id}/enroll",
        headers={"Authorization": f"Bearer {token}"},
        files={"file": ("test.jpg", file, "image/jpeg")}
    )
    
    assert response.status_code == 404
    assert response.json()["detail"] == "Employee not found in your organization"
    mock_db["employees"].find_one.assert_called_once_with({"_id": employee_id, "org_id": "org_a"})

@pytest.mark.asyncio
async def test_enroll_photo_upload_invalid_file_type(mock_db, mock_org_admin_user):
    token = get_orgadmin_token()
    employee_id = "emp123"
    
    # Mock employee exists
    mock_db["employees"].find_one.return_value = {"_id": employee_id, "org_id": "org_a"}
    
    file_content = b"fake pdf content"
    file = io.BytesIO(file_content)
    
    response = client.post(
        f"/api/v1/employees/{employee_id}/enroll",
        headers={"Authorization": f"Bearer {token}"},
        files={"file": ("test.pdf", file, "application/pdf")}
    )
    
    assert response.status_code == 400
    assert response.json()["detail"] == "Invalid file type. Only JPEG and PNG are allowed."

@pytest.mark.asyncio
async def test_enroll_photo_upload_file_too_large(mock_db, mock_org_admin_user):
    token = get_orgadmin_token()
    employee_id = "emp123"
    
    # Mock employee exists
    mock_db["employees"].find_one.return_value = {"_id": employee_id, "org_id": "org_a"}
    
    # Create a "large" file (6MB)
    file_content = b"a" * (6 * 1024 * 1024)
    file = io.BytesIO(file_content)
    
    response = client.post(
        f"/api/v1/employees/{employee_id}/enroll",
        headers={"Authorization": f"Bearer {token}"},
        files={"file": ("large.jpg", file, "image/jpeg")}
    )
    
    assert response.status_code == 400
    assert response.json()["detail"] == "File too large. Maximum size is 5MB."
