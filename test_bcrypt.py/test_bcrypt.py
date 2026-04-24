from passlib.context import CryptContext
import logging

logging.basicConfig(level=logging.INFO)

pwd_context = CryptContext(
    schemes=["argon2"],
    deprecated="auto"
)

# =========================
# HASH
# =========================
password = "admin123"
hashed = pwd_context.hash(password)

logging.info(f"🔐 HASH: {hashed}")

# =========================
# VERIFY
# =========================
is_valid = pwd_context.verify(password, hashed)

logging.info(f"✅ PASSWORD VALID: {is_valid}")