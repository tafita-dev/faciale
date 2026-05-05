import pytest
from httpx import AsyncClient
from app.main import app
from app.core import security
from app.db.mongodb import get_database, connect_to_mongo, close_mongo_connection

import pytest_asyncio

@pytest_asyncio.fixture(autouse=True)
async def setup_db():
    await connect_to_mongo()
    yield
    # We could close it here, but it might be shared
    # await close_mongo_connection()

from httpx import AsyncClient, ASGITransport

@pytest.mark.asyncio
async def test_update_fcm_token(setup_db):
    db = get_database()
    email = "test_fcm@example.com"
    # Setup user
    await db["users"].delete_one({"email": email})
    await db["users"].insert_one({
        "email": email,
        "password_hash": security.get_password_hash("password"),
        "role": "admin",
        "org_id": "org123",
        "fcm_tokens": []
    })
    
    # Login to get token
    access_token = security.create_access_token(data={"sub": email, "role": "admin", "org_id": "org123"})
    headers = {"Authorization": f"Bearer {access_token}"}
    
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        response = await ac.post(
            "/api/v1/auth/fcm-token",
            json={"token": "new_fcm_token"},
            headers=headers
        )
        
    assert response.status_code == 200
    assert response.json()["success"] is True
    
    # Verify in DB
    user = await db["users"].find_one({"email": email})
    assert "new_fcm_token" in user["fcm_tokens"]

@pytest.mark.asyncio
async def test_remove_fcm_token(setup_db):
    db = get_database()
    email = "test_remove_fcm@example.com"
    # Setup user
    await db["users"].delete_one({"email": email})
    await db["users"].insert_one({
        "email": email,
        "password_hash": security.get_password_hash("password"),
        "role": "admin",
        "org_id": "org123",
        "fcm_tokens": ["token_to_remove", "other_token"]
    })
    
    # Login to get token
    access_token = security.create_access_token(data={"sub": email, "role": "admin", "org_id": "org123"})
    headers = {"Authorization": f"Bearer {access_token}"}
    
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        response = await ac.request(
            "DELETE",
            "/api/v1/auth/fcm-token",
            json={"token": "token_to_remove"},
            headers=headers
        )
        
    assert response.status_code == 200
    assert response.json()["success"] is True
    
    # Verify in DB
    user = await db["users"].find_one({"email": email})
    assert "token_to_remove" not in user["fcm_tokens"]
    assert "other_token" in user["fcm_tokens"]
