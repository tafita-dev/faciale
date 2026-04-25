---
id: US-07-SADM-005
title: Mobile UI for Organization Listing and Management
status: READY
type: feature
---
# Description
As a Super Admin, I want to see a list of all organizations and have the ability to delete them so that I can manage the system's clients effectively.

# Context Map
> Reference @specs/context-map.md to find file paths.
> Specific files for this story:
> * `mobile/lib/features/organizations/org_list_screen.dart`
> * `mobile/lib/features/organizations/org_provider.dart`

# Acceptance Criteria (DoD)
- [ ] **Scenario 1: View Organization List**
    - Given I am on the Super Admin Dashboard
    - When I tap "Active Organizations" card or a "View All" button
    - Then I should see a scrollable list of all registered organizations.
    - And each item should display the organization name and type.
- [ ] **Scenario 2: Delete Organization with Confirmation**
    - Given I am on the "Organization List" screen
    - When I tap the "Delete" icon next to an organization
    - Then I should see a confirmation dialog asking "Are you sure you want to delete this organization?".
    - When I confirm "Delete"
    - Then the app should call `DELETE /api/v1/orgs/{id}`.
    - And remove the item from the list with a success snackbar.
- [ ] **Scenario 3: Empty State**
    - Given there are no organizations in the system
    - When I navigate to the "Organization List" screen
    - Then I should see a message "No organizations found".

# UI element
- Screen: Organization List
  - ListView with `ListTile` for each org.
  - Delete Icon (Trash bin) on the trailing edge of each tile.
  - Confirmation Dialog.
  - Loading Spinner during fetch/delete.

# Technical Notes (Architect)
- Update `OrgNotifier` in `org_provider.dart` to include a `deleteOrganization(id)` method.
- Use `ListView.builder` for the list.
- Implement a `Provider` for fetching the list of organizations.
