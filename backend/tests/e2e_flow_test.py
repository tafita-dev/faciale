import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.db.mongodb import get_database, db_obj
from app.db.qdrant import qdrant_obj
from app.api.deps import (
    get_org_repository, 
    get_department_repository, 
    get_employee_repository, 
    get_attendance_repository,
    get_reporting_service
)
from app.services.recognition import RecognitionService
from app.services.liveness import LivenessService
from app.models.org import Org
from app.models.department import Department
from app.models.employee import Employee
from unittest.mock import MagicMock, AsyncMock, patch
import numpy as np
from datetime import datetime, timezone
import json

client = TestClient(app)

@pytest.fixture
def mock_db():
    mock_db_instance = MagicMock()
    collections = {}

    def get_collection(name):
        if name not in collections:
            coll = MagicMock()
            coll.find_one = AsyncMock()
            coll.insert_one = AsyncMock()
            coll.update_one = AsyncMock()
            coll.find = MagicMock()
            collections[name] = coll
        return collections[name]

    mock_db_instance.__getitem__.side_effect = get_collection
    
    db_obj.db = mock_db_instance
    app.dependency_overrides[get_database] = lambda: mock_db_instance
    yield mock_db_instance
    app.dependency_overrides.pop(get_database, None)

@pytest.fixture
def mock_repos():
    org_repo = MagicMock()
    dept_repo = MagicMock()
    emp_repo = MagicMock()
    att_repo = MagicMock()
    report_service = MagicMock()

    app.dependency_overrides[get_org_repository] = lambda: org_repo
    app.dependency_overrides[get_department_repository] = lambda: dept_repo
    app.dependency_overrides[get_employee_repository] = lambda: emp_repo
    app.dependency_overrides[get_attendance_repository] = lambda: att_repo
    app.dependency_overrides[get_reporting_service] = lambda: report_service

    yield {
        "org": org_repo,
        "dept": dept_repo,
        "emp": emp_repo,
        "att": att_repo,
        "report": report_service
    }

    app.dependency_overrides.pop(get_org_repository, None)
    app.dependency_overrides.pop(get_department_repository, None)
    app.dependency_overrides.pop(get_employee_repository, None)
    app.dependency_overrides.pop(get_attendance_repository, None)
    app.dependency_overrides.pop(get_reporting_service, None)

@pytest.fixture
def mock_qdrant():
    mock_client = MagicMock()
    mock_client.upsert = AsyncMock()
    mock_client.search = AsyncMock()
    qdrant_obj.client = mock_client
    yield mock_client

@pytest.fixture
def mock_recognition():
    mock = MagicMock(spec=RecognitionService)
    mock.extract_embedding.return_value = np.zeros(512)
    mock.decode_image_from_bytes.return_value = np.zeros((100, 100, 3), dtype=np.uint8)
    
    RecognitionService._instance = mock
    with patch("app.services.enrollment.RecognitionService", return_value=mock), \
         patch("app.services.attendance.RecognitionService", return_value=mock):
        yield mock

