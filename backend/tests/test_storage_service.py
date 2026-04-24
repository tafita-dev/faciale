import pytest
import pathlib
import os
import stat
from unittest.mock import MagicMock, AsyncMock, patch
from cryptography.fernet import Fernet
from app.services.storage import StorageService, StorageServiceError, InvalidImageError, initialize_fernet

@pytest.fixture(autouse=True)
def setup_encryption(monkeypatch):
    """Fixture to set up encryption for tests."""
    encryption_key = Fernet.generate_key().decode()
    mock_settings = MagicMock()
    mock_settings.UPLOAD_DIR = "/tmp/enrollments"
    mock_settings.ENCRYPTION_KEY = encryption_key
    monkeypatch.setattr("app.services.storage.settings", mock_settings)
    initialize_fernet()
    yield encryption_key
    # Reset fernet after tests
    monkeypatch.setattr("app.services.storage.settings.ENCRYPTION_KEY", None)
    initialize_fernet()

@pytest.mark.asyncio
async def test_save_enrollment_photo_creates_dir_with_correct_permissions(tmp_path, setup_encryption):
    upload_dir = tmp_path / "enrollments"
    storage_service = StorageService(upload_dir=str(upload_dir))
    
    file_content = b"fake image content"
    filename = "test.jpg"
    
    mock_file = MagicMock()
    mock_file.read = AsyncMock(return_value=file_content)
    mock_file.filename = filename
    
    saved_path = await storage_service.save_enrollment_photo(mock_file)
    
    # Check if directory exists
    assert upload_dir.exists()
    
    # Check permissions (on Unix)
    if os.name != 'nt':
        mode = os.stat(upload_dir).st_mode
        assert stat.S_IMODE(mode) == 0o700
    
    # Check if file exists
    path = pathlib.Path(saved_path)
    assert path.exists()
    
    # Content should be encrypted, not equal to original
    saved_content = path.read_bytes()
    assert saved_content != file_content
    
    # Decrypt to verify
    f = Fernet(setup_encryption.encode())
    assert f.decrypt(saved_content) == file_content
    
    # Check unique filename (UUID)
    assert path.name != filename
    assert len(path.stem) == 36 # UUID length

@pytest.mark.asyncio
async def test_save_enrollment_photo_handles_read_error(tmp_path):
    storage_service = StorageService(upload_dir=str(tmp_path))
    
    mock_file = MagicMock()
    mock_file.read = AsyncMock(side_effect=IOError("Simulated read error"))
    mock_file.filename = "error.jpg"
    
    with pytest.raises(InvalidImageError, match="Failed to read image file"):
        await storage_service.save_enrollment_photo(mock_file)

@pytest.mark.asyncio
async def test_save_enrollment_photo_handles_empty_file(tmp_path):
    storage_service = StorageService(upload_dir=str(tmp_path))
    
    mock_file = MagicMock()
    mock_file.read = AsyncMock(return_value=b"")
    mock_file.filename = "empty.jpg"
    
    with pytest.raises(InvalidImageError, match="Uploaded file is empty"):
        await storage_service.save_enrollment_photo(mock_file)

@pytest.mark.asyncio
async def test_save_enrollment_photo_handles_write_error(tmp_path, monkeypatch):
    storage_service = StorageService(upload_dir=str(tmp_path))
    
    mock_file = MagicMock()
    mock_file.read = AsyncMock(return_value=b"some content")
    mock_file.filename = "test.jpg"
    
    # Mock aiofiles.open to raise OSError
    with patch("aiofiles.open", side_effect=OSError("Disk full")):
        with pytest.raises(StorageServiceError, match="Failed to save encrypted file"):
            await storage_service.save_enrollment_photo(mock_file)

@pytest.mark.asyncio
async def test_save_enrollment_photo_missing_encryption(monkeypatch):
    # Force fernet to None
    monkeypatch.setattr("app.services.storage.fernet", None)
    
    storage_service = StorageService(upload_dir="/tmp/test")
    
    mock_file = MagicMock()
    mock_file.read = AsyncMock(return_value=b"data")
    mock_file.filename = "test.jpg"
    
    with pytest.raises(StorageServiceError, match="Encryption is not configured"):
        await storage_service.save_enrollment_photo(mock_file)
