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
async def test_create_employee_success(mock_db, mock_org_admin_user):
    token = get_orgadmin_token()
    
    # Mock department exists and belongs to org_a
    mock_db["departments"].find_one.return_value = {"_id": "dept_x", "name": "Dept X", "org_id": "org_a"}
    mock_db["employees"].insert_one.return_value = MagicMock(inserted_id="emp123")
    
    response = client.post(
        "/api/v1/employees/",
        headers={"Authorization": f"Bearer {token}"},
        json={"name": "John Doe", "dept_id": "dept_x"}
    )
    
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "John Doe"
    assert data["dept_id"] == "dept_x"
    assert data["org_id"] == "org_a"
    assert data["is_active"] is True

@pytest.mark.asyncio
async def test_create_employee_invalid_dept(mock_db, mock_org_admin_user):
    token = get_orgadmin_token()
    
    # Mock department not found (either doesn't exist or belongs to different org)
    mock_db["departments"].find_one.return_value = None
    
    response = client.post(
        "/api/v1/employees/",
        headers={"Authorization": f"Bearer {token}"},
        json={"name": "John Doe", "dept_id": "dept_other"}
    )
    
    assert response.status_code == 400
    assert response.json()["detail"] == "Department not found or does not belong to your organization."
    # Verify the filter included org_id
    mock_db["departments"].find_one.assert_called_with({
        "_id": "dept_other",
        "org_id": "org_a"
    })

@pytest.mark.asyncio
async def test_list_employees_with_filter(mock_db, mock_org_admin_user):
    token = get_orgadmin_token()
    mock_employees = [
        {"_id": "emp1", "name": "John Doe", "dept_id": "dept_x", "org_id": "org_a", "is_active": True},
    ]
    
    mock_cursor = MagicMock()
    mock_cursor.to_list = AsyncMock(return_value=mock_employees)
    mock_db["employees"].find.return_value = mock_cursor
    
    response = client.get(
        "/api/v1/employees/?dept_id=dept_x",
        headers={"Authorization": f"Bearer {token}"}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["dept_id"] == "dept_x"
    # Verify filter was correct
    mock_db["employees"].find.assert_called_with({"org_id": "org_a", "dept_id": "dept_x"})

@pytest.mark.asyncio
async def test_list_employees_no_filter(mock_db, mock_org_admin_user):
    token = get_orgadmin_token()
    mock_employees = [
        {"_id": "emp1", "name": "John Doe", "dept_id": "dept_x", "org_id": "org_a", "is_active": True},
        {"_id": "emp2", "name": "Jane Smith", "dept_id": "dept_y", "org_id": "org_a", "is_active": True},
    ]
    
    mock_cursor = MagicMock()
    mock_cursor.to_list = AsyncMock(return_value=mock_employees)
    mock_db["employees"].find.return_value = mock_cursor
    
    response = client.get(
        "/api/v1/employees/",
        headers={"Authorization": f"Bearer {token}"}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 2
    mock_db["employees"].find.assert_called_with({"org_id": "org_a"})
