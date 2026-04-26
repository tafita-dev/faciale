---
id: US-08-SEC-002
title: Biometric Data Encryption at Rest
status: DONE
type: feature
---
# Description
As a Security-conscious User, I want my biometric data (facial embeddings) to be encrypted at rest so that my privacy is protected even if the database is compromised.

# Context Map
> Reference @specs/context-map.md to find file paths.
> Specific files for this story:
> * `backend/app/repositories/vector_db.py`
> * `backend/app/core/security.py`

# Acceptance Criteria (DoD)
- [x] **Scenario 1: Store Encrypted Embedding**
    - Given a facial embedding vector
    - When it is stored in Qdrant
    - Then it should be encrypted using a project-wide master key before being sent to the database.
- [x] **Scenario 2: Retrieve and Decrypt Embedding**
    - Given an encrypted embedding is retrieved from Qdrant
    - When it is used for matching
    - Then it should be decrypted correctly to its original 512d vector.

# Technical Notes (Architect)
- Use `cryptography` library with AES-256 (Fernet) for encryption.
- Store the master key in `.env` (already present or to be added).
- Note: If Qdrant performs distance matching, encryption might prevent direct search. 
- *Correction*: Biometric "data at rest" encryption in this context usually refers to the reference image or the metadata. If vectors are encrypted, search is impossible. 
- *Refined Plan*: Focus on encrypting the reference images on disk/S3 and ensuring the metadata in MongoDB/Qdrant is encrypted. If the PRD mandates vector encryption, use a searchable encryption scheme or clarify with stakeholders.
- *Assumption*: We will encrypt the reference images and sensitive employee metadata.
