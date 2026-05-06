---
id: US-13-ATT-006
title: Backend - Support forced attendance type in unified API
status: DONE
type: feature
---

# Description
As an API, I want to support an optional `force_type` parameter in the `/check-in` endpoint so that clients can override the automatic entry/exit toggling logic.

# Context Map
> Reference @specs/context-map.md to find file paths.
> Specific files for this story:
> *   `backend/app/api/v1/endpoints/attendance.py`
> *   `backend/app/services/attendance.py`

# Acceptance Criteria (DoD)

- [ ] **Scenario 1: Forced Entry**
    - Given a check-in request with `force_type="entry"`
    - When the face is successfully matched
    - Then the `AttendanceLog` is created with `attendance_type="entry"` regardless of previous logs today.

- [ ] **Scenario 2: Forced Exit**
    - Given a check-in request with `force_type="exit"`
    - When the face is successfully matched
    - Then the `AttendanceLog` is created with `attendance_type="exit"` regardless of previous logs today.

- [ ] **Scenario 3: Validation of force_type**
    - Given a check-in request with `force_type="invalid"`
    - When the request is received
    - Then the API returns a 422 Unprocessable Entity error (or 400 Bad Request).

- [ ] **Scenario 4: Default behavior preserved**
    - Given a check-in request WITHOUT `force_type`
    - When the face is matched
    - Then the system uses the automatic toggling logic (count logs today % 2).

# Technical Notes (Architect)
- Add `force_type: Optional[str] = None` to the `check_in` endpoint parameters (as a Query param or Form field).
- Update `AttendanceService.process_attendance` to accept `force_type`.
- If `force_type` is provided, skip the `count_logs_today` check and use the provided value.
- Ensure `force_type` is validated against `AttendanceType` enum values.
