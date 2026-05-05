---
id: US-11-SHFT-002
title: Attendance - Auto-Categorize Status (Present/Late)
status: DONE
type: feature
priority: HIGH
---

# Description
As a System, I want to automatically determine if an attendance log is "Present" or "Late" based on the organization's configured hours so that reporting is accurate without manual intervention.

# Context Map
> Reference @specs/context-map.md to find file paths.
> Specific files for this story:
> * `backend/app/services/recognition.py`
> * `backend/app/repositories/attendance.py`

# Acceptance Criteria (DoD)

- [x] **Scenario 1: Check-in before buffer**
    - Given Org Start Time is "09:00" and Buffer is "15 minutes"
    - When an employee checks in at "09:10"
    - Then the `AttendanceLog` status is set to "present".
- [x] **Scenario 2: Check-in after buffer**
    - Given Org Start Time is "09:00" and Buffer is "15 minutes"
    - When an employee checks in at "09:16"
    - Then the `AttendanceLog` status is set to "late".
- [x] **Scenario 3: No configuration fallback**
    - Given an organization has not configured work hours
    - When an employee checks in
    - Then the status defaults to "present".

# Technical Notes (Architect)
- Modify `RecognitionService` or `AttendanceRepository` to fetch `Organization.settings` before saving a successful match.
- Compare current server time with `start_time` + `late_buffer_minutes`.
- Use `pytz` to handle timezones correctly based on the organization's location (assume UTC for now if not specified).
