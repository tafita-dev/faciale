---
id: US-09-PERF-002
title: Scalability Verification with 1,000+ Vectors
status: DONE
type: feature
---
# Description
As a Super Admin, I want to be confident that the system can handle organizations with over 1,000 employees without significant performance degradation in facial matching.

# Context Map
- Backend: `backend/app/repositories/vector_db.py`
- Test: `backend/tests/test_scalability.py`

# Acceptance Criteria (DoD)
- [x] **Scenario 1: Bulk Insertion and Search**
    - Given a Qdrant collection populated with 1,000+ mock facial embeddings
    - When a search query is performed for a known face
    - Then the search time within the vector database should be less than 100ms on average. (Result: ~13ms)
- [x] **Scenario 2: Accuracy Maintenance**
    - Given a large vector space (1,000+ vectors)
    - When matching a face with a similarity score > 0.85
    - Then the system should correctly identify the individual without increasing False Positives. (Result: Noisy match score ~0.97)

# Technical Notes (Architect)
- Use a script to generate 1,000 random 512d vectors and upsert them into a test Qdrant collection.
- Measure the time of `qdrant_client.search`.
- Validate that the indexing (HNSW) is working as expected for fast retrieval.
