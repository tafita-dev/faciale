---
id: US-02-ORG-003
title: Manage Employee Profiles (Metadata)
status: DONE
type: feature
---
# Description
As an Organization Admin, I want to add and list Employees (or Students) with their basic info so that they can be prepared for facial enrollment.

# Context Map
> Reference @specs/context-map.md
> Specific files for this story:
> * `backend/app/api/v1/endpoints/employees.py`
> * `backend/app/models/employee.py`

# Acceptance Criteria (DoD)
- [x] **Scenario 1: Add Employee with valid Department**
    - Given I am an Org Admin and "Dept X" exists in my Org
    - When I POST to `/api/v1/employees` with name "John Doe" and `dept_id` of "Dept X"
    - Then a new employee record should be created
- [x] **Scenario 2: Add Employee to invalid Department**
    - Given I am an Org Admin
    - When I POST to `/api/v1/employees` with a `dept_id` that belongs to a different Organization
    - Then I should receive a 400 Bad Request or 404 Not Found error
- [x] **Scenario 3: List Employees with Filters**
    - Given I have employees in multiple departments
    - When I GET `/api/v1/employees?dept_id=XYZ`
    - Then I should only see employees from that specific department

# Technical Notes (Architect)
- This story covers metadata only. Facial image enrollment is handled in Epic 3.
- Use a soft-delete pattern or `active` boolean for employees.
