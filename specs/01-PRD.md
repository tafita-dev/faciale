# Product Requirement Document (PRD)

## 1. Functional Specifications

### Feature: Multi-level User Management
*   **Super Admin:** Can create and manage "Organization" accounts (Schools or Companies).
*   **Organization Admin:** Can create Departments (or Classes) and add Employees (or Students).
*   **Employee/Student Profile:** Includes name, department/class, and a high-quality reference image for facial recognition.

### Feature: Facial Enrollment
*   **Rule 1:** When an employee is created, the system must process their image to extract a facial embedding (128d or 512d vector).
*   **Rule 2:** Vectors must be stored in the Vector Database (Qdrant) with the `employee_id` as metadata.
*   **Rule 3:** Reference images must be stored securely (e.g., S3 or local encrypted storage).

### Feature: Attendance via Facial Recognition
*   **Rule 1:** The mobile app captures a live photo/video stream.
*   **Rule 2:** The backend MUST perform Liveness Detection (Passive or Active) to prevent spoofing (Deepfakes, photos of photos, video playbacks).
*   **Rule 3:** If liveness is confirmed, the system extracts the embedding and searches the Vector DB.
*   **Rule 4:** Attendance is recorded only if the similarity score is above a configurable threshold (e.g., 0.85).

### Feature: Attendance Reporting
*   **Rule 1:** Organization Admins can export attendance logs (CSV/PDF).
*   **Rule 2:** Dashboard shows real-time "Present" vs "Absent" statistics.

## 2. Data Dictionary
*   **Organization:** `id, name, type (school/company), created_at`
*   **Department/Class:** `id, org_id, name`
*   **Employee/Student:** `id, dept_id, name, embedding_id, status`
*   **AttendanceLog:** `id, employee_id, timestamp, confidence_score, status (success/failed)`

## 3. Non-Functional Requirements
*   **Performance:** Recognition must take less than 2 seconds (End-to-End).
*   **Scalability:** Optimized for 1,000+ employees with sub-linear search time in Vector DB.
*   **Security:** JWT-based authentication. Encryption of biometric data at rest.
*   **Visuals:** Modern UI using Blue (#0047AB), White (#FFFFFF), and Black (#000000).