@pytest.mark.asyncio
async def test_e2e_onboarding_and_attendance_flow(mock_db, mock_repos, mock_qdrant, mock_recognition):
    # Setup DB mocks for login
    from app.core.security import get_password_hash
    mock_db["users"].find_one.return_value = {
        "email": "superadmin@precity.com",
        "password_hash": get_password_hash("admin123"),
        "role": "superadmin",
        "org_id": None
    }

    # 1. Login as Super Admin
    response = client.post(
        "/api/v1/auth/login",
        data={"username": "superadmin@precity.com", "password": "admin123"}
    )
    assert response.status_code == 200
    token = response.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 2. Create Organization
    org_id = "org123"
    mock_db["organizations"].find_one.return_value = None
    mock_db["organizations"].insert_one.return_value = MagicMock(inserted_id=org_id)
    
    response = client.post(
        "/api/v1/orgs/",
        headers=headers,
        json={"name": "E2E Test School", "type": "school"}
    )
    assert response.status_code == 201

    # 3. Simulate Org Admin Login
    from app.core.security import create_access_token
    org_admin_token = create_access_token(data={"sub": "orgadmin@test.com", "role": "org_admin", "org_id": org_id})
    org_headers = {"Authorization": f"Bearer {org_admin_token}"}
    
    mock_db["users"].find_one.return_value = {
        "email": "orgadmin@test.com",
        "role": "org_admin",
        "org_id": org_id
    }

    # 4. Create Department
    dept_id = "dept123"
    mock_db["departments"].find_one.return_value = None
    mock_db["departments"].insert_one.return_value = MagicMock(inserted_id=dept_id)
    
    response = client.post(
        "/api/v1/departments/",
        headers=org_headers,
        json={"name": "Grade 10"}
    )
    assert response.status_code == 201

    # 5. Create Employee
    employee_id = "emp123"
    mock_db["departments"].find_one.return_value = {"_id": dept_id, "name": "Grade 10", "org_id": org_id}
    mock_db["employees"].insert_one.return_value = MagicMock(inserted_id=employee_id)
    
    response = client.post(
        "/api/v1/employees/",
        headers=org_headers,
        json={"name": "Alice", "dept_id": dept_id}
    )
    assert response.status_code == 201
    
    # 6. Enroll Employee
    mock_db["employees"].find_one.return_value = {
        "_id": employee_id,
        "name": "Alice",
        "dept_id": dept_id,
        "org_id": org_id
    }
    
    with patch("app.services.enrollment.StorageService") as MockStorage:
        MockStorage.return_value.save_enrollment_photo = AsyncMock(return_value="path/to/photo.jpg")
        
        response = client.post(
            f"/api/v1/employees/{employee_id}/enroll",
            headers=org_headers,
            files={"file": ("test.jpg", b"fake-image-content", "image/jpeg")}
        )
        assert response.status_code == 202

    # 7. Attendance Check-in
    # Mock repositories return values
    mock_repos["att"].get_last_success_log = AsyncMock(return_value=None)
    mock_repos["att"].log_attendance = AsyncMock()
    mock_repos["emp"].get_employee = AsyncMock(return_value=Employee(
        _id=employee_id, name="Alice", dept_id=dept_id, org_id=org_id, is_active=True, is_enrolled=True, created_at=datetime.now(timezone.utc)
    ))

    with patch("app.services.attendance.AttendanceService.process_attendance") as MockProc:
        MockProc.return_value = {"status": "success", "employee_id": employee_id, "score": 0.95}
        
        response = client.post(
            "/api/v1/attendance/check-in",
            headers=org_headers,
            files={"file": ("scan.jpg", b"fake-scan-content", "image/jpeg")}
        )
        assert response.status_code == 200
        assert response.json()["success"] is True
        assert response.json()["data"]["employee_name"] == "Alice"

    # 8. Verify Stats
    mock_repos["report"].get_today_stats = AsyncMock(return_value={"present": 1, "late": 0, "absent": 0, "total": 1})
    
    response = client.get(
        "/api/v1/reports/stats",
        headers=org_headers
    )
    assert response.status_code == 200
    assert response.json()["data"]["present"] == 1

    # 9. Verify Logs
    mock_repos["report"].get_logs = AsyncMock(return_value={
        "items": [{
            "employee_id": employee_id,
            "employee_name": "Alice",
            "status": "success",
            "timestamp": datetime.now(timezone.utc).isoformat()
        }],
        "total": 1,
        "page": 1,
        "size": 10
    })
    
    response = client.get(
        "/api/v1/reports/logs",
        headers=org_headers
    )
    assert response.status_code == 200
    logs_data = response.json()["data"]
    assert any(log["employee_name"] == "Alice" for log in logs_data["items"])
