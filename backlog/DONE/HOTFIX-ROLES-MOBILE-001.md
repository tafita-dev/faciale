---
id: HOTFIX-ROLES-MOBILE-001
title: Fix roles and permissions on mobile
status: DONE
type: hotfix
---
# Description
Update mobile application to enforce the new role-based access control (RBAC) rules.

# Acceptance Criteria (DoD)
- [x] Superadmin navigation limited to Dashboard (Orgs) and Profile.
- [x] Superadmin dashboard hides employee and total user counts.
- [x] Admin dashboard shows organization-wide summaries and check-ins.
- [x] Admin can see organization-wide reports and employees.
- [x] User dashboard shows only their own recordings and managed employees count.
- [x] User navigation includes Dashboard, Employees, Reports, and Profile.
- [x] Quick Scan (Pointage) restricted to User role only.
- [x] Create User action restricted to Admin role.

# Technical Notes
- Modified `NavigationShell` to hide tabs for Superadmin.
- Updated `DashboardScreen` and `DashboardState` to handle role-specific data and actions.
- Added scope indicators to `ReportsScreen` and `EmployeesScreen`.
- Verified `auth_provider.dart` correctly handles role from JWT.
