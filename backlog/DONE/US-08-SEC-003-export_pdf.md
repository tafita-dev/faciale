---
id: US-08-SEC-003
title: Export Attendance Logs as PDF
status: DONE
type: feature
---
# Description
As an Organization Admin, I want to export attendance logs as PDF so that I can have a formatted, printer-friendly report for official documentation.

# Context Map
> Reference @specs/context-map.md to find file paths.
> Specific files for this story:
> * `backend/app/services/reporting_service.py`
> * `backend/app/api/v1/endpoints/reports.py`

# Acceptance Criteria (DoD)
- [x] **Scenario 1: Export PDF Success**
    - Given I am authenticated as an `org_admin`
    - When I send a `GET` request to `/api/v1/reports/export?format=pdf`
    - Then the system should return a PDF file with a table of attendance logs.
- [x] **Scenario 2: Content Validation**
    - Given the exported PDF
    - Then it should contain the Organization Name, Date Range, and the list of Employee names with their check-in times.

# Technical Notes (Architect)
- Use `ReportLab` or `FPDF` library for Python PDF generation.
- Ensure the file is streamed to the client to avoid high memory usage.
