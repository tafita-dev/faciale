import pytest
import numpy as np
import cv2
from app.services.liveness import LivenessService

def test_liveness_service_is_live_output_format():
    service = LivenessService()
    # Create a simple image
    img = np.zeros((100, 100, 3), dtype=np.uint8)
    cv2.rectangle(img, (25, 25), (75, 75), (255, 255, 255), -1)
    
    result = service.is_live(img)
    
    assert "is_live" in result
    assert "score" in result
    assert isinstance(result["is_live"], bool)
    assert isinstance(result["score"], float)

def test_liveness_service_blur_detection():
    service = LivenessService()
    
    # Sharp image (high variance)
    sharp_img = np.zeros((100, 100, 3), dtype=np.uint8)
    for i in range(0, 100, 2):
        sharp_img[i, :] = 255
        
    # Blurry image (low variance)
    blurry_img = cv2.GaussianBlur(sharp_img, (15, 15), 0)
    
    sharp_result = service.is_live(sharp_img)
    blurry_result = service.is_live(blurry_img)
    
    assert sharp_result["score"] > blurry_result["score"]
