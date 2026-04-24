---
id: US-07-SADM-002
title: Mobile UI for Organization Creation
status: IN_PROGRESS
type: feature
---
# Description
As a Super Admin, I want to create new organizations via the mobile app so that I can onboard new clients efficiently.

# Context Map
> Reference @specs/context-map.md to find file paths.
> Specific files for this story:
> * `mobile/lib/features/organizations/create_org_screen.dart`
> * `mobile/lib/features/organizations/org_provider.dart`

# Acceptance Criteria (DoD)
- [ ] **Scenario 1: Access Organization Creation**
    - Given I am on the Super Admin Dashboard
    - When I tap "Add Organization"
    - Then I should be navigated to the "Create Organization" screen.
- [ ] **Scenario 2: Create Organization Success**
    - Given I am on the "Create Organization" screen
    - When I fill in "Organization Name" and "Type" (School/Company)
    - And I tap "Create"
    - Then the app should call `POST /api/v1/orgs/`
    - And show a success message "Organization created successfully".
    - And redirect back to the Super Admin Dashboard.
- [ ] **Scenario 3: Validation Error**
    - Given I leave the name empty
    - When I tap "Create"
    - Then I should see a validation error "Organization name is required".

# UI element
- Form with:
  - Text Field: Organization Name
  - Dropdown: Type (School, Company)
  - Button: Create (Primary Blue)

# Technical Notes (Architect)
- Create `organizations` feature folder in mobile.
- Use `http` package to call the existing backend endpoint.
- Use `ref.read(authProvider)` to get the Super Admin token.
