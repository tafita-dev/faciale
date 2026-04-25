---
id: US-07-SADM-004
title: Backend Delete Organization Endpoint
status: DONE
type: feature
---
# Description
As a Super Admin, I want to delete an organization from the system so that I can remove decommissioned or invalid accounts.

# Context Map
> Reference @specs/context-map.md to find file paths.
> Specific files for this story:
> * `backend/app/api/v1/endpoints/orgs.py`

# Acceptance Criteria (DoD)
- [ ] **Scenario 1: Successful Organization Deletion**
    - Given I am authenticated as a `superadmin`
    - When I send a `DELETE` request to `/api/v1/orgs/{org_id}`
    - Then the system should remove the organization from the database.
    - And return a `204 No Content` response.
- [ ] **Scenario 2: Non-existent Organization**
    - Given I am authenticated as a `superadmin`
    - When I send a `DELETE` request for a non-existent `org_id`
    - Then the system should return a `404 Not Found` error.
- [ ] **Scenario 3: Unauthorized Deletion**
    - Given I am authenticated as an `org_admin` or regular user
    - When I send a `DELETE` request to `/api/v1/orgs/{org_id}`
    - Then the system should return a `403 Forbidden` error.

# Technical Notes (Architect)
- Implement `DELETE` method in `backend/app/api/v1/endpoints/orgs.py`.
- Ensure cascading delete or referential integrity (e.g., what happens to users/employees? For now, simple delete of Org is enough, or mark as inactive).
- Use `check_admin` dependency (ensure it enforces `superadmin` for delete).
