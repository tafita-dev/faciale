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
    return create_access_token({"sub": "orgadmin@example.com", "role": "org_admin", "org_id": "some_org"})

@pytest.fixture
def mock_db():
    mock_db_instance = MagicMock()
    mock_coll = MagicMock() # Use MagicMock for collection to control find()
    mock_db_instance.__getitem__.return_value = mock_coll
    
    # Setup async methods on collection
    mock_coll.find_one = AsyncMock()
    mock_coll.insert_one = AsyncMock()
    
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
def mock_org_admin_user():
    user = {"email": "orgadmin@example.com", "role": "org_admin", "org_id": "some_org"}
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
    
    response = client.post(
        "/api/v1/orgs/",
        headers={"Authorization": f"Bearer {superadmin_token}"},
        json={"name": "Super School", "type": "school"}
    )
    
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Super School"

@pytest.mark.asyncio
async def test_create_organization_success(mock_db, mock_admin_user):
    superuser_token = get_superuser_token()
    
    mock_db["organizations"].find_one.return_value = None
    mock_db["organizations"].insert_one.return_value = MagicMock(inserted_id="org123")
    
    response = client.post(
        "/api/v1/orgs/",
        headers={"Authorization": f"Bearer {superuser_token}"},
        json={"name": "Test School", "type": "school"}
    )
    
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Test School"
    assert data["type"] == "school"

@pytest.mark.asyncio
async def test_create_organization_unauthorized(mock_db, mock_org_admin_user):
    orgadmin_token = get_orgadmin_token()
    
    response = client.post(
        "/api/v1/orgs/",
        headers={"Authorization": f"Bearer {orgadmin_token}"},
        json={"name": "Test School", "type": "school"}
    )
    
    assert response.status_code == 403

@pytest.mark.asyncio
async def test_list_organizations_success(mock_db, mock_admin_user):
    superuser_token = get_superuser_token()
    mock_orgs = [
        {"_id": "org1", "name": "School 1", "type": "school"},
        {"_id": "org2", "name": "Company 1", "type": "company"}
    ]
    
    mock_cursor = MagicMock()
    mock_cursor.to_list = AsyncMock(return_value=mock_orgs)
    mock_db["organizations"].find.return_value = mock_cursor
    
    response = client.get(
        "/api/v1/orgs/",
        headers={"Authorization": f"Bearer {superuser_token}"}
    )
    
    assert response.status_code == 200
    assert len(response.json()) == 2
