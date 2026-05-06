---
id: US-15-ENR-002
title: Intelligent Real-time Face Validation
status: DONE
type: feature
---
# Description
As a Security-Conscious User, I want the system to detect faces locally via ML Kit, providing dynamic visual feedback and controlling the capture process, so that only high-quality, valid images are captured.

# Context Map
> Reference @specs/context-map.md
> Specific files for this story:
> * @mobile/lib/features/attendance/face_detector_service.dart
> * @mobile/lib/features/employees/enroll_screen.dart

# Acceptance Criteria (DoD)
- [ ] **Scenario 1:** [Happy Path - Face Detection & Visual Feedback]
    - Given the camera is active and a face is in view
    - When the face is centered and oriented correctly
    - Then the system draws a blue dynamic border around the face and shows the capture button
- [ ] **Scenario 2:** [Error Case - No Face/Bad Orientation]
    - Given the camera is active but no face is found or orientation is bad (yaw/pitch > 15°)
    - When the scanner processes the frame
    - Then the system draws a red dynamic border, hides the capture button, and prompts for centering
- [ ] **Scenario 3:** [Happy Path - Capture Interaction]
    - Given a valid face is detected (blue border shown)
    - When the user taps the 'capture' button
    - Then the image is captured and the employee enrollment process proceeds

# UI element
- Dynamic border (Blue=Detected/Oriented, Red=Not Found/Bad) following the face.
- Capture button (appears/disappears based on validity).
- Instructional messaging overlay (e.g., "Place your face in the center").

# Technical Notes (Architect)
- Use ML Kit `FaceDetection` to get bounding boxes and Euler angles for tracking.
- Implement a state notifier to update the UI border color and button visibility in real-time.
- Decouple this validation logic so it can be used for both attendance scanning and employee enrollment.
