from app.core.security import verify_password, get_password_hash, create_access_token, decode_token
from app.core.config import settings

def test_password_hashing():
    password = "secretpassword"
    hashed = get_password_hash(password)
    assert hashed != password
    assert verify_password(password, hashed) is True
    assert verify_password("wrongpassword", hashed) is False

def test_jwt_token():
    data = {"sub": "testuser", "role": "admin"}
    token = create_access_token(data)
    assert isinstance(token, str)
    
    decoded = decode_token(token)
    assert decoded["sub"] == "testuser"
    assert decoded["role"] == "admin"
    assert "exp" in decoded
