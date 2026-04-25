import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app
from app.core import security
from app.db.mongodb import get_database
import uuid

async def get_db():
    from app.db.mongodb import connect_to_mongo, get_database
    await connect_to_mongo()
    return get_database()

@pytest.mark.asyncio
async def test_superadmin_permissions():
    db = await get_db()
    email = f"super{uuid.uuid4()}@test.com"
    user_id = str(uuid.uuid4())
    await db["users"].insert_one({"_id": user_id, "email": email, "role": "superadmin"})
    token = security.create_access_token({"sub": email, "role": "superadmin"})
    
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        # Should be able to list orgs
        resp = await ac.get("/api/v1/orgs/", headers={"Authorization": f"Bearer {token}"})
        assert resp.status_code != 403
        
        # Should NOT be able to access employees
        resp = await ac.get("/api/v1/employees/", headers={"Authorization": f"Bearer {token}"})
        assert resp.status_code == 403
        
        # Should NOT be able to access attendance logs
        resp = await ac.get("/api/v1/reports/logs", headers={"Authorization": f"Bearer {token}"})
        assert resp.status_code == 403

@pytest.mark.asyncio
async def test_user_isolation():
    db = await get_db()
    org_id = str(uuid.uuid4())
    user1_id = str(uuid.uuid4())
    user2_id = str(uuid.uuid4())
    user1_email = f"user1{uuid.uuid4()}@test.com"
    user2_email = f"user2{uuid.uuid4()}@test.com"
    
    await db["users"].insert_many([
        {"_id": user1_id, "email": user1_email, "role": "user", "org_id": org_id},
        {"_id": user2_id, "email": user2_email, "role": "user", "org_id": org_id}
    ])
    
    token1 = security.create_access_token({"sub": user1_email, "role": "user", "org_id": org_id})
    token2 = security.create_access_token({"sub": user2_email, "role": "user", "org_id": org_id})

    # Create employee for user1
    emp1_id = str(uuid.uuid4())
    await db["employees"].insert_one({
        "_id": emp1_id,
        "name": "Employee 1",
        "org_id": org_id,
        "dept_id": "dept1",
        "created_by": user1_id
    })

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        # User 1 sees their employee
        resp = await ac.get("/api/v1/employees/", headers={"Authorization": f"Bearer {token1}"})
        assert resp.status_code == 200
        data = resp.json()
        assert any(e["_id"] == emp1_id for e in data)
        
        # User 2 should NOT see user 1's employee
        resp = await ac.get("/api/v1/employees/", headers={"Authorization": f"Bearer {token2}"})
        assert resp.status_code == 200
        data = resp.json()
        assert all(e["_id"] != emp1_id for e in data), "User 2 should not see User 1's employee"

@pytest.mark.asyncio
async def test_admin_sees_all_in_org():
    db = await get_db()
    org_id = str(uuid.uuid4())
    admin_email = f"admin{uuid.uuid4()}@test.com"
    admin_id = str(uuid.uuid4())
    user1_id = str(uuid.uuid4())
    
    await db["users"].insert_one({"_id": admin_id, "email": admin_email, "role": "admin", "org_id": org_id})
    token = security.create_access_token({"sub": admin_email, "role": "admin", "org_id": org_id})
    
    # Create employee in org
    emp_id = str(uuid.uuid4())
    await db["employees"].insert_one({
        "_id": emp_id,
        "name": "Employee Admin",
        "org_id": org_id,
        "dept_id": "dept1",
        "created_by": user1_id
    })

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        resp = await ac.get("/api/v1/employees/", headers={"Authorization": f"Bearer {token}"})
        assert resp.status_code == 200
        data = resp.json()
        assert any(e["_id"] == emp_id for e in data)

