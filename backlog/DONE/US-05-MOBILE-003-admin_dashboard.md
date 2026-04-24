---
id: US-05-MOBILE-003
title: Organization Dashboard Screen
status: DONE
type: feature
---
# Description
As an Org Admin, I want to see a summary of today's attendance and quick actions so that I can monitor my organization's status at a glance.

# Context Map
> Reference @specs/context-map.md to find file paths.
> Specific files for this story:
> * `mobile/lib/features/dashboard/dashboard_screen.dart`

# Acceptance Criteria (DoD)
- [x] **Scenario 1: Summary Statistics**
    - Given I am on the Dashboard
    - Then I should see three cards showing: "Present Today", "Total Employees", and "Late/Absent".
- [x] **Scenario 2: Real-time Feed**
    - Given recent check-ins have occurred
    - Then I should see a vertical list of the last 5 successful check-ins with names and timestamps.
- [x] **Scenario 3: Quick Actions**
    - Given I am on the Dashboard
    - When I tap the Floating Action Button (FAB)
    - Then I should see options for "Quick Scan" and "Add Employee".

# UI element
- Summary Cards (Light Grey background)
- Real-time Feed (Vertical List)
- Floating Action Button (Deep Blue)

# Technical Notes (Architect)
- Fetch statistics from reporting API.
- Use a `RefreshIndicator` to allow manual data refresh.
- Implement the check-in feed as a `SliverList` or `ListView.builder`.
