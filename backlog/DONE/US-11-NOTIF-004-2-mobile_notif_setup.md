---
id: US-11-NOTIF-004-2
title: Mobile - Push Notification Setup & Registration
status: DONE
type: feature
priority: LOW
---

# Description
As an Admin, I want the app to register for push notifications and receive them when in the background so that I stay informed.

# Context Map
> Reference @specs/context-map.md to find file paths.
> Specific files for this story:
> * `mobile/android/`
> * `mobile/ios/`
> * `mobile/lib/core/services/notification_service.dart`

# Acceptance Criteria (DoD)

- [x] **Scenario 1: Token Registration**
    - Given the app starts
    - When the user is logged in
    - Then the app obtains an FCM token and sends it to the backend.
- [x] **Scenario 2: Background Notification Delivery**
    - Given the app is in the background or device is locked
    - When a push notification is sent by the backend
    - Then a system notification is displayed on the device.

# Technical Notes (Architect)
- Use `firebase_messaging` Flutter package.
- Configure Android (google-services.json) and iOS (GoogleService-Info.plist).
- Request notification permissions from the user.
