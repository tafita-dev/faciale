import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.db.mongodb import get_database
from app.core import security
import asyncio

@pytest.fixture
def client():
    with TestClient(app) as c:
        yield c

@pytest.mark.asyncio
async def test_org_creation_should_create_admin(client):
    # 1. Login as superadmin
    response = client.post(
        "/api/v1/auth/login",
        data={"username": "superadmin@precity.com", "password": "admin123"}
    )
    assert response.status_code == 200
    token = response.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 2. Create organization
    org_data = {
        "name": "Buggy Org",
        "type": "company"
    }
    response = client.post("/api/v1/orgs/", json=org_data, headers=headers)
    assert response.status_code == 201
    created_org = response.json()
    org_id = created_org["_id"]

    # 3. Check if admin user was created in DB
    db = get_database()
    admin_user = await db["users"].find_one({"org_id": org_id, "role": "admin"})
    
    # THIS IS EXPECTED TO FAIL CURRENTLY (admin_user will be None)
    assert admin_user is not None, "Admin user should be created when organization is created"
    assert admin_user["role"] == "admin"
