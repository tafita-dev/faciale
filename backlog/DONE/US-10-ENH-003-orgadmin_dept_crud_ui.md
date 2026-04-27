---
id: US-10-ENH-003
title: Org Admin - Department CRUD UI
status: DONE
type: feature
---
# Description
As an Organization Admin, I want to manage departments (Create, Update, Delete) through the UI so that I can organize my staff.

# Context Map
- Mobile: `mobile/lib/features/organizations/department_management_screen.dart`
- Backend: `backend/app/api/v1/endpoints/departments.py`

# Acceptance Criteria (DoD)
- [x] **Scenario 1: Create Department**
    - Given I am in the Department management section
    - When I enter a name and save
    - Then a new department should be created for my organization.
- [x] **Scenario 2: Update Department**
    - Given a list of departments
    - When I edit a department name
    - Then the name should be updated globally.
- [x] **Scenario 3: Delete Department**
    - Given a department with no assigned employees
    - When I delete it
    - Then it should be removed.

# Technical Notes (Architect)
- Implement `DepartmentNotifier` in the mobile app.
- Ensure backend validation prevents deleting departments that still have employees.
