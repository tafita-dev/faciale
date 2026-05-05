import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.core.security import create_access_token
from app.db.mongodb import get_database
from unittest.mock import AsyncMock, MagicMock

client = TestClient(app)

@pytest.fixture
def mock_db():
    mock_db_instance = MagicMock()
    
    users_coll = MagicMock()
    orgs_coll = MagicMock()
    
    users_coll.find_one = AsyncMock()
    orgs_coll.find_one = AsyncMock()
    
    def get_item(name):
        if name == "users":
            return users_coll
        if name == "organizations":
            return orgs_coll
        return MagicMock()
    
    mock_db_instance.__getitem__.side_effect = get_item
    
    app.dependency_overrides[get_database] = lambda: mock_db_instance
    yield mock_db_instance
    app.dependency_overrides.pop(get_database, None)

def test_org_admin_can_get_own_org(mock_db):
    org_id = "org123"
    token = create_access_token({"sub": "admin@test.com", "role": "admin", "org_id": org_id})
    
    # Mock user in DB (needed for get_current_user)
    mock_db["users"].find_one.return_value = {"email": "admin@test.com", "role": "admin", "org_id": org_id}
    
    # Mock org in DB
    mock_db["organizations"].find_one.return_value = {"_id": org_id, "name": "Test Org", "type": "school"}
    
    response = client.get(
        f"/api/v1/orgs/{org_id}",
        headers={"Authorization": f"Bearer {token}"}
    )
    
    # This should fail with 403 currently as it requires superadmin
    assert response.status_code == 200
    assert response.json()["name"] == "Test Org"

def test_org_admin_cannot_get_other_org(mock_db):
    my_org_id = "org123"
    other_org_id = "other456"
    token = create_access_token({"sub": "admin@test.com", "role": "admin", "org_id": my_org_id})
    
    mock_db["users"].find_one.return_value = {"email": "admin@test.com", "role": "admin", "org_id": my_org_id}
    
    response = client.get(
        f"/api/v1/orgs/{other_org_id}",
        headers={"Authorization": f"Bearer {token}"}
    )
    
    assert response.status_code == 403
