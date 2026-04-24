---
id: US-01-AUTH-002
title: Setup MongoDB and Qdrant Connections
status: DONE
type: feature
---
# Description
As a Developer, I want to establish asynchronous connections to MongoDB and Qdrant so that the application can persist data and search facial vectors.

# Context Map
> Reference @specs/context-map.md
> Specific files for this story:
> * `backend/app/db/mongodb.py`
> * `backend/app/db/qdrant.py`

# Acceptance Criteria (DoD)
- [ ] **Scenario 1:** MongoDB Connection Success
    - Given valid MongoDB credentials in environment variables
    - When the application starts
    - Then the Motor client should connect successfully and log "Connected to MongoDB"
- [ ] **Scenario 2:** Qdrant Connection Success
    - Given valid Qdrant URL and credentials
    - When the application starts
    - Then the Qdrant client should initialize and be able to list collections
- [ ] **Scenario 3:** Connection Failure Handling
    - Given invalid database credentials
    - When the application starts
    - Then it should log an error and exit or retry according to policy

# Technical Notes (Architect)
- Use `motor` for MongoDB.
- Use `qdrant-client` (async preferred if available or wrapped).
- Connections should be handled in lifespan events of FastAPI.
