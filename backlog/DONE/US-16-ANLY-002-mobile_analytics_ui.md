---
id: US-16-ANLY-002
title: Mobile - Analytics Dashboard UI
status: DONE
type: feature
---

# Description
As an Admin, I want to see visual representations of attendance data so that I can quickly identify patterns and issues.

# Context Map
> Reference @specs/context-map.md to find file paths.
> Specific files for this story:
> *   `mobile/lib/features/reports/analytics_screen.dart`

# Acceptance Criteria (DoD)

- [x] **Scenario 1: Metric Cards Display**
    - Given the analytics data is loaded
    - Then I see cards for Average Punctuality, Peak Arrival Time, and Total Hours.
    - And they follow the "I-POINTEO" Neumorphic design style.

- [x] **Scenario 2: Visual Charts**
    - Given the analytics data is loaded
    - Then I see a Line Chart showing daily attendance trends.
    - And I see a Doughnut Chart showing the status breakdown (Present, Late, Absent).

# UI element
- Neumorphic Metric Cards (Deep Blue text on Light Grey background).
- Line Chart (using `fl_chart` or similar).
- Status Doughnut Chart with color coding: Green (Present), Orange (Late), Red (Absent).

# Technical Notes (Architect)
- Use `fl_chart` for data visualization.
- Ensure the screen is responsive and handles different screen sizes gracefully.

# Reviewer Feedback
- **UI Quality**: Excellent implementation of the "I-POINTEO" Neumorphic style. The `NeumorphicCard` is used consistently for both metrics and chart containers.
- **Data Visualization**: `fl_chart` integration is clean. The Doughnut chart correctly uses the Success Green, Orange, and Error Red colors for the status breakdown.
- **Routing**: The sub-route `/reports/analytics` is correctly configured and the entry point in `ReportsScreen` is appropriately gated for Admin users.
- **Testing**: Passing widget tests confirm that the charts and cards are correctly rendered with the provided state.

**Approved for merging.**
