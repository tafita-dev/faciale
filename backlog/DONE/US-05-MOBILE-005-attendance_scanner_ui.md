---
id: US-05-MOBILE-005
title: Attendance Scanner UI (Hero Screen)
status: DONE
type: feature
---
# Description
As a User, I want an immersive camera view with visual guides so that I can easily align my face for automatic attendance check-in.

# Context Map
> Reference @specs/context-map.md to find file paths.
> Specific files for this story:
> * `mobile/lib/features/attendance/scanner_screen.dart`

# Acceptance Criteria (DoD)
- [x] **Scenario 1: Face Alignment Guide**
    - Given the Scanner is active
    - Then I should see a semi-transparent Blue "Face Oval" overlay centered on the screen.
- [x] **Scenario 2: Visual Feedback during Matching**
    - Given a face is detected within the oval
    - When the system starts processing
    - Then the guide oval should turn solid Blue
    - And a Blue progress ring should appear.
- [x] **Scenario 3: Success Feedback**
    - Given a successful match
    - Then the guide oval should turn Green
    - And a card should appear for 2 seconds showing: "Success: [Name] - [Timestamp]".
- [x] **Scenario 4: Failure/Spoof Feedback**
    - Given a liveness failure or no match
    - Then the guide oval should turn Red
    - And a descriptive error message should appear.

# UI element
- Camera Preview (Background)
- Face Oval Overlay (Custom Painter)
- Status Indicator (Text overlay)
- Success Card

# Technical Notes (Architect)
- Full-screen mode (hide status/nav bars).
- Optimize frame capture rate to balance battery life and recognition speed.
- Use `camera` package with `image_stream` for real-time processing.
- Sound feedback: Beep on success.
