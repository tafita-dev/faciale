---
id: US-07-SADM-003
title: End-to-End System Onboarding and Attendance Flow
status: READY
type: feature
---
# Description
As a Developer, I want to verify the complete system flow from Super Admin login to Employee attendance check-in so that I can ensure all components work together correctly.

# Context Map
> Reference @specs/context-map.md to find file paths.

# Acceptance Criteria (DoD)
- [ ] **Scenario 1: Complete Onboarding Flow**
    - Given I login as **Super Admin**
    - When I create an **Organization** (e.g., "Precity School")
    - And I login as the **Org Admin** for "Precity School"
    - And I create a **Department** (e.g., "Standard 1")
    - And I create an **Employee** (e.g., "Alice") and upload a reference photo
    - Then "Alice" should appear in the employee list.
- [ ] **Scenario 2: Successful Attendance Flow**
    - Given "Alice" is enrolled
    - When "Alice" uses the **Attendance Scanner**
    - And the backend confirms **Liveness** and **Matches** her face
    - Then the scanner should show "Success: Alice"
    - And the **Admin Dashboard** should show 1 "Present Today".
    - And the **Reports** should show the log for "Alice".

# Technical Notes (Architect)
- This is an integration verification story.
- Requires all backend services (FastAPI, MongoDB, Qdrant) and the Mobile app to be running.
- Can be verified manually or through a cross-platform integration test script.
