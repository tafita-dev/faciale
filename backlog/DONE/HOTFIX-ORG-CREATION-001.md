---
id: HOTFIX-ORG-CREATION-001
title: Fix Organization Creation to be compatible with backend
status: DONE
type: hotfix
---
# Description
The mobile app currently only sends `name` and `type` when creating an organization, but the backend requires `admin_name`, `admin_email`, and `admin_password` to create the organization's initial admin user.

# Context Map
* `mobile/lib/features/organizations/create_org_screen.dart`
* `mobile/lib/features/organizations/org_provider.dart`

# Acceptance Criteria
- [x] `OrgNotifier.createOrg` accepts and sends `adminName`, `adminEmail`, and `adminPassword`.
- [x] `CreateOrgScreen` includes fields for Admin Name, Admin Email, and Admin Password.
- [x] Fields are validated (email format, non-empty, etc.).
- [x] Organization creation works successfully with the backend.
