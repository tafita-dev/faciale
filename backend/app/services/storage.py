import uuid
import pathlib
import aiofiles
import os
from fastapi import UploadFile
from app.core.security import encrypt_data
from app.core.config import settings

# Define custom exceptions
class InvalidImageError(Exception):
    """Custom exception for invalid image files."""
    pass

class StorageServiceError(Exception):
    """Custom exception for storage-related errors."""
    pass


class StorageService:
    def __init__(self, upload_dir: str = None):
        self.upload_dir = pathlib.Path(upload_dir or settings.UPLOAD_DIR)

    async def save_enrollment_photo(self, file: UploadFile) -> str:
        """
        Saves an enrollment photo securely, encrypting it and storing with restricted permissions.
        Returns the absolute path to the saved file.
        """
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
            encrypted_contents = encrypt_data(contents).encode()

            async with aiofiles.open(file_path, mode='wb') as f:
                await f.write(encrypted_contents)
        except Exception as e: 
            raise StorageServiceError(f"An unexpected error occurred while saving the file: {e}") from e

        return str(file_path.absolute())

    async def save_logo(self, file: UploadFile) -> str:
        """
        Saves an organization logo.
        Returns the filename of the saved file.
        """
        if not self.upload_dir.exists():
            try:
                self.upload_dir.mkdir(parents=True, mode=0o755)
            except OSError as e:
                raise StorageServiceError(f"Failed to create directory {self.upload_dir}: {e}") from e

        # Generate unique filename
        file_extension = pathlib.Path(file.filename).suffix or ".jpg"
        unique_filename = f"logo_{uuid.uuid4()}{file_extension}"
        file_path = self.upload_dir / unique_filename

        try:
            contents = await file.read()
            if not contents:
                raise InvalidImageError("Uploaded file is empty.")
            
            async with aiofiles.open(file_path, mode='wb') as f:
                await f.write(contents)
        except Exception as e:
            raise StorageServiceError(f"An unexpected error occurred while saving the logo: {e}") from e

        return unique_filename

    async def get_enrollment_photo(self, file_path: str) -> bytes:
        """
        Retrieves and decrypts an enrollment photo.
        """
        path = pathlib.Path(file_path)
        if not path.exists():
            raise StorageServiceError(f"File not found: {file_path}")

        try:
            async with aiofiles.open(path, mode='rb') as f:
                encrypted_contents = await f.read()
            
            from app.core.security import decrypt_data
            decrypted = decrypt_data(encrypted_contents.decode())
            if isinstance(decrypted, str):
                return decrypted.encode()
            return decrypted
        except Exception as e:
            raise StorageServiceError(f"Failed to decrypt file {file_path}: {e}") from e

