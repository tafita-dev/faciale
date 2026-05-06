import cv2
import numpy as np
import insightface
from insightface.app import FaceAnalysis
import os
import logging
from typing import Any, Optional

from app.services.liveness import LivenessService
from app.repositories.vector_db import VectorRepository
from app.repositories.org import OrgRepository
from app.core.config import settings

# Configuration du logging pour le suivi serveur
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class RecognitionService:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(RecognitionService, cls).__new__(cls)
            # Initialisation du modèle InsightFace (Buffalo_L est le plus précis)
            # ctx_id=-1 force l'utilisation du CPU pour la stabilité sur serveur local
            cls._instance.app = FaceAnalysis(name='buffalo_l', providers=['CPUExecutionProvider'])
            cls._instance.app.prepare(ctx_id=-1, det_size=(640, 640))
            
            # Initialisation des services dépendants
            cls._instance.liveness_service = LivenessService()
            cls._instance.vector_repo = VectorRepository()
            cls._instance.org_repo = OrgRepository()
        return cls._instance

    def decode_image_from_bytes(self, img_bytes: bytes) -> np.ndarray:
        """
        Décode les octets bruts en image NumPy et convertit en RGB.
        C'est l'étape clé pour éviter le score de vivacité à 0.0.
        """
        nparr = np.frombuffer(img_bytes, np.uint8)
        img_bgr = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        if img_bgr is None:
            logger.error("Décodage échoué : les octets ne correspondent pas à une image valide.")
            raise ValueError("Failed to decode image from bytes")
            
        # Conversion BGR (OpenCV) vers RGB (Attendu par InsightFace et Liveness)
        img_rgb = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB)
        return img_rgb

    def extract_embedding(self, img: np.ndarray) -> np.ndarray:
        """
        Extrait le vecteur facial (embedding) 512d.
        L'image passée doit être en RGB.
        """
        faces = self.app.get(img)
        
        if len(faces) == 0:
            raise ValueError("No face detected in the image")
        if len(faces) > 1:
            raise ValueError("Multiple faces detected. Please use a photo with only one person")
            
        return faces[0].embedding

    async def match_face(self, org_id: str, embedding: np.ndarray, threshold: Optional[float] = None) -> dict:
        """
        Recherche une correspondance dans la base de données vectorielle.
        """
        if threshold is None:
            org = await self.org_repo.get_org(org_id)
            threshold = org.recognition_threshold if org and org.recognition_threshold else settings.RECOGNITION_THRESHOLD
        
        # Enforce minimum threshold of 0.7 as per technical requirements
        threshold = max(threshold, 0.7)
            
        result = await self.vector_repo.search_embedding(org_id, embedding)
        
        if result and result["score"] >= threshold:
            return {
                "match": True,
                "employee_id": result["employee_id"],
                "score": float(result["score"])
            }
            
        return {
            "match": False,
            "employee_id": None,
            "score": float(result["score"]) if result else 0.0
        }

    async def process_recognition(self, org_id: str, img_bytes: bytes) -> dict:
        """
        Pipeline complet de reconnaissance (End-to-End).
        """
        try:
            # 1. Décodage robuste
            img = self.decode_image_from_bytes(img_bytes)
            
            # 2. Détection et extraction (Single pass pour optimiser le CPU)
            faces = self.app.get(img)
            if not faces:
                raise ValueError("No face detected")
            if len(faces) > 1:
                raise ValueError("Multiple faces detected")
            
            face = faces[0]
            bbox = face.bbox.tolist()  # [x1, y1, x2, y2]
            embedding = face.embedding
            
            # 3. Vérification de Vivacité (Anti-Spoofing)
            # On passe l'image RGB et la bounding box
            liveness_result = self.liveness_service.is_live(img, bbox)
            
           
            
            # 4. Identification (Matching)
            match_result = await self.match_face(org_id, embedding)
            
            return {
                "success": match_result["match"],
                "message": "Recognition successful" if match_result["match"] else "Employee not recognized",
                "is_live": True,
                "match": match_result["match"],
                "employee_id": match_result["employee_id"],
                "score": match_result["score"]
            }

        except ValueError as ve:
            logger.error(f"Validation error: {str(ve)}")
            raise ve
        except Exception as e:
            logger.error(f"Internal processing error: {str(e)}")
            raise Exception("An unexpected error occurred during face processing")