---
id: US-06-REPORT-004
title: Export Attendance Logs to CSV
status: DONE
type: feature
---
# Description
As an Organization Admin, I want to export the attendance logs to a CSV file so that I can process the data in external tools like Excel.

# Context Map
> Reference @specs/context-map.md to find file paths.
> Specific files for this story:
> * `backend/app/api/v1/endpoints/reports.py`
> * `mobile/lib/features/reports/export_service.dart`

# Acceptance Criteria (DoD)
- [x] **Scenario 1: Export from backend**
    - Given I am authenticated as an Org Admin
    - When I call `GET /api/v1/reports/export?format=csv`
    - Then the system should return a CSV file containing all attendance logs for my organization.
- [x] **Scenario 2: Trigger export from mobile**
    - Given the Reports screen is open
    - When I tap the "Export CSV" button
    - Then the app should download/share the generated file.

# Technical Notes (Architect)
- [x] Use `StreamingResponse` in FastAPI to handle large CSV exports.
- [x] For mobile sharing, use `share_plus` or similar package.
- [x] Ensure the CSV columns include: Date, Time, Employee Name, Department, Status, Confidence Score.
