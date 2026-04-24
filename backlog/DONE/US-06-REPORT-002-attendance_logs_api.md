---
id: US-06-REPORT-002
title: Backend API for Attendance Logs with Filtering
status: DONE
type: feature
---
# Description
As an Organization Admin, I want to view a detailed list of attendance logs with filtering and pagination so that I can audit attendance activity.

# Context Map
> Reference @specs/context-map.md to find file paths.
> Specific files for this story:
> * `backend/app/api/v1/endpoints/reports.py`
> * `backend/app/repositories/attendance_repo.py`

# Acceptance Criteria (DoD)
- [x] **Scenario 1: List logs with pagination**
    - Given I am authenticated as an Org Admin
    - When I call `GET /api/v1/reports/logs?page=1&size=10`
    - Then the system should return a paginated list of attendance logs.
- [x] **Scenario 2: Filter by date range**
    - Given I am authenticated
    - When I call `GET /api/v1/reports/logs?start_date=2023-01-01&end_date=2023-01-31`
    - Then the system should only return logs within that range.
- [x] **Scenario 3: Filter by department**
    - Given I am authenticated
    - When I call `GET /api/v1/reports/logs?dept_id=[UUID]`
    - Then the system should only return logs for employees in that department.

# Technical Notes (Architect)
- Join `AttendanceLog` with `Employee` to return employee names in the response.
- Use `pydantic` for request validation.
- Response should include `total_count`, `page`, and `size`.
