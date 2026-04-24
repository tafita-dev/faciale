---
id: US-02-ORG-002
title: Manage Departments or Classes
status: DONE
type: feature
---
# Description
As an Organization Admin, I want to create and list Departments (or Classes) so that I can organize my staff or students.

# Context Map
> Reference @specs/context-map.md
> Specific files for this story:
> * `backend/app/api/v1/endpoints/departments.py`
> * `backend/app/models/department.py`

# Acceptance Criteria (DoD)
- [ ] **Scenario 1: Create Department in own Organization**
    - Given I am logged in as an Organization Admin for "Org A"
    - When I POST to `/api/v1/departments` with name "Engineering"
    - Then a new department should be created linked to "Org A"
- [ ] **Scenario 2: List Departments for own Organization**
    - Given "Org A" has 3 departments and "Org B" has 2
    - When I GET `/api/v1/departments` as Org Admin of "Org A"
    - Then I should see only the 3 departments belonging to "Org A"
- [ ] **Scenario 3: Empty State**
    - Given my organization has no departments
    - When I GET `/api/v1/departments`
    - Then I should receive an empty list with a 200 OK

# Technical Notes (Architect)
- Ensure the `org_id` is automatically injected from the current user's JWT token, not the request body, to prevent cross-tenant creation.
