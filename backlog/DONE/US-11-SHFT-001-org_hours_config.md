---
id: US-11-SHFT-001
title: Organization - Work/School Hours Configuration
status: DONE
type: feature
priority: MEDIUM
---

# Description
As an Organization Admin, I want to configure the official start time and late threshold for my organization so that the system can automatically categorize attendance logs.

# Context Map
> Reference @specs/context-map.md to find file paths.
> Specific files for this story:
> * `backend/app/models/org.py`
> * `mobile/lib/features/organizations/`

# Acceptance Criteria (DoD)

- [x] **Scenario 1: Set work hours via Admin UI**
    - Given I am logged in as an Organization Admin
    - When I navigate to Organization Settings and set "Start Time" to "09:00" and "Late Buffer" to "15 minutes"
    - Then the settings are saved in MongoDB under the Organization document.
- [x] **Scenario 2: Validation of time format**
    - Given I am setting the start time
    - When I enter an invalid time format (e.g., "25:00" or "abc")
    - Then the system displays a validation error "Invalid time format".

# UI element
- Settings screen in the mobile app with TimePickers for Start Time and a numeric input for Late Buffer (minutes).

# Technical Notes (Architect)
- Update `Organization` model in MongoDB to include `settings: { start_time: string, late_buffer_minutes: int }`.
- Ensure the mobile UI follows the Neumorphism style established in Epic 10.

# Reviewer Feedback (Reviewer)
- [x] **Access Control Issue**: Fixed. `GET /orgs/{org_id}` now allows Org Admins to fetch their own details.
- [x] **Missing Business Logic Integration**: Fixed. `ReportingService.get_today_stats` now uses the organization's settings for "late" calculations.
- [x] **Consistency**: Verified that reports pull from new settings.
