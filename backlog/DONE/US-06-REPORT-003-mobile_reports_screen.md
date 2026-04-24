---
id: US-06-REPORT-003
title: Mobile Attendance Reports Screen
status: DONE
type: feature
---
# Description
As an Organization Admin, I want a dedicated Reports screen in the mobile app so that I can monitor attendance logs on the go.

# Context Map
> Reference @specs/context-map.md to find file paths.
> Specific files for this story:
> * `mobile/lib/features/reports/reports_screen.dart`
> * `mobile/lib/features/reports/reports_provider.dart`

# Acceptance Criteria (DoD)
- [x] **Scenario 1: View attendance logs**
    - Given the Reports screen is navigated to via the bottom bar
    - When the screen loads
    - Then it should display a list of attendance logs showing Employee Name, Timestamp, and Status.
- [x] **Scenario 2: Pull to refresh**
    - Given the Reports screen is open
    - When I pull down to refresh
    - Then the list should be updated with the latest logs from the API.
- [x] **Scenario 3: Empty state**
    - Given no logs are returned from the API
    - Then I should see an "Empty State" message: "No attendance logs found."

# UI element
- List View of logs.
- Search/Filter icon (placeholder for now).
- Refresh indicator.

# Technical Notes (Architect)
- Use Riverpod to manage reporting state.
- Implement infinite scrolling/pagination if possible, or at least load the first page.
- Match the Blue/White/Black theme.
