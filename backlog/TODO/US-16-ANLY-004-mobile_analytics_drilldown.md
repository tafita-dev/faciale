---
id: US-16-ANLY-004
title: Mobile - Analytics Drill-down Interaction
status: READY
type: feature
---

# Description
As an Admin, I want to explore the data behind the charts so that I can understand individual cases that affect the metrics.

# Context Map
> Reference @specs/context-map.md to find file paths.
> Specific files for this story:
> *   `mobile/lib/features/reports/analytics_screen.dart`
> *   `mobile/lib/features/reports/report_view.dart`

# Acceptance Criteria (DoD)

- [ ] **Scenario 1: Status Drill-down**
    - When I tap on a segment of the status doughnut chart (e.g., "Late")
    - Then I am navigated to the Attendance Logs list screen.
    - And the list is automatically filtered to show only "Late" records for the current period.

- [ ] **Scenario 2: Trend Drill-down**
    - When I tap on a specific point in the trend line chart
    - Then I am navigated to the logs list for that specific day.

# Technical Notes (Architect)
- Use `go_router` or `Navigator` with query parameters to pass the filter state to the `ReportView` screen.
- Ensure the `ReportView` screen can parse these incoming filters (status, date) and apply them to its initial state.
