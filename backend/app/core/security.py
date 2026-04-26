from datetime import datetime, timedelta, timezone
from typing import Any, Union
import json
import base64
from jose import jwt
from passlib.context import CryptContext
from cryptography.fernet import Fernet
from app.core.config import settings

# =========================
# 🔐 ARGON2 (NEW)
# =========================
pwd_context = CryptContext(
    schemes=["argon2"],
    deprecated="auto"
)

# =========================
# 🔒 FERNET ENCRYPTION
# =========================
_fernet: Fernet | None = None

def get_fernet() -> Fernet:
    global _fernet
    if _fernet is None:
        if not settings.ENCRYPTION_KEY:
            raise ValueError("ENCRYPTION_KEY is not set in settings")
        _fernet = Fernet(settings.ENCRYPTION_KEY.encode())
    return _fernet

def encrypt_data(data: Union[str, bytes, list, dict]) -> str:
    """
    Encrypts data using Fernet. 
    If data is not bytes, it is converted to JSON string and then bytes.
    Returns a base64 encoded string of the encrypted data.
    """
    f = get_fernet()
    if isinstance(data, (list, dict)):
        data_bytes = json.dumps(data).encode()
    elif isinstance(data, str):
        data_bytes = data.encode()
    else:
        data_bytes = data
    
    encrypted = f.encrypt(data_bytes)
    return encrypted.decode()

def decrypt_data(token: str, as_json: bool = False) -> Any:
    """
    Decrypts a Fernet token.
    Returns the decrypted data. If as_json is True, it parses the result as JSON.
    """
    f = get_fernet()
    decrypted_bytes = f.decrypt(token.encode())
    
    if as_json:
        return json.loads(decrypted_bytes.decode())
    
    try:
        return decrypted_bytes.decode()
    except UnicodeDecodeError:
        return decrypted_bytes

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