---
id: US-04-SMART-002
title: Vector Search & Identity Matching
status: DONE
type: feature
---
# Description
As a System, I want to compare a live facial embedding against the registered database so that I can identify the employee attempting to check in.

# Context Map
> Reference @specs/context-map.md to find file paths.
> Specific files for this story:
> * `backend/app/repositories/vector_db.py`
> * `backend/app/services/recognition.py`

# Acceptance Criteria (DoD)
- [x] **Scenario 1: Successful Match**
    - Given a live embedding and a valid `org_id`
    - When searching the Vector DB
    - Then it should return the `employee_id` with the highest similarity score if it is >= 0.85.
- [x] **Scenario 2: Low Confidence (No Match)**
    - Given an embedding that doesn't closely match any registered employee
    - When searching the Vector DB
    - Then it should return a "No Match" result if the highest score is below 0.85.
- [x] **Scenario 3: Multi-Organization Isolation**
    - Given a search request for Org A
    - When searching the Vector DB
    - Then it should never return results belonging to Org B.

# UI element
None (Backend Logic).

# Technical Notes (Architect)
- Use Qdrant's `search` API with a filter on `org_id`.
- Threshold (0.85) should be configurable via environment variables or organization settings.
- Ensure the search is optimized for speed (< 500ms for the DB query).

# Reviewer Feedback
The implementation of the matching logic and multi-organization isolation is correct and passes the tests. However, it fails to meet the technical requirement regarding the configurability of the threshold.

- **Missing Configurability**: Fixed. Added `RECOGNITION_THRESHOLD` to `Settings` and `.env`.
- **Organization Settings**: Fixed. `RecognitionService.match_face` now fetches organization-specific threshold from `OrgRepository`.
