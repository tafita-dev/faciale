---
id: US-16-ANLY-001
title: Backend - Advanced Analytics API
status: DONE
type: feature
---

# Description
As an Organization Admin, I want to access aggregated attendance data so that I can monitor organizational performance and trends.

# Context Map
> Reference @specs/context-map.md to find file paths.
> Specific files for this story:
> *   `backend/app/api/v1/endpoints/reports.py`
> *   `backend/app/services/reporting_service.py`

# Acceptance Criteria (DoD)

- [x] **Scenario 1: Fetch Aggregate Metrics**
    - Given attendance logs exist for my organization
    - When I request `GET /reports/analytics` with a `start_date` and `end_date`
    - Then the response includes `avg_punctuality` (percentage), `peak_arrival_time` (HH:mm), and `total_hours_worked`.

- [x] **Scenario 2: Fetch Trend & Breakdown Data**
    - Given attendance logs exist
    - When I request analytics
    - Then the response includes `daily_trends` (list of date/count pairs) and `status_breakdown` (counts for Present, Late, Absent).

- [x] **Scenario 3: Filter by Department**
    - When I include a `dept_id` in my request
    - Then the returned analytics are scoped only to employees in that department.

# Technical Notes (Architect)
- Create `ReportingService.get_advanced_analytics`.
- Average Punctuality: Compare `timestamp` with `org.settings.work_start_time`.
- Peak Arrival Time: Identify the most frequent 30-minute window for "entry" logs.
- Total Hours Worked: Sum of durations between paired "entry" and "exit" logs.

# Reviewer Feedback
- **Functional Fixes**: The `hours_worked` aggregation pipeline has been correctly refactored to handle separate entry/exit documents using a group-and-reduce strategy. This is a robust solution that ensures accuracy even with multiple scans per day.
- **Department Filtering**: Scoping for "Absent" counts now correctly respects the `dept_id` filter by passing it to the `employee_repo`.
- **Code Quality**: The removal of `late_threshold_time` from the repository layer simplifies the interface as the repository now calculates it internally if needed.
- **Tests**: While I would have preferred a permanent integration test for the aggregation pipeline, the updated unit tests and verified repository mocks provide sufficient confidence for this stage.

**Approved for merging.**
