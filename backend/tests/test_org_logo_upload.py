import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from fastapi.testclient import TestClient
from app.main import app
from app.core.security import create_access_token
from app.db.mongodb import get_database
from app.api.deps import get_current_user
import io

client = TestClient(app)

@pytest.fixture
def mock_db():
    mock_db_instance = MagicMock()
    mock_coll = MagicMock()
    mock_db_instance.__getitem__.return_value = mock_coll
    mock_coll.find_one = AsyncMock()
    mock_coll.update_one = AsyncMock()
    app.dependency_overrides[get_database] = lambda: mock_db_instance
    yield mock_db_instance
    app.dependency_overrides.pop(get_database, None)

def get_superadmin_token():
    return create_access_token({"sub": "superadmin@example.com", "role": "superadmin"})

@pytest.fixture
def mock_superadmin_user():
    user = {"email": "superadmin@example.com", "role": "superadmin"}
    app.dependency_overrides[get_current_user] = lambda: user
    yield user
    app.dependency_overrides.pop(get_current_user, None)

@pytest.mark.asyncio
async def test_upload_org_logo_success(mock_db, mock_superadmin_user):
    org_id = "org123"
    token = get_superadmin_token()
    
    mock_db["organizations"].find_one.side_effect = [
        {
            "_id": org_id, 
            "name": "Test Org", 
            "type": "school",
            "logo_url": None
        },
        {
            "_id": org_id, 
            "name": "Test Org", 
            "type": "school",
            "logo_url": "/uploads/logo_filename.png"
        }
    ]
    
    # We will need to implement save_logo in StorageService or use a similar mechanism
    with patch("app.api.v1.endpoints.orgs.StorageService") as MockStorage:
        mock_storage = MockStorage.return_value
        mock_storage.save_logo = AsyncMock(return_value="logo_filename.png")
        
        file_content = b"fake image content"
        file = io.BytesIO(file_content)
        
        response = client.post(
            f"/api/v1/orgs/{org_id}/logo",
            headers={"Authorization": f"Bearer {token}"},
            files={"file": ("logo.png", file, "image/png")}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "logo_url" in data
        assert data["logo_url"].endswith("logo_filename.png")
        
        mock_db["organizations"].update_one.assert_called_once()
        args, _ = mock_db["organizations"].update_one.call_args
        assert args[0] == {"_id": org_id}
        assert "$set" in args[1]
        assert "logo_url" in args[1]["$set"]

@pytest.mark.asyncio
async def test_upload_org_logo_orgadmin_success(mock_db):
    org_id = "org123"
    token = create_access_token({"sub": "orgadmin@example.com", "role": "admin", "org_id": org_id})
    user = {"email": "orgadmin@example.com", "role": "admin", "org_id": org_id}
    app.dependency_overrides[get_current_user] = lambda: user

    mock_db["organizations"].find_one.side_effect = [
        {
            "_id": org_id, 
            "name": "Test Org", 
            "type": "school",
            "logo_url": None
        },
        {
            "_id": org_id, 
            "name": "Test Org", 
            "type": "school",
            "logo_url": "/uploads/logo_filename.png"
        }
    ]
    
    with patch("app.api.v1.endpoints.orgs.StorageService") as MockStorage:
        mock_storage = MockStorage.return_value
        mock_storage.save_logo = AsyncMock(return_value="logo_filename.png")
        
        file_content = b"fake image content"
        file = io.BytesIO(file_content)
        
        response = client.post(
            f"/api/v1/orgs/{org_id}/logo",
            headers={"Authorization": f"Bearer {token}"},
            files={"file": ("logo.png", file, "image/png")}
        )
        
        assert response.status_code == 200
        app.dependency_overrides.pop(get_current_user, None)

@pytest.mark.asyncio
async def test_upload_org_logo_unauthorized(mock_db):
    org_id = "org123"
    other_org_id = "other_org"
    token = create_access_token({"sub": "orgadmin@example.com", "role": "admin", "org_id": other_org_id})
    user = {"email": "orgadmin@example.com", "role": "admin", "org_id": other_org_id}
    app.dependency_overrides[get_current_user] = lambda: user

    response = client.post(
        f"/api/v1/orgs/{org_id}/logo",
        headers={"Authorization": f"Bearer {token}"},
        files={"file": ("logo.png", io.BytesIO(b"content"), "image/png")}
    )
    
    assert response.status_code == 403
    app.dependency_overrides.pop(get_current_user, None)
