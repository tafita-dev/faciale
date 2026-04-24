import logging
from datetime import timedelta
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm

from app.core import security
from app.core.config import settings
from app.db.mongodb import get_database
from app.models.token import Token
from app.api import deps

router = APIRouter()

# =========================
# LOGGER CONFIG
# =========================
logger = logging.getLogger("auth")
logging.basicConfig(level=logging.INFO)


# =========================
# LOGIN
# =========================
@router.post("/login", response_model=Token)
async def login(form_data: OAuth2PasswordRequestForm = Depends()) -> Any:
    db = get_database()

    logger.info("=================================")
    logger.info(f"🔍 Login attempt: {form_data.username}")

    # =========================
    # GET USER FROM DB
    # =========================
    user = await db["users"].find_one({"email": form_data.username})

    logger.info(f"👤 User from DB: {user}")

    # =========================
    # DEBUG PASSWORD HASH
    # =========================
    if user:
        logger.info(f"🔐 Stored password hash: {user.get('password_hash')}")
        logger.info(f"🔑 Input password: {form_data.password}")

    # =========================
    # VERIFY USER
    # =========================
    if not user:
        logger.warning("❌ User not found")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # =========================
    # VERIFY PASSWORD
    # =========================
    is_valid = security.verify_password(
        form_data.password,
        user["password_hash"]
    )

    logger.info(f"🔎 Password valid: {is_valid}")

    if not is_valid:
        logger.warning("❌ Wrong password")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    logger.info("✅ Login success")

    # =========================
    # CREATE TOKEN
    # =========================
    access_token_expires = timedelta(
        minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES
    )

    access_token = security.create_access_token(
        data={
            "sub": user["email"],
            "role": user.get("role"),
            "org_id": user.get("org_id"),
        },
        expires_delta=access_token_expires
    )

    return {
        "access_token": access_token,
        "token_type": "bearer",
    }


# =========================
# GET CURRENT USER
# =========================
@router.get("/me")
async def read_users_me(
    current_user: dict = Depends(deps.get_current_user)
) -> Any:
    return {
        "email": current_user["email"],
        "role": current_user.get("role"),
        "org_id": current_user.get("org_id"),
    }