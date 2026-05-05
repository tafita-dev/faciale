---
id: US-11-NOTIF-003
title: Dashboard - Real-time Admin Scan Notifications
status: DONE
type: feature
priority: MEDIUM
---

# Description
As an Organization Admin, I want to see real-time in-app notifications of facial scans so that I can monitor building entry/exit without manually refreshing the dashboard.

# Context Map
> Reference @specs/context-map.md to find file paths.
> Specific files for this story:
> * `backend/app/api/v1/endpoints/attendance.py`
> * `mobile/lib/features/dashboard/`

# Acceptance Criteria (DoD)

- [ ] **Scenario 1: Scan Success Notification**
    - Given I am on the Dashboard as an Admin
    - When an employee successfully checks in
    - Then a snackbar or top-toast appears saying "Success: [Name] checked in (Present)".
- [ ] **Scenario 2: Scan Failure/Spoof Alert**
    - Given I am on the Dashboard
    - When a scan fails due to spoofing or unknown user
    - Then a red alert notification appears with details.

# Technical Notes (Architect)
- Since we don't have WebSockets yet, consider implementing a simple polling mechanism (every 10s) on the Dashboard for admins or use Firebase Cloud Messaging (FCM) for real-time delivery if requested.
- For this story, start with a "Recent Activity" stream update that triggers a UI toast.
