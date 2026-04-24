---
id: US-06-REPORT-001
title: Backend API for Real-time Attendance Statistics
status: DONE
type: feature
---
# Description
As an Organization Admin, I want to retrieve real-time attendance statistics (Present, Absent, Late) so that I can see a quick summary of my organization's status on the dashboard.

# Context Map
> Reference @specs/context-map.md to find file paths.
> Specific files for this story:
> * `backend/app/api/v1/endpoints/reports.py`
> * `backend/app/services/reporting_service.py`

# Acceptance Criteria (DoD)
- [x] **Scenario 1: Retrieve today's statistics**
    - Given I am authenticated as an Org Admin
    - When I call `GET /api/v1/reports/stats`
    - Then the system should return the count of employees who are 'Present', 'Absent', and 'Late' for today.
    - And the response status should be 200 OK.
- [x] **Scenario 2: Statistics with no data**
    - Given an organization with no employees
    - When I call `GET /api/v1/reports/stats`
    - Then the system should return zeros for all categories.
- [x] **Scenario 3: Unauthorized access**
    - Given I am not authenticated
    - When I call `GET /api/v1/reports/stats`
    - Then the system should return 401 Unauthorized.

# Technical Notes (Architect)
- "Late" is defined by a threshold (e.g., after 9:00 AM) or a specific organization setting (not yet implemented, use 9:00 AM as default).
- Statistics should be calculated based on `AttendanceLog` and `Employee` collections in MongoDB.
- Use aggregation pipeline for efficiency.
