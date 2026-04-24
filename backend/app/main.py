from contextlib import asynccontextmanager
from fastapi import FastAPI
import os
import logging

from app.core.config import settings
from app.core import security   # ✅ maintenant basé sur ARGON2
from app.db.mongodb import (
    connect_to_mongo,
    close_mongo_connection,
    get_database,
)
from app.db.qdrant import connect_to_qdrant, close_qdrant_connection
from app.api.v1.api import api_router
from app.repositories.attendance import AttendanceRepository

# =========================
# LOGGER SETUP
# =========================
logger = logging.getLogger("app")
logging.basicConfig(level=logging.INFO)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # =========================
    # STARTUP
    # =========================
    await connect_to_mongo()
    await connect_to_qdrant()

    attendance_repo = AttendanceRepository()
    await attendance_repo.init_indexes()

    # =========================
    # SEED SUPERADMIN
    # =========================
    db = get_database()

    superadmin_email = os.getenv("SUPERADMIN_EMAIL", "superadmin@precity.com")
    superadmin_password = os.getenv("SUPERADMIN_PASSWORD", "admin123").strip()

    # ❌ bcrypt limit supprimé (PLUS BESOIN avec argon2)

    existing = await db["users"].find_one({"role": "superadmin"})

    if not existing:
        # 🔐 ARGON2 HASH
        password_hash = security.get_password_hash(superadmin_password)

        await db["users"].insert_one({
            "email": superadmin_email.lower().strip(),
            "password_hash": password_hash,
            "role": "superadmin",
            "org_id": None
        })

        logger.info("✅ Superadmin created successfully")
        logger.info(f"📧 Email: {superadmin_email}")
    else:
        logger.info("ℹ️ Superadmin already exists")

    yield

    # =========================
    # SHUTDOWN
    # =========================
    await close_mongo_connection()
    await close_qdrant_connection()


# =========================
# FASTAPI APP
# =========================
app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    lifespan=lifespan
)

app.include_router(api_router, prefix=settings.API_V1_STR)


# =========================
# HEALTH CHECK
# =========================
@app.get("/health", tags=["health"])
async def health_check():
    return {
        "status": "healthy",
        "version": settings.API_VERSION
    }


# =========================
# ENTRYPOINT
# =========================
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)