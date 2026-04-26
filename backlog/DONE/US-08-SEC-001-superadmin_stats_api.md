---
id: US-08-SEC-001
title: Super Admin System-wide Statistics API
status: DONE
type: feature
---
# Description
As a Super Admin, I want to see real-time system-wide statistics so that I can monitor the growth and health of the platform.

# Context Map
> Reference @specs/context-map.md to find file paths.
> Specific files for this story:
> * `backend/app/api/v1/endpoints/reports.py`
> * `backend/app/services/reporting_service.py`

# Acceptance Criteria (DoD)
- [x] **Scenario 1: Fetch Global Stats Success**
    - Given I am authenticated as a `superadmin`
    - When I send a `GET` request to `/api/v1/reports/system-stats`
    - Then the system should return the total number of organizations and total number of users (employees).
- [x] **Scenario 2: Unauthorized Access**
    - Given I am authenticated as an `org_admin`
    - When I send a `GET` request to `/api/v1/reports/system-stats`
    - Then the system should return a `403 Forbidden` error.

# Technical Notes (Architect)
- Implement `get_system_stats` in `ReportingService`.
- Expose the endpoint in `reports.py` with `check_superadmin` dependency.

# Reviewer Feedback
- The implementation is missing the "total number of users (employees)" in the `system-stats` endpoint as required by Acceptance Criteria Scenario 1.
- Please update `ReportingService.get_system_stats` to include `total_users` (using `employee_repo.count_all()`).
- Update the tests in `backend/tests/test_report_api.py` to verify the presence of `total_users`.
