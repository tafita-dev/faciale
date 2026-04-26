---
id: US-09-POL-004
title: Mobile Error Handling and UI Polish
status: DONE
type: feature
---
# Description
As an Employee or Admin, I want the mobile application to provide clear feedback and graceful handling of network errors or facial recognition failures so that I understand what went wrong and how to fix it.

# Context Map
- Mobile: `mobile/lib/core/network/`
- Mobile: `mobile/lib/features/attendance/scan_screen.dart`
- Mobile: `mobile/lib/features/auth/login_screen.dart`

# Acceptance Criteria (DoD)
- [ ] **Scenario 1: Offline Detection**
    - Given the device loses internet connectivity
    - When the app is active
    - Then a "No Connection" bar or message should be displayed, and network-dependent actions should be disabled.
- [ ] **Scenario 2: API Error Feedback**
    - Given a network request fails (e.g., 500 server error)
    - When the user is performing an action (Login, Scan)
    - Then a user-friendly SnackBar or Alert should be shown instead of a raw error or crash.
- [ ] **Scenario 3: Recognition Failure Guidance**
    - Given the facial recognition fails (low confidence or spoof detected)
    - When the user is at the scanner
    - Then the app should provide helpful advice (e.g., "Move to a brighter area", "Hold still") based on the error detail.

# Technical Notes (Architect)
- Implement a global network listener or use `connectivity_plus`.
- Wrap API calls with try-catch and map backend error codes to localized user-friendly messages.
- Improve the `scan_screen.dart` feedback loop using the status messages from the backend.
