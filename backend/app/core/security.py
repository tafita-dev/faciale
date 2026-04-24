from datetime import datetime, timedelta, timezone
from typing import Any, Union
from jose import jwt
from passlib.context import CryptContext
from app.core.config import settings

# =========================
# 🔐 ARGON2 (NEW)
# =========================
pwd_context = CryptContext(
    schemes=["argon2"],
    deprecated="auto"
)

# =========================
# VERIFY PASSWORD
# =========================
def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

# =========================
# HASH PASSWORD
# =========================
def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)

# =========================
# CREATE TOKEN
# =========================
def create_access_token(
    data: dict,
    expires_delta: Union[timedelta, None] = None
) -> str:
    to_encode = data.copy()

    expire = datetime.now(timezone.utc) + (
        expires_delta
        if expires_delta
        else timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    )

    to_encode.update({"exp": expire})

    return jwt.encode(
        to_encode,
        settings.SECRET_KEY,
        algorithm=settings.ALGORITHM
    )

# =========================
# DECODE TOKEN
# =========================
def decode_token(token: str) -> dict[str, Any]:
    return jwt.decode(
        token,
        settings.SECRET_KEY,
        algorithms=[settings.ALGORITHM]
    )