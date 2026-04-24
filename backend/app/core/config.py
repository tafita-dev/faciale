from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    PROJECT_NAME: str = "Faciale"
    API_V1_STR: str = "/api/v1"
    API_VERSION: str = "1.0.0"

    # MongoDB
    MONGODB_URL: str = "mongodb://mongodb:27017"
    MONGODB_DB_NAME: str = "faciale_db"

    # Qdrant
    QDRANT_URL: str = "http://localhost:6333"
    QDRANT_API_KEY: str | None = None

    # Security
    SECRET_KEY: str = "70d63f0449d0689b6920f6667954950946b5a19003c20c025531952a265696d5"  # Generated for dev
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days
    ENCRYPTION_KEY: str | None = None

    # Recognition
    RECOGNITION_THRESHOLD: float = 0.85

    # Storage
    MAX_CONTENT_LENGTH: int = 5 * 1024 * 1024  # 5MB
    UPLOAD_DIR: str = "uploads"

    # SuperAdmin
    SUPERADMIN_PASSWORD: str = "admin"

    model_config = SettingsConfigDict(
        case_sensitive=True,
        env_file=".env"
    )

settings = Settings()
