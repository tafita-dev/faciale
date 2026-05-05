---
id: US-11-NOTIF-004-3
title: Mobile - Push Notification Action & Navigation
status: READY
type: feature
priority: LOW
---

# Description
As an Admin, I want to be taken to the relevant details when I tap a push notification so that I can quickly act on the information.

# Context Map
> Reference @specs/context-map.md to find file paths.
> Specific files for this story:
> * `mobile/lib/main.dart`
> * `mobile/lib/features/attendance/attendance_log_details_screen.dart`

# Acceptance Criteria (DoD)

- [ ] **Scenario 1: Notification Action**
    - Given I receive a "Late Arrival" push notification
    - When I tap the notification
    - Then the app opens (or brings to front) and navigates directly to the Attendance Log details for that entry.

# Technical Notes (Architect)
- Implement deep linking or notification data handling in `FirebaseMessaging.onMessageOpenedApp`.
- Pass the attendance log ID in the FCM data payload.
