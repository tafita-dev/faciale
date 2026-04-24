import uuid
import pathlib
import aiofiles
import os
from fastapi import UploadFile
from app.core.config import settings
from cryptography.fernet import Fernet, InvalidToken

# Define custom exceptions
class InvalidImageError(Exception):
    """Custom exception for invalid image files."""
    pass

class StorageServiceError(Exception):
    """Custom exception for storage-related errors."""
    pass

# --- Encryption Setup ---
# Global variable for Fernet instance. It will be initialized based on settings.
fernet = None

def initialize_fernet():
    """Initializes the Fernet instance based on settings."""
    global fernet
    fernet = None # Reset fernet
    if hasattr(settings, 'ENCRYPTION_KEY') and settings.ENCRYPTION_KEY:
        try:
            key = settings.ENCRYPTION_KEY.encode()
            fernet = Fernet(key)
        except (ValueError, TypeError) as e:
            # Log this in production. For now, print a warning.
            print(f"Warning: Could not initialize Fernet encryption due to invalid key. Reason: {e}")
            fernet = None # Ensure fernet remains None if key is invalid
    # If ENCRYPTION_KEY is not present or empty, fernet remains None.

# Initialize Fernet when the module loads
initialize_fernet()

def encrypt_data(data: bytes) -> bytes:
    """Encrypts data using Fernet. Raises StorageServiceError if Fernet is not initialized."""
    if not fernet:
        raise StorageServiceError("Encryption is not configured. Cannot encrypt data.")
    try:
        return fernet.encrypt(data)
    except Exception as e:
        raise StorageServiceError(f"Failed to encrypt data: {e}") from e

# Decryption function (for potential future use, not directly in save_enrollment_photo)
# def decrypt_data(data: bytes) -> bytes:
#     """Decrypts data using Fernet. Raises StorageServiceError if Fernet is not initialized or token is invalid."""
#     if not fernet:
#         raise StorageServiceError("Encryption is not configured. Cannot decrypt data.")
#     try:
#         return fernet.decrypt(data)
#     except InvalidToken:
#         raise StorageServiceError("Failed to decrypt data: Invalid token.")
#     except Exception as e:
#         raise StorageServiceError(f"Failed to decrypt data: {e}") from e


class StorageService:
    def __init__(self, upload_dir: str = None):
        self.upload_dir = pathlib.Path(upload_dir or settings.UPLOAD_DIR)

    async def save_enrollment_photo(self, file: UploadFile) -> str:
        """
        Saves an enrollment photo securely, encrypting it and storing with restricted permissions.
        Returns the absolute path to the saved file.
        """
        # Check if Fernet is initialized. If not, raise error immediately as encryption is mandatory.
        if not fernet:
            raise StorageServiceError("Encryption is not configured. Cannot save file securely.")

        # Ensure directory exists with restricted permissions (0o700)
        if not self.upload_dir.exists():
            try:
                self.upload_dir.mkdir(parents=True, mode=0o700)
            except OSError as e:
                raise StorageServiceError(f"Failed to create directory {self.upload_dir}: {e}") from e
        else:
            # Ensure permissions are correct even if directory exists
            if os.name != 'nt': # Skip on Windows as permissions differ
                try:
                    os.chmod(self.upload_dir, 0o700)
                except OSError as e:
                    raise StorageServiceError(f"Failed to set permissions on existing directory {self.upload_dir}: {e}") from e

        # Generate unique filename
        file_extension = pathlib.Path(file.filename).suffix or ".jpg"
        unique_filename = f"{uuid.uuid4()}{file_extension}"
        file_path = self.upload_dir / unique_filename

        # --- Read File ---
        contents = None
        try:
            contents = await file.read()
            if not contents: # Check for empty file content
                raise InvalidImageError("Uploaded file is empty.")
        except Exception as e:
            # Catch potential errors during file reading (e.g., corrupted upload, network issues)
            raise InvalidImageError(f"Failed to read image file: {e}") from e

        # --- Encrypt and Save File ---
        try:
            # Encrypt the content before writing
            encrypted_contents = encrypt_data(contents)

            async with aiofiles.open(file_path, mode='wb') as f:
                await f.write(encrypted_contents)
        except StorageServiceError as e: # Catch specific encryption or other storage errors
            # If encryption fails, or writing fails, it's a StorageServiceError
            raise e
        except OSError as e: # Catch file system errors during open/write
            raise StorageServiceError(f"Failed to save encrypted file: {e}. Disk full or permissions issue?") from e
        except Exception as e: # Catch any other unexpected errors during write
            raise StorageServiceError(f"An unexpected error occurred while saving the file: {e}") from e

        return str(file_path.absolute())
