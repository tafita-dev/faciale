---
id: US-16-ANLY-003
title: Mobile - Analytics Filtering & Date Range
status: READY
type: feature
---

# Description
As an Admin, I want to filter the dashboard by date and department so that I can analyze specific subsets of my data.

# Context Map
> Reference @specs/context-map.md to find file paths.
> Specific files for this story:
> *   `mobile/lib/features/reports/analytics_screen.dart`
> *   `mobile/lib/features/reports/analytics_provider.dart`

# Acceptance Criteria (DoD)

- [ ] **Scenario 1: Custom Date Range**
    - When I select a custom date range using the picker
    - Then the dashboard UI shows a loading state
    - And refreshes with data specific to that range.

- [ ] **Scenario 2: Department Filter**
    - When I select a specific department from the dropdown
    - Then the analytics update to reflect only that department's employees.

- [ ] **Scenario 3: Persistence**
    - Given I have set a filter
    - When I navigate away and back to the analytics screen
    - Then my filters are preserved during the session.

# UI element
- Date Range Picker (Standard Material or custom I-POINTEO style).
- Department Dropdown (Searchable if many departments).

# Technical Notes (Architect)
- Use a Riverpod `StateProvider` or `Notifier` to manage the `AnalyticsFilter` state.
- Preserving filters can be done in-memory via the provider.
