---
id: US-04-SMART-003
title: Attendance Logging Persistence
status: DONE
type: feature
---
# Description
As a System, I want to record every attendance attempt in a permanent log so that admins can review history and generate reports.

# Context Map
> Reference @specs/context-map.md to find file paths.
> Specific files for this story:
> * `backend/app/models/attendance.py`
> * `backend/app/db/mongodb.py`

# Acceptance Criteria (DoD)
- [x] **Scenario 1: Log Successful Check-in**
    - Given a successful facial match and liveness check
    - When the system processes the result
    - Then it should save a log entry with `status: "success"`, the `employee_id`, and the `confidence_score`.
- [x] **Scenario 2: Log Failed Attempt (Unknown Person)**
    - Given a check-in attempt that fails to match an employee
    - When the system processes the result
    - Then it should save a log entry with `status: "failed"`, `reason: "no_match"`, and `employee_id: null`.
- [x] **Scenario 3: Log Spoofing Attempt**
    - Given an attempt where liveness detection fails
    - When the system processes the result
    - Then it should save a log entry with `status: "failed"`, `reason: "spoof_detected"`.

# UI element
None (Backend Logic).

# Technical Notes (Architect)
- MongoDB collection: `attendance_logs`.
- Index by `timestamp` and `employee_id` for reporting performance.
- Use Pydantic models for data validation.
