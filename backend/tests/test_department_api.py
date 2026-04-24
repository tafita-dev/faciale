import pytest
from unittest.mock import AsyncMock, MagicMock
from fastapi.testclient import TestClient
from app.main import app
from app.core.security import create_access_token
from app.db.mongodb import get_database
from app.api.deps import get_current_user

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
async def test_create_department_success(mock_db, mock_org_admin_user):
    token = get_orgadmin_token()
    
    mock_db["departments"].find_one.return_value = None
    mock_db["departments"].insert_one.return_value = MagicMock(inserted_id="dept123")
    
    response = client.post(
        "/api/v1/departments/",
        headers={"Authorization": f"Bearer {token}"},
        json={"name": "Engineering"}
    )
    
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Engineering"
    assert data["org_id"] == "org_a"

@pytest.mark.asyncio
async def test_list_departments_success(mock_db, mock_org_admin_user):
    token = get_orgadmin_token()
    mock_depts = [
        {"_id": "dept1", "name": "Engineering", "org_id": "org_a"},
        {"_id": "dept2", "name": "HR", "org_id": "org_a"}
    ]
    
    mock_cursor = MagicMock()
    mock_cursor.to_list = AsyncMock(return_value=mock_depts)
    mock_db["departments"].find.return_value = mock_cursor
    
    response = client.get(
        "/api/v1/departments/",
        headers={"Authorization": f"Bearer {token}"}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 2
    assert data[0]["name"] == "Engineering"
    assert data[1]["name"] == "HR"
    # Verify that find was called with org_id filter
    mock_db["departments"].find.assert_called_once_with({"org_id": "org_a"})

@pytest.mark.asyncio
async def test_list_departments_empty(mock_db, mock_org_admin_user):
    token = get_orgadmin_token()
    
    mock_cursor = MagicMock()
    mock_cursor.to_list = AsyncMock(return_value=[])
    mock_db["departments"].find.return_value = mock_cursor
    
    response = client.get(
        "/api/v1/departments/",
        headers={"Authorization": f"Bearer {token}"}
    )
    
    assert response.status_code == 200
    assert response.json() == []

@pytest.mark.asyncio
async def test_create_department_duplicate(mock_db, mock_org_admin_user):
    token = get_orgadmin_token()
    
    mock_db["departments"].find_one.return_value = {"_id": "existing", "name": "Engineering", "org_id": "org_a"}
    
    response = client.post(
        "/api/v1/departments/",
        headers={"Authorization": f"Bearer {token}"},
        json={"name": "Engineering"}
    )
    
    assert response.status_code == 400
    assert response.json()["detail"] == "Department with this name already exists in your organization."

@pytest.mark.asyncio
async def test_list_departments_multi_tenancy(mock_db, mock_org_admin_user):
    # Org A admin
    token_a = get_orgadmin_token(org_id="org_a")
    
    # Mock data for both orgs
    mock_depts = [
        {"_id": "dept1", "name": "Eng A", "org_id": "org_a"},
        {"_id": "dept2", "name": "HR A", "org_id": "org_a"}
    ]
    
    mock_cursor = MagicMock()
    mock_cursor.to_list = AsyncMock(return_value=mock_depts)
    mock_db["departments"].find.return_value = mock_cursor
    
    # Request as Org A
    response = client.get(
        "/api/v1/departments/",
        headers={"Authorization": f"Bearer {token_a}"}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 2
    # Verify filter was correct
    mock_db["departments"].find.assert_called_with({"org_id": "org_a"})

@pytest.mark.asyncio
async def test_create_department_no_org_id(mock_db):
    # User with no org_id (e.g. malformed or different role)
    user = {"email": "baduser@example.com", "role": "org_admin"} # missing org_id
    app.dependency_overrides[get_current_user] = lambda: user
    token = create_access_token({"sub": "baduser@example.com", "role": "org_admin"})
    
    response = client.post(
        "/api/v1/departments/",
        headers={"Authorization": f"Bearer {token}"},
        json={"name": "Engineering"}
    )
    
    assert response.status_code == 403
    app.dependency_overrides.pop(get_current_user, None)
