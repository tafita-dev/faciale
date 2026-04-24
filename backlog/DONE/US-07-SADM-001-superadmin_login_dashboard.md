---
id: US-07-SADM-001
title: Super Admin Login and Multi-role Dashboard
status: DONE
type: feature
---
# Description
As a Super Admin, I want to login to the mobile app and see a specialized dashboard so that I can manage the entire system.

# Context Map
> Reference @specs/context-map.md to find file paths.
> Specific files for this story:
> * `mobile/lib/features/auth/auth_provider.dart`
> * `mobile/lib/features/dashboard/dashboard_screen.dart`

# Acceptance Criteria (DoD)
- [x] **Scenario 1: Super Admin Login**
    - Given I am at the Login Screen
    - When I enter Super Admin credentials (`superadmin@precity.com` / `admin123`)
    - Then the system should authenticate me and identify my role as `superadmin`.
    - And I should be redirected to the Super Admin Dashboard.
- [x] **Scenario 2: Super Admin Dashboard View**
    - Given I am logged in as a Super Admin
    - When I view the dashboard
    - Then I should see system-wide metrics (Total Organizations, Total Users).
    - And I should see an action to "Create New Organization".
- [x] **Scenario 3: Role-based Redirection**
    - Given I login as an `org_admin`
    - Then I should see the Organization Dashboard (already implemented).
    - Given I login as a `superadmin`
    - Then I should see the Super Admin Dashboard.

# UI element
- Login Form (existing).
- Super Admin Dashboard (New):
  - Card: "Active Organizations"
  - Card: "System Health"
  - Button: "Add Organization"

# Technical Notes (Architect)
- Update `authProvider` to handle real backend response (removing mock logic for superadmin).
- Implement role-based UI conditional rendering in `DashboardScreen`.
