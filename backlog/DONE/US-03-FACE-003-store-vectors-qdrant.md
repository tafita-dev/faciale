---
id: US-03-FACE-003
title: Store Vectors in Qdrant
status: DONE
type: feature
---
# Description
As a System, I want to store the extracted facial embeddings in the Vector Database (Qdrant) so that I can perform lightning-fast attendance matching later.

# Context Map
> Reference @specs/context-map.md
> Specific files for this story:
> * `backend/app/db/qdrant.py`
> * `backend/app/services/enrollment.py`

# Acceptance Criteria (DoD)
- [x] **Scenario 1: Successful Vector Storage**
    - Given a 512d embedding for "Employee 123"
    - When the system saves it to Qdrant
    - Then the vector should be searchable using "Employee 123"'s ID as payload metadata
- [x] **Scenario 2: Update Existing Enrollment**
    - Given "Employee 123" is already enrolled
    - When I upload a new photo and save the new vector
    - Then the old vector in Qdrant should be replaced or updated for that `employee_id`
- [x] **Scenario 3: MongoDB Status Update**
    - Given a successful vector storage in Qdrant
    - When the process completes
    - Then the employee record in MongoDB should have `is_enrolled: True`

# Technical Notes (Architect)
- Use the `org_id` as a partition key or metadata filter in Qdrant to ensure cross-tenant isolation during search.
- Use `upsert` operation in Qdrant using `employee_id` as a point ID (UUID v5 derived from employee_id or similar).

# Reviewer Feedback
- The implementation correctly uses Qdrant `upsert` with a stable UUID v5 derived from `employee_id`.
- `org_id` is included in the payload for isolation.
- `is_enrolled` status is updated in MongoDB.
- Added `is_enrolled` to `EmployeeInDB` Pydantic model and initialized it in the creation endpoint for consistency.
