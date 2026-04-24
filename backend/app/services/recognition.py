import cv2
import numpy as np
import insightface
from insightface.app import FaceAnalysis
import os
from app.services.liveness import LivenessService
from app.repositories.vector_db import VectorRepository
from app.repositories.org import OrgRepository
from app.core.config import settings

class RecognitionService:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(RecognitionService, cls).__new__(cls)
            # We initialize FaceAnalysis. ctx_id=0 for GPU, -1 for CPU.
            # For simplicity and testability in local env, we use CPU (-1).
            cls._instance.app = FaceAnalysis(name='buffalo_l', providers=['CPUExecutionProvider'])
            cls._instance.app.prepare(ctx_id=-1, det_size=(640, 640))
            cls._instance.liveness_service = LivenessService()
            cls._instance.vector_repo = VectorRepository()
            cls._instance.org_repo = OrgRepository()
        return cls._instance

    def extract_embedding(self, img: np.ndarray) -> np.ndarray:
        """
        Extract 512d facial embedding from an image.
        Expects img to be a BGR image (OpenCV format).
        """
        faces = self.app.get(img)
        
        if len(faces) == 0:
            raise ValueError("No face detected in the image")
        if len(faces) > 1:
            raise ValueError("Multiple faces detected. Please upload a photo with only one person")
            
        return faces[0].embedding

    def decode_image_from_bytes(self, img_bytes: bytes) -> np.ndarray:
        """
        Convert raw bytes to an OpenCV image (BGR).
        """
        nparr = np.frombuffer(img_bytes, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        if img is None:
            raise ValueError("Failed to decode image from bytes")
        return img

    async def verify_liveness(self, img_bytes: bytes) -> dict:
        """
        Verify if the face in the image is a live person.
        Returns:
            dict: {"is_live": bool, "score": float}
        """
        img = self.decode_image_from_bytes(img_bytes)
        faces = self.app.get(img)
        
        if len(faces) == 0:
            raise ValueError("No face detected in the image")
        if len(faces) > 1:
            raise ValueError("Multiple faces detected")
            
        # bbox format: [x1, y1, x2, y2]
        bbox = faces[0].bbox.tolist()
        return self.liveness_service.is_live(img, bbox)

    async def match_face(self, org_id: str, embedding: np.ndarray, threshold: float = None) -> dict:
        """
        Search for a matching employee in the vector database.
        Returns:
            dict: {"match": bool, "employee_id": str, "score": float}
        """
        if threshold is None:
            # Check for an organization-specific threshold, falling back to settings
            org = await self.org_repo.get_org(org_id)
            if org and org.recognition_threshold is not None:
                threshold = org.recognition_threshold
            else:
                threshold = settings.RECOGNITION_THRESHOLD
            
        result = await self.vector_repo.search_embedding(org_id, embedding)
        
        if result and result["score"] >= threshold:
            return {
                "match": True,
                "employee_id": result["employee_id"],
                "score": result["score"]
            }
            
        return {
            "match": False,
            "employee_id": None,
            "score": result["score"] if result else 0.0
        }
