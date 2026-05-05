---
id: US-12-BRAND-006-1
title: Mobile - Refined Organization List for Super Admin
status: DONE
type: feature
priority: MEDIUM
---

# Description

As a Super Admin, I want the Organization list to show specific fields (Name, Email, Logo) so that I have the most relevant information at a glance.

# Context Map

> Reference @specs/context-map.md to find file paths.
> Specific files for this story:
>
> - `mobile/lib/features/organizations/org_list_screen.dart`

# Acceptance Criteria (DoD)

- [ ] **Scenario 1: Super Admin Org List Fields**
  - Given I am logged in as Super Admin
  - When I view the Organizations list
  - Then each entry displays: Name, Email, and Logo.

# Technical Notes (Architect)

- Ensure the API response for organization list includes the email and logo fields.
- Update the UI card to display these three elements clearly.
