---
id: US-10-ENH-007
title: Global - Neumorphism UI Implementation (Enhanced UX for Facial Recognition Attendance)
status: DONE
type: feature
priority: HIGH
---

# Description

As a User, I want a modern, intuitive, and visually appealing interface using Neumorphism so that the facial recognition attendance experience feels fast, high-tech, and trustworthy.

---

# Context Map

- Mobile: `mobile/lib/core/theme.dart`
- Mobile: `mobile/lib/core/widgets/neumorphic_card.dart`

---

# UX/UI Enhancements (Added)

## 🎯 Vision

The application must feel:

- High-tech (AI / facial recognition)
- Fast and responsive
- Secure and reliable
- Extremely simple (minimal user actions)

---

## 🎥 Facial Recognition Experience (Core UX)

- Add a **central circular scan area** (camera focus)
- Include **subtle animation (pulse / glow)** during scanning
- Provide **instant feedback**:
  - Success → green highlight + confirmation message
  - Failure → red highlight + retry message
- Display clear instructions:
  - “Regardez la caméra”
  - “Scan en cours...”

---

## 🎨 Neumorphism Design Guidelines

- Maintain soft UI with **dual shadows (light + dark)**
- Use:
  - Raised effect → buttons, cards
  - Inset effect → inputs, scan frame

### Color Palette (unchanged but enforced)

- Blue (#3A7DFF)
- White (#F5F7FA)
- Black (#1C1C1E)

---

## ⚡ Micro-Interactions (New)

- Button press animation (scale down slightly)
- Smooth transitions (200–300ms)
- Optional vibration feedback on success/failure
- Subtle hover/tap feedback

---

## 📊 Dashboard UX Improvement (Non-breaking)

- Display:
  - Last check-in / check-out time
  - Status (Présent / En retard / Absent)
- Use neumorphic cards for data blocks
- Keep layout clean and readable

---

## 💡 Advanced UX Idea (Added)

- Add a **“AI scanning effect”**:
  - Animated lines or radar effect over face scan area
  - Circular progress glow while scanning
- Purpose: reinforce high-tech perception

---

## 🔐 Security UX (Optional but Recommended)

- Auto-lock screen after inactivity
- Require re-scan for sensitive actions
- Optional blur screen when app is backgrounded

---

# Acceptance Criteria (DoD)

## Scenario 1: Neumorphic Buttons

- Given any screen with buttons
- Then:
  - Buttons must have dual shadows (light + dark)
  - Buttons must show pressed effect on tap
  - Buttons must include smooth animation

---

## Scenario 2: Thematic Consistency

- Given the app uses the Blue/White/Black palette
- Then:
  - All elements must follow neumorphic style
  - UI must remain consistent across all screens
  - Contrast must remain accessible

---

## Scenario 3: Facial Scan UX

- Given user opens the scan screen
- Then:
  - A central neumorphic circular scan area must be visible
  - A scanning animation must be displayed
  - Real-time feedback must be shown (success/failure)

---

## Scenario 4: Micro-Interactions

- Given user interacts with UI
- Then:
  - Animations must be smooth (200–300ms)
  - Feedback must be visible on all interactions

---

# Technical Notes (Architect)

- Use custom `BoxDecoration` with multiple `BoxShadow` (light and dark) to achieve the effect
- Create reusable widgets:
  - `NeumorphicCard`
  - `NeumorphicButton`
- Ensure performance is optimized for mobile devices (avoid heavy shadows)

---

# Non-Functional Requirements (Added)

- UI must remain responsive on all screen sizes
- Animations must not block user interaction
- Maintain performance (no lag during face scan)
