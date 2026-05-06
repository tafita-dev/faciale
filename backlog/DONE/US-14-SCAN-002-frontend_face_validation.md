---
id: US-14-SCAN-002
title: Advanced Frontend Facial Validation & Anti-Spoofing
status: DONE
type: feature
---
# Description
As a Security-Conscious User, I want the system to perform local face detection, head orientation checks, and liveness verification before any API communication, so that only genuine, well-positioned faces are processed.

# Context Map
> Specific files for this story:
> * @mobile/lib/features/attendance/face_detector_service.dart
> * @mobile/lib/features/attendance/scanner_state.dart

# Acceptance Criteria (DoD)
- [ ] **Scenario 1:** [Happy Path - Valid Face]
    - Given a face is detected by ML Kit and correctly centered/oriented (yaw/pitch)
    - When the scanner processes the frame
    - Then the system triggers the attendance/enrollment API call
- [ ] **Scenario 2:** [Error Case - Invalid Position/No Face]
    - Given a face is present but mal-oriented (e.g., looking away) or no face is found
    - When the scanner processes the frame
    - Then the system ignores the frame and does NOT call the API
- [ ] **Scenario 3:** [Error Case - Liveness Failure]
    - Given a static photo or screen is presented
    - When the scanner performs local liveness checks (blink/movement)
    - Then the system alerts the user and does NOT call the API

# UI element
- Instructional messages (e.g., "Look straight ahead", "Blink eyes").
- Temporary visual indicators if face orientation is poor.

# Technical Notes (Architect)
- Use ML Kit `headEulerAngleY` (yaw) and `headEulerAngleX` (pitch) for centering checks.
- Implement blink detection logic via landmark point tracking.
- Ensure the component is reusable for both Scan Employee and Add Employee.
