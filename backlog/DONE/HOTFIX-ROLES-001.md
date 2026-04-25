---
id: HOTFIX-ROLES-001
title: Fix roles and permissions for attendance system
status: DONE
type: hotfix
---
# Description
Emergency hotfix to correct role hierarchy and permissions:
- Superadmin: Only organization list, no access to employees or logs.
- Admin: Organization data isolation, sees all employees/logs in org, filter by user/dept/date.
- User: Sees only their own employees and recorded logs.

# Acceptance Criteria (DoD)
- [x] Superadmin cannot access employee list or attendance logs.
- [x] Superadmin can list organizations.
- [x] Admin can filter attendance logs by user_id.
- [x] User can only see employees they created.
- [x] User can only see attendance logs they recorded.
- [x] Attendance logs track user_id on both check-in and check-out.

# Technical Notes
- Modified `ReportingService` to restrict superadmin stats.
- Modified `reports.py` to allow user_id filtering for admins.
- Modified `AttendanceService` to record user_id on session close.
- Verified isolation in `employees.py` and `attendance.py`.
