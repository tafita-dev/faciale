import uuid
import pathlib
import aiofiles
import os
from typing import Any
from fastapi import UploadFile, HTTPException
from app.services.recognition import RecognitionService
from app.repositories.vector_db import VectorRepository
from app.db.mongodb import get_database
from app.core.config import settings
import numpy as np

from app.services.storage import StorageService

async def start_enrollment_pipeline(employee_id: str, file: UploadFile) -> None:
    """
    Start the facial enrollment pipeline:
    1. Extract facial embeddings.
    2. Store vectors in Qdrant.
    3. Persist the reference image.
    4. Update employee status.
    """
    recognition_service = RecognitionService()
    vector_repo = VectorRepository()
    storage_service = StorageService()
    db = get_database()
    
    # Get employee to know their org_id
    employee = await db["employees"].find_one({"_id": employee_id})
    if not employee:
        return

    org_id = employee.get("org_id")
    
    # Read file content for recognition (we need bytes)
    await file.seek(0)
    contents = await file.read()
    await file.seek(0) # Reset for storage service if needed, though StorageService will also read it
    
    # Decode image
    img = recognition_service.decode_image_from_bytes(contents)
    
    # 1. Extract facial embeddings
    embedding = recognition_service.extract_embedding(img)
    
    # 2. Store vectors in Qdrant
    await vector_repo.upsert_embedding(employee_id, org_id, embedding)
    
    # 3. Persist the reference image securely
    file_path = await storage_service.save_enrollment_photo(file)
    
    # 4. Update employee status
    await db["employees"].update_one(
        {"_id": employee_id},
        {"$set": {
            "is_enrolled": True,
            "image_path": file_path
        }}
    )

