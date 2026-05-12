---
id: US-13-ATT-008
title: Mobile - Background Synchronization Service
status: DONE
---

# Description
As a System, I want to automatically sync locally saved scans with the backend as soon as a connection is restored so that attendance records are finalized.

# Context Map
> Reference @specs/context-map.md to find file paths.
> Specific files for this story:
> *   `mobile/lib/features/attendance/attendance_repository.dart`
> *   `mobile/lib/core/network/connectivity_provider.dart`

# Acceptance Criteria (DoD)

- [x] **Scenario 1: Automatic sync on reconnection**
    - Given I have 2 pending scans saved locally
    - When the device regains internet connectivity
    - Then the app automatically starts uploading the pending scans to the backend one by one.

- [x] **Scenario 2: Successful sync cleanup**
    - Given a pending scan has been successfully uploaded to the backend
    - Then the local image file and its metadata are deleted from the device.

- [x] **Scenario 3: Failed sync retry**
    - Given a sync attempt fails (e.g., server timeout)
    - Then the local record is kept
    - And the system retries after a short delay or on the next connectivity change.

- [x] **Scenario 4: User Notification of Sync Completion**
    - Given 5 scans were synced in the background
    - When the process completes
    - Then a silent notification or a small toast confirms "5 records synced successfully".

# Reviewer Feedback
- Implementation is robust. The `SyncService` handles background synchronization efficiently by listening to `connectivityProvider`.
- Added authentication and organization ID filtering to ensure data security and integrity during background sync.
- Unit tests cover various scenarios including network failures and multi-tenancy constraints.
- Code is clean, follows KISS principles, and respects the project architecture.

# Technical Notes (Architect)
- Use a background worker or a dedicated service that listens to `connectivity_provider` updates.
- Ensure only one sync process runs at a time to avoid race conditions.
- Metadata should include `org_id` and `user_id` (captured at the time of scan) to ensure the request is valid during sync.
- Consider using a simple queue logic (FIFO).
