# UX/UI Design Specs

## 1. Global Layout & Theme
*   **Color Palette:**
    *   Primary: Deep Blue (`#0047AB`) - Used for primary buttons, headers, and active states.
    *   Background: Pure White (`#FFFFFF`) - Clean, medical/professional feel.
    *   Text: Black (`#000000`) - High contrast for readability.
    *   **Accents:** Light Grey (`#F5F5F5`) - Used for card backgrounds and input fields.
        *   **Neumorphic Shadows:**
            *   Light: `#FFFFFF` (Pure White).
            *   Dark: `#D1D9E6` (Soft Grey-Blue).
        *   **Feedback:** Success Green (`#28A745`), Error/Spoof Red (`#DC3545`), Warning Orange (`#FFC107`).
    *   **Typography:** Clean, sans-serif font (e.g., Roboto or Inter). Bold for headings, Regular for body.
    *   **Neumorphism (I-POINTEO Style):** 
        *   Cards and buttons use a "soft-extrusion" effect with dual shadows (light on top-left, dark on bottom-right).
        *   Concave (inset) style for active states or text input fields.
    *   **Navigation:**

    *   **Admin/Org Admin:** Persistent Bottom Navigation Bar (Dashboard, Employees, Reports, Profile).
    *   **Employee/Public (Scanning):** Immersive full-screen camera view with minimal overlay controls.

## 2. Screen Descriptions

### Screen: Login
*   **Route:** `/login`
*   **Elements:**
    *   **Logo:** Centered at the top (Modern, geometric face icon).
    *   **Input Fields:** Email and Password with Blue borders on focus.
    *   **Primary Button:** "Login" (Solid Blue with White text).
    *   **Text Link:** "Forgot password?" (Black, underlined).
*   **Interactions:**
    *   **Login Clicked:** Show loading spinner on button -> Redirect to Dashboard based on Role.
    *   **Invalid Credentials:** Shake animation on inputs + Red "Invalid email or password" snackbar.

### Screen: Attendance Scanner (The "Hero" Screen)
*   **Route:** `/scanner`
*   **Elements:**
    *   **Live Camera Preview:** Full-screen background.
    *   **Face Guide:** A semi-transparent Blue "Face Oval" overlay to guide the user's position.
    *   **Status Indicator:** Text at the bottom (e.g., "Align your face", "Hold still", "Analyzing...").
    *   **Liveness Feedback:** Minimalist Blue progress ring during liveness detection.
*   **Interactions:**
    *   **Face Detected:** Guide oval turns solid Blue -> Start processing.
    *   **Success:** Guide oval turns Green -> Sound "Beep" -> Show "Success: [Name] - [Timestamp]" card for 2 seconds -> Reset.
    *   **Spoof Detected:** Guide oval turns Red -> Show "Liveness failed. Please try again" message.
    *   **Not Recognized:** Guide oval turns Red -> "User not found".

### Screen: Organization Dashboard
*   **Route:** `/admin/dashboard`
*   **Elements:**
    *   **Summary Cards:** "Present Today", "Total Employees", "Late/Absent".
    *   **Quick Actions:** Floating Action Button (FAB) for "Quick Scan" or "Add Employee".
    *   **Real-time Feed:** Vertical list of the last 5 successful check-ins.
*   **Interactions:**
    *   **Card Tap:** Navigate to detailed list view of that category.

### Screen: Employee Enrollment
*   **Route:** `/admin/employee/enroll`
*   **Elements:**
    *   **Form:** Name, Department/Class dropdown.
    *   **Photo Capture Box:** Placeholder box with a "Capture Reference Photo" button.
    *   **Camera Preview (Dialog):** To take the reference photo.
*   **Interactions:**
    *   **Capture Clicked:** Opens camera -> User takes photo -> App shows "Image Quality Check" (Ensure face is clear).
    *   **Save Clicked:** Show "Generating Secure Identity..." loading state -> Redirect to Employee List on success.

### Screen: Advanced Reporting Dashboard
*   **Route:** `/admin/reports/analytics`
*   **Elements:**
    *   **Date Range Selector:** A horizontal scrollable bar or dropdown for "Last 7 Days", "Last 30 Days", "Custom".
    *   **Neumorphic Metric Cards:** 
        *   Layout: Three cards in a horizontal row (or grid on small screens).
        *   Content: Small icon, Label (e.g., "Avg. Punctuality"), and Large Value (e.g., "92%").
        *   Style: Deep Blue text for values, bold typography.
    *   **Line Chart (Trends):** 
        *   Card: Large Neumorphic container.
        *   X-Axis: Dates; Y-Axis: Attendance Count.
        *   Interaction: Tap a point to show a popup with "Date: [Date], Present: [Count]".
    *   **Doughnut Chart (Breakdown):**
        *   Colors: Green (Present), Orange (Late), Red (Absent).
        *   Center Label: Total "Expected" attendance for the period.
        *   Legend: Interactive labels that toggle visibility of segments.
    *   **Export Action:** A persistent Blue FAB with a "Download" icon.
*   **Interactions:**
    *   **Chart Drill-down:** 
        *   Tapping a segment in the Doughnut chart or a point in the Line chart navigates to the `/admin/reports` screen.
        *   The destination screen (Report View) must automatically apply filters (Status, Date) based on the clicked element.
    *   **Loading State:** Shimmer effect on cards and skeleton loaders for charts while data is being fetched from `/reports/analytics`.
    *   **Empty State:** "No data for this period" illustration and a "Change Date" button.
    *   **Filter Change:** Real-time update of all charts and metrics with a fade-in animation.

## 3. User Flows

### Flow 1: Daily Check-in (Employee)
1.  User launches app (already set to "Scan Mode" for shared tablet or personal device).
2.  Aligns face within the Blue Oval.
3.  System detects liveness and performs matching.
4.  Success animation + Name display.
5.  Ready for the next person automatically.

### Flow 2: Organization Setup (Admin)
1.  Super Admin logs in -> Creates Organization Account.
2.  Org Admin logs in -> Creates "Departments" (e.g., HR, Engineering).
3.  Org Admin adds "Employee" -> Enrolls their Face.
4.  Ready for attendance.

## 4. Error States & Edge Cases
*   **No Internet:** Persistent Red bar at the top: "Offline Mode - Records will sync when connected".
*   **Poor Lighting:** Floating toast: "Too dark. Please move to a brighter area".
*   **Multiple Faces:** System ignores detection until only one dominant face is in the oval.
