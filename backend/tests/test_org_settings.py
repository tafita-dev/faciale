import pytest
from unittest.mock import AsyncMock, MagicMock
from fastapi.testclient import TestClient
from app.main import app
from app.core.security import create_access_token
from app.db.mongodb import get_database
from app.api.deps import get_current_user

client = TestClient(app)

def get_orgadmin_token():
    return create_access_token({"sub": "orgadmin@example.com", "role": "admin", "org_id": "org123"})

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

@pytest.fixture
def mock_org_admin():
    user = {"email": "orgadmin@example.com", "role": "admin", "org_id": "org123"}
    app.dependency_overrides[get_current_user] = lambda: user
    yield user
    app.dependency_overrides.pop(get_current_user, None)

@pytest.mark.asyncio
async def test_update_org_settings_success(mock_db, mock_org_admin):
    org_id = "org123"
    token = get_orgadmin_token()
    
    # Mock finding the organization
    mock_db["organizations"].find_one.side_effect = [
        {"_id": org_id, "name": "Test Org", "type": "school"}, # Before update
        {"_id": org_id, "name": "Test Org", "type": "school", "settings": {"start_time": "09:00", "late_buffer_minutes": 15}} # After update
    ]
    
    response = client.patch(
        f"/api/v1/orgs/settings",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "settings": {
                "start_time": "09:00",
                "late_buffer_minutes": 15
            }
        }
    )
    
    assert response.status_code == 200
    data = response.json()
    assert data["settings"]["start_time"] == "09:00"
    assert data["settings"]["late_buffer_minutes"] == 15
    
    # Verify update_one was called
    mock_db["organizations"].update_one.assert_called_once()
    args, kwargs = mock_db["organizations"].update_one.call_args
    assert args[0] == {"_id": org_id}
    assert "$set" in args[1]
    assert args[1]["$set"]["settings"]["start_time"] == "09:00"

@pytest.mark.asyncio
async def test_update_org_settings_invalid_time(mock_db, mock_org_admin):
    token = get_orgadmin_token()
    
    response = client.patch(
        f"/api/v1/orgs/settings",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "settings": {
                "start_time": "25:00",
                "late_buffer_minutes": 15
            }
        }
    )
    
    assert response.status_code == 422 # Pydantic validation error or custom error
