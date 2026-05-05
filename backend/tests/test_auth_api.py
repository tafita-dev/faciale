import pytest
from unittest.mock import patch, AsyncMock
from fastapi.testclient import TestClient
from app.main import app
from app.core import security
from app.core.security import get_password_hash

client = TestClient(app)

@pytest.mark.asyncio
async def test_login_success():
    hashed_password = get_password_hash("testpassword")
    mock_user = {
        "email": "test@example.com",
        "password_hash": hashed_password,
        "role": "admin",
        "org_id": "org123"
    }
    
    # Mock find_one for the users collection
    with patch("app.api.v1.endpoints.auth.get_database") as mock_db:
        mock_coll = AsyncMock()
        mock_coll.find_one.return_value = mock_user
        mock_db.return_value.__getitem__.return_value = mock_coll
        
        response = client.post(
            "/api/v1/auth/login",
            data={"username": "test@example.com", "password": "testpassword"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data
        assert data["token_type"] == "bearer"

@pytest.mark.asyncio
async def test_login_invalid_password():
    hashed_password = get_password_hash("testpassword")
    mock_user = {
        "email": "test@example.com",
        "password_hash": hashed_password
    }
    
    with patch("app.api.v1.endpoints.auth.get_database") as mock_db:
        mock_coll = AsyncMock()
        mock_coll.find_one.return_value = mock_user
        mock_db.return_value.__getitem__.return_value = mock_coll
        
        response = client.post(
            "/api/v1/auth/login",
            data={"username": "test@example.com", "password": "wrongpassword"}
        )
        
        assert response.status_code == 401
        assert response.json()["detail"] == "Incorrect email or password"

@pytest.mark.asyncio
async def test_login_user_not_found():
    with patch("app.api.v1.endpoints.auth.get_database") as mock_db:
        mock_coll = AsyncMock()
        mock_coll.find_one.return_value = None
        mock_db.return_value.__getitem__.return_value = mock_coll
        
        response = client.post(
            "/api/v1/auth/login",
            data={"username": "notfound@example.com", "password": "testpassword"}
        )
        
        assert response.status_code == 401
        assert response.json()["detail"] == "Incorrect email or password"

@pytest.mark.asyncio
async def test_read_users_me_success():
    hashed_password = get_password_hash("testpassword")
    mock_user = {
        "email": "test@example.com",
        "password_hash": hashed_password,
        "role": "admin",
        "org_id": "org123",
        "name": "Test User",
        "photo_url": "http://example.com/photo.jpg"
    }
    
    # Get a token first
    with patch("app.api.v1.endpoints.auth.get_database") as mock_db:
        mock_coll = AsyncMock()
        mock_coll.find_one.return_value = mock_user
        mock_db.return_value.__getitem__.return_value = mock_coll
        
        login_response = client.post(
            "/api/v1/auth/login",
            data={"username": "test@example.com", "password": "testpassword"}
        )
        token = login_response.json()["access_token"]

    # Now call a protected endpoint
    # We need to mock get_database again for the dependency get_current_user
    with patch("app.api.deps.get_database") as mock_db:
        mock_coll = AsyncMock()
        mock_coll.find_one.return_value = mock_user
        mock_db.return_value.__getitem__.return_value = mock_coll
        
        response = client.get(
            "/api/v1/auth/me",
            headers={"Authorization": f"Bearer {token}"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["email"] == "test@example.com"
        assert data["name"] == "Test User"
        assert data["role"] == "admin"
        assert data["photo_url"] == "http://example.com/photo.jpg"

@pytest.mark.asyncio
async def test_read_users_me_unauthorized():
    response = client.get("/api/v1/auth/me")
    assert response.status_code == 401

@pytest.mark.asyncio
async def test_password_reset_request_success():
    mock_user = {
        "email": "test@example.com",
        "name": "Test User"
    }
    
    with patch("app.api.v1.endpoints.auth.get_database") as mock_db:
        mock_coll = AsyncMock()
        mock_coll.find_one.return_value = mock_user
        mock_db.return_value.__getitem__.return_value = mock_coll
        
        response = client.post(
            "/api/v1/auth/password-reset-request",
            json={"email": "test@example.com"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "msg" in data
        assert "token" in data

@pytest.mark.asyncio
async def test_password_reset_request_user_not_found():
    with patch("app.api.v1.endpoints.auth.get_database") as mock_db:
        mock_coll = AsyncMock()
        mock_coll.find_one.return_value = None
        mock_db.return_value.__getitem__.return_value = mock_coll
        
        response = client.post(
            "/api/v1/auth/password-reset-request",
            json={"email": "notfound@example.com"}
        )
        
        assert response.status_code == 200

@pytest.mark.asyncio
async def test_password_reset_confirm_success():
    token = security.create_access_token(data={"sub": "test@example.com", "purpose": "reset"}, expires_delta=None)
    mock_user = {
        "email": "test@example.com",
        "password_hash": "old_hash"
    }
    
    with patch("app.api.v1.endpoints.auth.get_database") as mock_db:
        mock_coll = AsyncMock()
        mock_coll.find_one.return_value = mock_user
        mock_coll.update_one = AsyncMock()
        mock_db.return_value.__getitem__.return_value = mock_coll
        
        response = client.post(
            "/api/v1/auth/password-reset-confirm",
            json={"token": token, "new_password": "newpassword123"}
        )
        
        assert response.status_code == 200
        assert response.json()["msg"] == "Password reset successfully"
        assert mock_coll.update_one.called

@pytest.mark.asyncio
async def test_password_reset_confirm_invalid_token():
    response = client.post(
        "/api/v1/auth/password-reset-confirm",
        json={"token": "invalid_token", "new_password": "newpassword123"}
    )
    
    assert response.status_code == 400
    assert "Invalid" in response.json()["detail"]

@pytest.mark.asyncio
async def test_password_reset_confirm_weak_password():
    token = security.create_access_token(data={"sub": "test@example.com", "purpose": "reset"})
    
    response = client.post(
        "/api/v1/auth/password-reset-confirm",
        json={"token": token, "new_password": "123"}
    )
    
    assert response.status_code == 422