@pytest.mark.asyncio
async def test_attendance_log_isolation():
    db = await get_db()
    org_id = str(uuid.uuid4())
    user1_id = str(uuid.uuid4())
    user2_id = str(uuid.uuid4())
    user1_email = f"user1{uuid.uuid4()}@test.com"
    user2_email = f"user2{uuid.uuid4()}@test.com"
    
    await db["users"].insert_many([
        {"_id": user1_id, "email": user1_email, "role": "user", "org_id": org_id},
        {"_id": user2_id, "email": user2_email, "role": "user", "org_id": org_id}
    ])
    
    token1 = security.create_access_token({"sub": user1_email, "role": "user", "org_id": org_id})
    token2 = security.create_access_token({"sub": user2_email, "role": "user", "org_id": org_id})

    # Create log for user1
    log1_id = str(uuid.uuid4())
    emp1_id = str(uuid.uuid4())
    from datetime import datetime, timezone
    await db["attendance_logs"].insert_one({
        "_id": log1_id,
        "org_id": org_id,
        "user_id": user1_id,
        "employee_id": emp1_id,
        "status": "success",
        "timestamp": datetime.now(timezone.utc),
        "confidence_score": 0.9 # needed for repository projection
    })

    # Create an employee for emp1_id so the lookup works
    await db["employees"].insert_one({
        "_id": emp1_id,
        "name": "Employee 1",
        "org_id": org_id,
        "dept_id": "dept1"
    })

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        # User 1 sees their log
        resp = await ac.get("/api/v1/reports/logs", headers={"Authorization": f"Bearer {token1}"})
        assert resp.status_code == 200
        data = resp.json()["data"]["items"]
        assert any(l["id"] == log1_id for l in data)
        
        # User 2 should NOT see user 1's log
        resp = await ac.get("/api/v1/reports/logs", headers={"Authorization": f"Bearer {token2}"})
        assert resp.status_code == 200
        data = resp.json()["data"]["items"]
        assert all(l["id"] != log1_id for l in data), "User 2 should not see User 1's log"

@pytest.mark.asyncio
async def test_admin_filter_by_user():
    db = await get_db()
    org_id = str(uuid.uuid4())
    admin_id = str(uuid.uuid4())
    admin_email = f"admin{uuid.uuid4()}@test.com"
    user1_id = str(uuid.uuid4())
    user2_id = str(uuid.uuid4())
    
    await db["users"].insert_many([
        {"_id": admin_id, "email": admin_email, "role": "admin", "org_id": org_id},
        {"_id": user1_id, "email": "u1@t.com", "role": "user", "org_id": org_id},
        {"_id": user2_id, "email": "u2@t.com", "role": "user", "org_id": org_id}
    ])
    
    token = security.create_access_token({"sub": admin_email, "role": "admin", "org_id": org_id})
    
    # Create logs
    log1_id = str(uuid.uuid4())
    log2_id = str(uuid.uuid4())
    emp1_id = str(uuid.uuid4())
    emp2_id = str(uuid.uuid4())
    
    from datetime import datetime, timezone
    await db["attendance_logs"].insert_many([
        {"_id": log1_id, "org_id": org_id, "user_id": user1_id, "employee_id": emp1_id, "status": "success", "timestamp": datetime.now(timezone.utc), "confidence_score": 0.9},
        {"_id": log2_id, "org_id": org_id, "user_id": user2_id, "employee_id": emp2_id, "status": "success", "timestamp": datetime.now(timezone.utc), "confidence_score": 0.9}
    ])
    
    await db["employees"].insert_many([
        {"_id": emp1_id, "name": "E1", "org_id": org_id, "dept_id": "d1"},
        {"_id": emp2_id, "name": "E2", "org_id": org_id, "dept_id": "d1"}
    ])

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        # Admin sees all
        resp = await ac.get("/api/v1/reports/logs", headers={"Authorization": f"Bearer {token}"})
        data = resp.json()["data"]["items"]
        assert any(l["id"] == log1_id for l in data)
        assert any(l["id"] == log2_id for l in data)
        
        # Admin filters by user1
        resp = await ac.get(f"/api/v1/reports/logs?user_id={user1_id}", headers={"Authorization": f"Bearer {token}"})
        data = resp.json()["data"]["items"]
        assert any(l["id"] == log1_id for l in data)
        assert all(l["id"] != log2_id for l in data)
