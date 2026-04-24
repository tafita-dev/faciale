---
id: US-04-SMART-004
title: Unified Attendance Check-in API
status: DONE
type: feature
---
# Description
As a Mobile Client, I want a single API endpoint to submit a check-in request so that the complex flow (liveness + matching + logging) is handled in one call.

# Context Map
> Reference @specs/context-map.md to find file paths.
> Specific files for this story:
> * `backend/app/api/v1/endpoints/attendance.py`
> * `backend/app/main.py`

# Acceptance Criteria (DoD)
- [x] **Scenario 1: Complete Happy Path**
    - Given a valid check-in request with an image
    - When the mobile app calls `POST /api/v1/attendance/check-in`
    - Then the system should return a `200 OK` with the employee's name and check-in time within 2 seconds.
- [x] **Scenario 2: Rapid Re-try Handling**
    - Given a user who just successfully checked in
    - When they attempt another check-in within 60 seconds
    - Then the system should return a message indicating they are already checked in (Debouncing).
- [x] **Scenario 3: Invalid Input**
    - Given a request without an image or with a corrupted file
    - When the API is called
    - Then it should return a `400 Bad Request`.

# UI element
None (API Definition).

# Technical Notes (Architect)
- The endpoint should coordinate `LivenessService`, `RecognitionService`, and `AttendanceRepo`.
- Implement basic rate limiting/debouncing to prevent duplicate logs.
- Profile the endpoint to ensure it meets the < 2s NFR.

# Reviewer Feedback
The implementation of the unified check-in endpoint is well-structured and correctly implements the debouncing logic and the standard success path. However, it fails to fully satisfy **Scenario 3: Invalid Input**.

- **Missing Error Handling**: The endpoint does not catch `ValueError` exceptions that can be raised by the `AttendanceService` or `RecognitionService` (e.g., "Failed to decode image from bytes", "No face detected in the image", "Multiple faces detected"). These exceptions will currently result in a **500 Internal Server Error** instead of the required **400 Bad Request**.
- **Scenario 3 Verification**: Please ensure that corrupted files or images with no detected faces return a `400 Bad Request` as per the Acceptance Criteria. You may want to use a `try...except ValueError` block in the endpoint or implement a global exception handler in `main.py`.
- **Testing**: Add a test case in `test_attendance_api.py` to verify that a corrupted image (mocking the service to raise `ValueError`) returns a 400 error.
