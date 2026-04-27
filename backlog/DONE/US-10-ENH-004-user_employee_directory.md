---
id: US-10-ENH-004
title: User - Employee Directory
status: DONE
type: feature
---
# Description
As an Employee, I want to see a list of my colleagues so that I can know who is in my organization.

# Context Map
- Mobile: `mobile/lib/features/employees/directory_screen.dart`

# Acceptance Criteria (DoD)
- [x] **Scenario 1: Access Directory**
    - Given I am logged in as a regular user
    - When I open the "Directory" tab
    - Then I should see a list of names and departments of my colleagues.
- [x] **Scenario 2: Privacy**
    - Given I am viewing the directory
    - Then I should NOT see sensitive data like biometric status or private contact info.

# Technical Notes (Architect)
- Read-only view for regular employees.
- Optimize fetching for large organizations using pagination.
