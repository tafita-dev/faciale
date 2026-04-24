---
id: US-03-FACE-001
title: Enrollment Photo Upload API
status: DONE
type: feature
---
# Description
As an Organization Admin, I want to upload a reference photo for an existing employee so that the system can start the facial enrollment process.

# Context Map
> Reference @specs/context-map.md
> Specific files for this story:
> * `backend/app/api/v1/endpoints/employees.py` (Add new endpoint)
> * `backend/app/services/enrollment.py`

# Acceptance Criteria (DoD)
- [x] **Scenario 1: Successful Multipart Upload**
    - Given I am an Org Admin and "Employee 123" exists in my organization
    - When I POST a valid JPEG/PNG image to `/api/v1/employees/123/enroll`
    - Then I should receive a 202 Accepted (or 200 OK) confirming receipt
- [x] **Scenario 2: Unauthorized Organization Access**
    - Given I am an Org Admin for "Org A"
    - When I attempt to upload a photo for an employee belonging to "Org B"
    - Then I should receive a 403 Forbidden or 404 Not Found
- [x] **Scenario 3: Invalid File Type**
    - Given I am an Org Admin
    - When I upload a `.pdf` or `.txt` file instead of an image
    - Then I should receive a 400 Bad Request with "Invalid file type" message

# Technical Notes (Architect)
- The endpoint should use `UploadFile` from FastAPI.
- Limit file size to 5MB initially.
- This endpoint is the entry point for the enrollment pipeline.
