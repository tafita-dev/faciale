---
id: US-11-NOTIF-004-1
title: Backend - Notification Service & FCM Integration
status: DONE
type: feature
priority: LOW
---

# Description
As a Developer, I want to implement a Notification Service in the backend that integrates with Firebase Cloud Messaging (FCM) so that we can trigger push notifications.

# Context Map
> Reference @specs/context-map.md to find file paths.
> Specific files for this story:
> * `backend/app/services/notification.py`
> * `backend/app/models/user.py`

# Acceptance Criteria (DoD)

- [x] **Scenario 1: FCM Integration**
    - Given a valid FCM server key/credentials
    - When the `NotificationService` is called to send a message
    - Then the request is successfully sent to FCM.
- [x] **Scenario 2: Trigger on Late Arrival**
    - Given an employee is flagged as "Late" during attendance scan
    - When the attendance is saved
    - Then the `NotificationService` is triggered for the Organization Admin.

# Technical Notes (Architect)
- Integrate `firebase-admin` Python SDK.
- Store Admin's FCM registration tokens in MongoDB `User` document (ensure model supports it).
- Create a `NotificationService` to handle logic.
- **Added endpoints:** `POST /api/v1/auth/fcm-token` and `DELETE /api/v1/auth/fcm-token` to manage user device tokens.
