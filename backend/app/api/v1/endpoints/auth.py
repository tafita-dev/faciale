import logging
from datetime import timedelta
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm

from app.core import security
from app.core.config import settings
from app.db.mongodb import get_database
from app.models.token import Token
from app.models.auth import PasswordResetRequest, PasswordResetConfirm
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
        "name": current_user.get("name"),
        "role": current_user.get("role"),
        "org_id": current_user.get("org_id"),
    }


@router.post("/logout")
async def logout(current_user: dict = Depends(deps.get_current_user)) -> Any:
    """
    Log out the current user. 
    In JWT, this is mostly handled client-side by deleting the token.
    Server-side can implement a blacklist if needed.
    """
    return {"success": True, "message": "Successfully logged out"}


# =========================
# PASSWORD RESET REQUEST
# =========================
@router.post("/password-reset-request")
async def password_reset_request(request: PasswordResetRequest) -> Any:
    db = get_database()
    user = await db["users"].find_one({"email": request.email})

    if user:
        # Create a short-lived token (15 minutes)
        token = security.create_access_token(
            data={"sub": user["email"], "purpose": "reset"},
            expires_delta=timedelta(minutes=15)
        )
        # In a real app, send email here.
        # For now, return it in the response as per technical notes.
        logger.info(f"🔑 Password reset token for {request.email}: {token}")
        return {
            "msg": "Password reset email sent if account exists",
            "token": token
        }

    # Return 200 even if user doesn't exist to prevent enumeration
    return {"msg": "Password reset email sent if account exists"}


# =========================
# PASSWORD RESET CONFIRM
# =========================
@router.post("/password-reset-confirm")
async def password_reset_confirm(confirm: PasswordResetConfirm) -> Any:
    try:
        payload = security.decode_token(confirm.token)
        email = payload.get("sub")
        purpose = payload.get("purpose")

        if not email or purpose != "reset":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid token"
            )

        db = get_database()
        user = await db["users"].find_one({"email": email})

        if not user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid token"
            )

        hashed_password = security.get_password_hash(confirm.new_password)
        await db["users"].update_one(
            {"email": email},
            {"$set": {"password_hash": hashed_password}}
        )

        return {"msg": "Password reset successfully"}

    except Exception as e:
        logger.error(f"❌ Password reset confirm failed: {e}")
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired token"
        )
