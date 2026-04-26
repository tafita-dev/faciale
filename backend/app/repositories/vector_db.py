import uuid
from qdrant_client import AsyncQdrantClient
from qdrant_client.http import models
from app.db.qdrant import get_qdrant_client
from app.core.security import encrypt_data, decrypt_data
import numpy as np

class VectorRepository:
    def __init__(self, client: AsyncQdrantClient = None):
        self.client = client or get_qdrant_client()
        self.collection_name = "embeddings"

    def _get_uuid(self, employee_id: str) -> str:
        # Generate a stable UUID v5 from employee_id
        # Using a fixed namespace for Faciale
        NAMESPACE_FACIALE = uuid.UUID('12345678-1234-5678-1234-567812345678')
        return str(uuid.uuid5(NAMESPACE_FACIALE, employee_id))

    async def upsert_embedding(self, employee_id: str, org_id: str, embedding: np.ndarray):
        point_id = self._get_uuid(employee_id)
        
        # Biometric Encryption at Rest:
        # Encrypt the embedding vector and store it in the payload.
        # The vector itself remains unencrypted for Qdrant search.
        encrypted_embedding = encrypt_data(embedding.tolist())
        
        await self.client.upsert(
            collection_name=self.collection_name,
            points=[
                models.PointStruct(
                    id=point_id,
                    vector=embedding.tolist(),
                    payload={
                        "employee_id": employee_id,
                        "org_id": org_id,
                        "encrypted_embedding": encrypted_embedding
                    }
                )
            ]
        )

    async def search_embedding(self, org_id: str, embedding: np.ndarray, limit: int = 1):
        results = await self.client.search(
            collection_name=self.collection_name,
            query_vector=embedding.tolist(),
            query_filter=models.Filter(
                must=[
                    models.FieldCondition(
                        key="org_id",
                        match=models.MatchValue(value=org_id)
                    )
                ]
            ),
            limit=limit
        )
        
        if not results:
            return None
            
        payload = results[0].payload
        data = {
            "employee_id": payload["employee_id"],
            "score": results[0].score
        }
        
        # Decrypt embedding if present
        if "encrypted_embedding" in payload:
            data["embedding"] = decrypt_data(payload["encrypted_embedding"], as_json=True)
            
        return data
