---
id: US-15-ENR-003
title: Liveness Detection and Capture Modes
status: DONE
type: feature
---
# Description
As a Security-Conscious User, I want the system to perform local liveness checks (blink/movement) and allow me to choose between manual and automatic capture modes, so that the enrollment is secure and customized to my preference.

# Context Map
> Reference @specs/context-map.md
> Specific files for this story:
> * @mobile/lib/features/attendance/face_detector_service.dart
> * @mobile/lib/features/employees/enroll_screen.dart

# Acceptance Criteria (DoD)
- [ ] **Scenario 1:** [Happy Path - Liveness Validation]
    - Given a face is correctly positioned
    - When the scanner checks for blinks/micro-movements
    - Then the system validates liveness and allows the capture
- [ ] **Scenario 2:** [Happy Path - Automatic Capture Mode]
    - Given the user has selected 'Automatic' capture mode
    - When a valid face is detected, oriented correctly, and liveness check passes
    - Then the system automatically takes the picture without user input
- [ ] **Scenario 3:** [Error Case - Anti-Spoofing Failure]
    - Given a static photo or screen
    - When the scanner processes the frame
    - Then the system flags liveness failure and prevents image capture

# UI element
- Settings toggle for Capture Mode (Manual / Automatic).
- Visual feedback on the liveness status (e.g., progress ring around face).

# Technical Notes (Architect)
- Integrate eye-open probability and movement thresholds into the reusable scanner.
- Implement the capture mode state (Manual/Automatic) as a parameter.
- Ensure the capture button is programmatically controlled based on these local checks.
