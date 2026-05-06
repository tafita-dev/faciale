---
id: US-13-ATT-005
title: Mobile - Scanner Mode Selection (Auto/Entry/Exit)
status: DONE
type: feature
---

# Description
As an Admin, I want to select the scanning mode (Auto, Entry Only, Exit Only) in the scanner screen so that I can configure the device based on its physical location (e.g., at an entrance gate or exit gate).

# Context Map
> Reference @specs/context-map.md to find file paths.
> Specific files for this story:
> *   `mobile/lib/features/attendance/scanner_screen.dart`
> *   `mobile/lib/features/attendance/scanner_state.dart`

# Acceptance Criteria (DoD)

- [x] **Scenario 1: Default to Auto Mode**
    - Given the scanner screen is opened for the first time
    - Then the current mode is "Auto"
    - And the UI shows an "Auto" indicator

- [x] **Scenario 2: Switch to Entry Only**
    - Given the scanner screen is open
    - When I tap on the mode selector and choose "Entry Only"
    - Then the current mode updates to "Entry Only"
    - And all subsequent scans sent to the backend include the `force_type=entry` parameter

- [x] **Scenario 3: Switch to Exit Only**
    - Given the scanner screen is open
    - When I tap on the mode selector and choose "Exit Only"
    - Then the current mode updates to "Exit Only"
    - And all subsequent scans sent to the backend include the `force_type=exit` parameter

- [x] **Scenario 4: UI Persistence**
    - Given I have selected "Exit Only" mode
    - When I leave the scanner screen and come back
    - Then the mode "Exit Only" is still selected (using local state or provider)

# UI element
- Mode Selector Toggle/Dropdown in the scanner screen (discreet but accessible).
- Mode Status Indicator (e.g., "Mode: Auto").

# Technical Notes (Architect)
- Update `ScannerState` to include `scanningMode` (enum: auto, entry, exit).
- Update `AttendanceRepository.checkIn` to accept an optional `forceType`.
- Add a small Neumorphic toggle or icon in the `ScannerScreen` to switch modes.
