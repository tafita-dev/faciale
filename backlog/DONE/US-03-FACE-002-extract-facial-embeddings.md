---
id: US-03-FACE-002
title: Extract Facial Embeddings
status: DONE
type: feature
---
# Description
As a System, I want to process an uploaded employee photo to detect the face and extract a high-dimensional embedding so that it can be used for biometric matching.

# Context Map
> Reference @specs/context-map.md
> Specific files for this story:
> * `backend/app/services/enrollment.py`
> * `backend/app/services/recognition.py` (Reuse logic if any)

# Acceptance Criteria (DoD)
- [x] **Scenario 1: Single Face Detected**
    - Given an uploaded image with one clear face
    - When the system processes the image
    - Then it should successfully extract a 512-dimension vector (embedding)
- [x] **Scenario 2: No Face Detected**
    - Given an uploaded image with no recognizable face
    - When the system processes the image
    - Then it should return an error "No face detected in the image"
- [x] **Scenario 3: Multiple Faces Detected**
    - Given an uploaded image with 3 people's faces
    - When the system processes the image
    - Then it should return an error "Multiple faces detected. Please upload a photo with only one person"

# Technical Notes (Architect)
- Use `InsightFace` (ArcFace) for embedding extraction.
- The embedding must be a 512d float array.
- Handle `cv2` image loading and preprocessing (resize/normalize).
