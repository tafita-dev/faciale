---
id: US-10-ENH-002
title: Org Admin - Employee List with Department Filtering
status: DONE
type: feature
---
# Description
As an Organization Admin, I want to view my employees grouped or filtered by department so that I can manage large teams easily.

# Context Map
- Mobile: `mobile/lib/features/employees/employees_screen.dart`

# Acceptance Criteria (DoD)
- [x] **Scenario 1: Filter by Department**
    - Given I am on the Employees screen
    - When I select a specific department from a filter dropdown
    - Then only employees belonging to that department should be displayed.
- [x] **Scenario 2: Grouped View**
    - Given I am on the Employees screen
    - When I enable "Group by Department"
    - Then employees should be organized into sections labeled by their department.

# Technical Notes (Architect)
- Use a `ListView.builder` with headers or a `ExpansionPanelList` for grouping.
- Ensure the `Employee` model includes `dept_name` or `dept_id`.
