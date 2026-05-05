---
id: US-12-BRAND-006-2
title: Mobile - Refined User List for Admin
status: DONE
type: feature
priority: MEDIUM
---

# Description
As an Admin, I want the User list (Employees) to show specific fields (Name, Email, Photo) so that I have the most relevant information at a glance.

# Context Map
> Reference @specs/context-map.md to find file paths.
> Specific files for this story:
> * `mobile/lib/features/employees/employees_screen.dart`

# Acceptance Criteria (DoD)

- [x] **Scenario 1: Admin User List Fields**
    - Given I am logged in as Admin
    - When I view the Users list (Employees)
    - Then each entry displays: Name, Email, and Photo.

# Technical Notes (Architect)
- Ensure the API response for employees includes the email field (photo should already be there).
- Use a consistent card layout similar to the Organization list for visual harmony.
