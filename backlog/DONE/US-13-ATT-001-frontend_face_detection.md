---
id: US-13-ATT-001
title: Frontend Continuous Facial Detection with ML Kit
status: DONE
type: feature
---
# Description
As a Mobile User, I want the attendance scanner to capture facial data continuously and detect faces locally using ML Kit, so that the application only makes API calls when a valid face is present.

# Context Map
> Reference @specs/context-map.md
> Specific files for this story:
> *   @mobile/lib/features/attendance/scanner_screen.dart
> *   @mobile/lib/features/attendance/scanner_state.dart
> *   @mobile/lib/features/attendance/face_detector_service.dart

# Acceptance Criteria (DoD)
- [ ] **Scenario 1:** [Happy Path - Face Detected]
    - Given the scanner is active and a human face is present in the camera frame
    - When the scanner processes the frame locally using ML Kit
    - Then the system identifies the face and initiates the API call for attendance matching
- [ ] **Scenario 2:** [Happy Path - No Face Detected]
    - Given the scanner is active and no human face is present
    - When the scanner processes the frame locally using ML Kit
    - Then the system does not initiate any API call and continues scanning
- [ ] **Scenario 3:** [Error Case - Camera Permission Denied]
    - Given the scanner is initiated
    - When camera permissions are denied
    - Then the system displays an appropriate error message to the user

# UI element
- The camera preview remains active continuously.
- Visual feedback (e.g., box or oval) highlights the detected face in real-time.

# Technical Notes (Architect)
- Use `google_mlkit_face_detection` for local processing.
- Offload frame processing to a background isolate if performance issues occur.
- Ensure the state management correctly handles the 'scanning' vs 'processing' transitions.
