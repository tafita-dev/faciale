---
id: US-13-ATT-001
title: Backend - Toggling Attendance Logic
status: IN_PROGRESS
type: feature
---

# Description
As a System, I want to automatically alternate between "Entry" and "Exit" status based on the employee's last record of the day, so that the attendance flow is simplified for users.

# Context Map
> Reference @specs/context-map.md to find file paths.
> Specific files for this story:
> *   `backend/app/services/attendance.py`
> *   `backend/app/repositories/attendance.py`

# Acceptance Criteria (DoD)

- [x] **Scenario 1: First scan of the day**
    - Given an employee has no attendance records for the current day
    - When they perform a successful facial scan
    - Then the system records the pointage as "entry"

- [x] **Scenario 2: Subsequent scans of the day**
    - Given an employee's last successful record today was "entry"
    - When they perform a successful facial scan
    - Then the system records the pointage as "exit"
    - And if the last record was "exit", the next one must be "entry" (infinite toggle)

- [x] **Scenario 3: Date boundary check**
    - Given an employee performed an "entry" yesterday but hasn't scanned today
    - When they perform their first scan today
    - Then the system must record "entry" (ignoring yesterday's status)

# Technical Notes (Architect)
- Update `AttendanceRepository` to fetch only the *latest* successful log for the current server date.
- Use MongoDB index: `db.attendance.createIndex({ employee_id: 1, timestamp: -1 })`.
- Logic: `count(logs_today) % 2 == 0 ? ENTRY : EXIT` or based on `last_record.type`.
- Ensure timezone consistency (UTC recommended).
- Remove the "already checked in" debouncing logic if it blocks the "entry/exit" flow.
