---
id: US-02-ORG-001
title: Create and List Organizations
status: DONE
type: feature
---
# Description
As a Super Admin, I want to create and list Organization accounts (Schools or Companies) so that they can begin using the system.

# Context Map
> Reference @specs/context-map.md
> Specific files for this story:
> * `backend/app/api/v1/endpoints/orgs.py`
> * `backend/app/models/org.py`

# Acceptance Criteria (DoD)
- [ ] **Scenario 1: Successful Organization Creation**
    - Given I am logged in as a Super Admin
    - When I POST to `/api/v1/orgs` with name "Test School" and type "school"
    - Then a new organization record should be created in MongoDB
    - And I should receive a 201 Created response
- [ ] **Scenario 2: Invalid Organization Type**
    - Given I am a Super Admin
    - When I POST to `/api/v1/orgs` with type "other"
    - Then I should receive a 422 Unprocessable Entity error
- [ ] **Scenario 3: Unauthorized Access**
    - Given I am logged in as a standard Organization Admin
    - When I POST to `/api/v1/orgs`
    - Then I should receive a 403 Forbidden error

# Technical Notes (Architect)
- Enforce unique names for Organizations.
- Use a Pydantic model to validate the `type` enum.
