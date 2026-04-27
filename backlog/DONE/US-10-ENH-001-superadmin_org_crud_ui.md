---
id: US-10-ENH-001
title: SuperAdmin - Organization Management UI
status: DONE
type: feature
---
# Description
As a SuperAdmin, I want to view, edit, and delete organizations so that I can manage system tenants effectively.

# Context Map
- Mobile: `mobile/lib/features/organizations/org_list_screen.dart`
- Backend: `backend/app/api/v1/endpoints/orgs.py`

# Acceptance Criteria (DoD)
- [x] **Scenario 1: View Organization List**
    - Given I am logged in as SuperAdmin
    - When I navigate to the Organizations screen
    - Then I should see a list of all existing organizations.
- [x] **Scenario 2: Edit Organization**
    - Given I am on the Organization List screen
    - When I select "Edit" on an organization and update its name or type
    - Then the changes should be persisted and reflected in the list.
- [x] **Scenario 3: Delete Organization**
    - Given I am on the Organization List screen
    - When I select "Delete" and confirm the action
    - Then the organization should be removed from the system.

# Technical Notes (Architect)
- Reuse `OrgNotifier` for the API calls.
- Add confirmation dialogs for destructive actions.

# Reviewer Feedback
- UI implementation for editing and deleting organizations is clean and matches the requirements.
- Proper use of confirmation dialogs for destructive actions.
- Test coverage is excellent, including widget and provider tests.
- Backend endpoints were already available and correctly leveraged.
