---
id: US-13-ATT-007
title: Mobile - Offline Scan Local Storage
status: DONE
---

# Description
As a User, I want the app to save my scan locally when there is no internet connection so that I don't lose my attendance record.

# Context Map
> Reference @specs/context-map.md to find file paths.
> Specific files for this story:
> *   `mobile/lib/features/attendance/attendance_repository.dart`
> *   `mobile/lib/core/network/connectivity_provider.dart`

# Acceptance Criteria (DoD)

- [x] **Scenario 1: Scan while offline**
    - Given the device has no internet connection
    - When I perform a scan
    - Then the app saves the image file and the timestamp locally
    - And the UI shows a "Scan saved locally (Offline)" message in the result modal.

- [x] **Scenario 2: Visual indicator for pending sync**
    - Given I have 3 scans saved locally that are not yet synced
    - When I am on the scanner screen
    - Then a small indicator (e.g., "3 pending scans") is visible.

- [x] **Scenario 3: Error handling during local save**
    - Given the device storage is full
    - When I attempt an offline scan
    - Then the app shows an error: "Storage full. Scan could not be saved."

# Technical Notes (Architect)
- Use `path_provider` to find a directory to store pending images.
- Use `shared_preferences` or a simple JSON file to track metadata of pending scans (timestamp, image path, forced mode).
- Integrate with `connectivity_provider` to detect offline status before attempting the HTTP call.
- The `AttendanceRepository` should handle the branching logic: `if (offline) saveLocally() else upload()`.

# Reviewer Feedback
- All issues addressed. Image persistence now uses `getApplicationDocumentsDirectory()`. Storage full error handling is implemented in the file copy operation. UI changes are aligned with the new design language.

