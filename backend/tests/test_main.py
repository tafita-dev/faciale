from unittest.mock import patch, AsyncMock
from fastapi.testclient import TestClient
from app.main import app
from app.core.config import settings

client = TestClient(app)

def test_health_check():
    with patch("app.main.connect_to_mongo", new_callable=AsyncMock), \
         patch("app.main.connect_to_qdrant", new_callable=AsyncMock), \
         patch("app.main.close_mongo_connection", new_callable=AsyncMock), \
         patch("app.main.close_qdrant_connection", new_callable=AsyncMock), \
         patch("app.main.AttendanceRepository") as MockRepo:
        
        MockRepo.return_value.init_indexes = AsyncMock()
        
        with TestClient(app) as client:
            response = client.get("/health")
            assert response.status_code == 200
            assert response.json()["status"] == "healthy"
            assert response.json()["version"] == settings.API_VERSION

def test_settings_load():
    # Since we added a .env file, these should match the .env content
    assert settings.PROJECT_NAME == "Faciale-Dev"
    assert settings.API_V1_STR == "/api/v1"
