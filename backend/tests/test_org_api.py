import pytest
from unittest.mock import AsyncMock, MagicMock
from fastapi.testclient import TestClient
from app.main import app
from app.core.security import create_access_token
from app.db.mongodb import get_database
from app.api.deps import get_current_user

client = TestClient(app)

def get_superuser_token():
    return create_access_token({"sub": "admin@example.com", "role": "admin"})

def get_orgadmin_token():
    return create_access_token({"sub": "orgadmin@example.com", "role": "admin", "org_id": "some_org"})

@pytest.fixture
def mock_db():
    mock_db_instance = MagicMock()
    mock_coll = MagicMock() # Use MagicMock for collection to control find()
    mock_db_instance.__getitem__.return_value = mock_coll
    
    # Setup async methods on collection
    mock_coll.find_one = AsyncMock()
    mock_coll.insert_one = AsyncMock()
    mock_coll.delete_one = AsyncMock()
    
    app.dependency_overrides[get_database] = lambda: mock_db_instance
    yield mock_db_instance
    app.dependency_overrides.pop(get_database, None)

@pytest.fixture
def mock_admin_user():
    user = {"email": "admin@example.com", "role": "admin"}
    app.dependency_overrides[get_current_user] = lambda: user
    yield user
    app.dependency_overrides.pop(get_current_user, None)

@pytest.fixture
def mock_admin_user():
    user = {"email": "orgadmin@example.com", "role": "admin", "org_id": "some_org"}
    app.dependency_overrides[get_current_user] = lambda: user
    yield user
    app.dependency_overrides.pop(get_current_user, None)

def get_superadmin_token():
    return create_access_token({"sub": "superadmin@example.com", "role": "superadmin"})

@pytest.fixture
def mock_superadmin_user():
    user = {"email": "superadmin@example.com", "role": "superadmin"}
    app.dependency_overrides[get_current_user] = lambda: user
    yield user
    app.dependency_overrides.pop(get_current_user, None)

@pytest.mark.asyncio
async def test_create_organization_superadmin_success(mock_db, mock_superadmin_user):
    superadmin_token = get_superadmin_token()
    
    mock_db["organizations"].find_one.return_value = None
    mock_db["organizations"].insert_one.return_value = MagicMock(inserted_id="org456")
    mock_db["users"].find_one.return_value = None
    mock_db["users"].insert_one.return_value = MagicMock(inserted_id="user789")
    
    response = client.post(
        "/api/v1/orgs/",
        headers={"Authorization": f"Bearer {superadmin_token}"},
        json={
            "name": "Super School",
            "type": "school",
            "admin_name": "Initial Admin",
            "admin_email": "admin@school.com",
            "admin_password": "password123"
        }
    )
    
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Super School"

@pytest.mark.asyncio
async def test_create_organization_success(mock_db, mock_superadmin_user):
    # Renamed to reflect it needs superadmin
    superadmin_token = get_superadmin_token()
    
    mock_db["organizations"].find_one.return_value = None
    mock_db["organizations"].insert_one.return_value = MagicMock(inserted_id="org123")
    mock_db["users"].find_one.return_value = None
    mock_db["users"].insert_one.return_value = MagicMock(inserted_id="user123")
    
    response = client.post(
        "/api/v1/orgs/",
        headers={"Authorization": f"Bearer {superadmin_token}"},
        json={
            "name": "Test School",
            "type": "school",
            "admin_name": "Test Admin",
            "admin_email": "test@admin.com",
            "admin_password": "password123"
        }
    )
    
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Test School"
    assert data["type"] == "school"

@pytest.mark.asyncio
async def test_create_organization_unauthorized(mock_db, mock_admin_user):
    orgadmin_token = get_orgadmin_token()
    
    response = client.post(
        "/api/v1/orgs/",
        headers={"Authorization": f"Bearer {orgadmin_token}"},
        json={
            "name": "Test School",
            "type": "school",
            "admin_name": "Test Admin",
            "admin_email": "test@admin.com",
            "admin_password": "password123"
        }
    )
    
    assert response.status_code == 403

@pytest.mark.asyncio
async def test_list_organizations_success(mock_db, mock_superadmin_user):
    # List also requires superadmin
    superadmin_token = get_superadmin_token()
    mock_orgs = [
        {"_id": "org1", "name": "School 1", "type": "school"},
        {"_id": "org2", "name": "Company 1", "type": "company"}
    ]
    
    mock_cursor = MagicMock()
    mock_cursor.to_list = AsyncMock(return_value=mock_orgs)
    mock_db["organizations"].find.return_value = mock_cursor
    
    response = client.get(
        "/api/v1/orgs/",
        headers={"Authorization": f"Bearer {superadmin_token}"}
    )
    
    assert response.status_code == 200
    assert len(response.json()) == 2

@pytest.mark.asyncio
async def test_delete_organization_superadmin_success(mock_db, mock_superadmin_user):
    org_id = "org123"
    superadmin_token = get_superadmin_token()
    
    mock_db["organizations"].find_one.return_value = {"_id": org_id, "name": "Test Org"}
    mock_db["organizations"].delete_one.return_value = MagicMock(deleted_count=1)
    
    response = client.delete(
        f"/api/v1/orgs/{org_id}",
        headers={"Authorization": f"Bearer {superadmin_token}"}
    )
    
    assert response.status_code == 204
    mock_db["organizations"].delete_one.assert_called_once_with({"_id": org_id})

@pytest.mark.asyncio
async def test_delete_organization_not_found(mock_db, mock_superadmin_user):
    org_id = "nonexistent"
    superadmin_token = get_superadmin_token()
    
    mock_db["organizations"].find_one.return_value = None
    
    response = client.delete(
        f"/api/v1/orgs/{org_id}",
        headers={"Authorization": f"Bearer {superadmin_token}"}
    )
    
    assert response.status_code == 404
    assert response.json()["detail"] == "Organization not found"

@pytest.mark.asyncio
async def test_delete_organization_unauthorized_admin(mock_db, mock_admin_user):
    org_id = "org123"
    superuser_token = get_superuser_token()
    
    response = client.delete(
        f"/api/v1/orgs/{org_id}",
        headers={"Authorization": f"Bearer {superuser_token}"}
    )
    
    # Based on technical notes, only superadmin should delete
    assert response.status_code == 403

@pytest.mark.asyncio
async def test_delete_organization_unauthorized_orgadmin(mock_db, mock_admin_user):
    org_id = "org123"
    orgadmin_token = get_orgadmin_token()
    
    response = client.delete(
        f"/api/v1/orgs/{org_id}",
        headers={"Authorization": f"Bearer {orgadmin_token}"}
    )
    
    assert response.status_code == 403
