import uuid
from qdrant_client import AsyncQdrantClient
from qdrant_client.http import models
from app.db.qdrant import get_qdrant_client
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
        
        await self.client.upsert(
            collection_name=self.collection_name,
            points=[
                models.PointStruct(
                    id=point_id,
                    vector=embedding.tolist(),
                    payload={
                        "employee_id": employee_id,
                        "org_id": org_id
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
            
        return {
            "employee_id": results[0].payload["employee_id"],
            "score": results[0].score
        }
