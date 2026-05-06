---
id: US-13-ATT-002
title: Frontend Liveness and Anti-Spoofing Detection
status: DONE
type: feature
---
# Description
As a Security-Conscious User, I want the application to perform liveness and anti-spoofing checks locally on my device, so that my attendance record is verified for authenticity without relying on backend liveness calls.

# Context Map
> Reference @specs/context-map.md
> Specific files for this story:
> *   @mobile/lib/features/attendance/face_detector_service.dart
> *   @mobile/lib/features/attendance/scanner_state.dart

# Acceptance Criteria (DoD)
- [ ] **Scenario 1:** [Happy Path - Liveness Validated]
    - Given a face is detected and liveness criteria (e.g., movement/blinking) are met
    - When the scanner processes the data locally
    - Then the system proceeds to initiate the attendance API call
- [ ] **Scenario 2:** [Error Case - Anti-Spoofing Failure]
    - Given a static image or a non-live source is presented
    - When the scanner performs local liveness/anti-spoofing checks
    - Then the system blocks the API call and displays a 'Liveness Check Failed' message
- [ ] **Scenario 3:** [Edge Case - Low Quality Detection]
    - Given a face is detected but image quality is too low for reliable liveness check
    - When the scanner processes the frame
    - Then the system asks the user to move to a better-lit area and does not call the API

# UI element
- Instructional text on the scanner screen (e.g., "Blink your eyes", "Move closer").
- Status indicator changes upon successful local validation.

# Technical Notes (Architect)
- Use ML Kit face landmarks (eye open probability) to determine liveness.
- Implement basic anti-spoofing heuristics (e.g., checking for unnatural static image artifacts or brightness distribution if necessary).
- Ensure this logic runs *before* the API call for identification.
