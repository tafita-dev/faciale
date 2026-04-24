# UX/UI Design Specs

## 1. Global Layout & Theme
*   **Color Palette:**
    *   Primary: Deep Blue (`#0047AB`) - Used for primary buttons, headers, and active states.
    *   Background: Pure White (`#FFFFFF`) - Clean, medical/professional feel.
    *   Text: Black (`#000000`) - High contrast for readability.
    *   Accents: Light Grey (`#F5F5F5`) - Used for card backgrounds and input fields.
    *   Feedback: Success Green (`#28A745`), Error/Spoof Red (`#DC3545`).
*   **Typography:** Clean, sans-serif font (e.g., Roboto or Inter). Bold for headings, Regular for body.
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
