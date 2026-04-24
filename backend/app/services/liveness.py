import cv2
import numpy as np
import onnxruntime as ort
import os
from app.core.config import settings

class LivenessService:
    """
    Service for performing passive liveness detection using MiniFASNetV2.
    """
    
    def __init__(self, model_path: str = None):
        if model_path is None:
            # Default path relative to the project root
            model_path = os.path.join(
                os.path.dirname(os.path.dirname(__file__)), 
                "models", "liveness", "MiniFASNetV2.onnx"
            )
        
        if not os.path.exists(model_path):
            raise RuntimeError(f"Liveness model not found at {model_path}")
            
        # Initialize ONNX Runtime session
        # Using CPU for better compatibility in local/dev environments
        self.session = ort.InferenceSession(model_path, providers=['CPUExecutionProvider'])
        self.input_name = self.session.get_inputs()[0].name
        
    def _preprocess(self, img: np.ndarray, bbox: list = None) -> np.ndarray:
        """
        Preprocess the image for the liveness model.
        1. Crop the face using a scale factor (if bbox provided).
        2. Convert BGR to RGB.
        3. Resize to 80x80.
        4. Normalize using ImageNet stats.
        5. Convert to NCHW format.
        """
        if bbox:
            # bbox format: [x1, y1, x2, y2]
            x1, y1, x2, y2 = bbox
            w = x2 - x1
            h = y2 - y1
            
            # Crop scale (2.7 is recommended for MiniFASNetV2)
            scale = 2.7
            cx, cy = x1 + w / 2, y1 + h / 2
            side = max(w, h) * scale
            
            x1 = int(cx - side / 2)
            y1 = int(cy - side / 2)
            x2 = int(cx + side / 2)
            y2 = int(cy + side / 2)
            
            # Handle boundaries
            h_img, w_img = img.shape[:2]
            x1 = max(0, x1)
            y1 = max(0, y1)
            x2 = min(w_img, x2)
            y2 = min(h_img, y2)
            
            img = img[y1:y2, x1:x2]

        if img.size == 0:
            raise ValueError("Empty image after cropping")

        # Convert to RGB
        img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        
        # Resize to 80x80
        img = cv2.resize(img, (80, 80))
        
        # Normalize
        img = img.astype(np.float32) / 255.0
        mean = np.array([0.485, 0.456, 0.406], dtype=np.float32)
        std = np.array([0.229, 0.224, 0.225], dtype=np.float32)
        img = (img - mean) / std
        
        # HWC to CHW
        img = img.transpose(2, 0, 1)
        # Add batch dimension
        img = np.expand_dims(img, axis=0).astype(np.float32)
        
        return img

    def _softmax(self, x):
        e_x = np.exp(x - np.max(x))
        return e_x / e_x.sum(axis=1)

    def is_live(self, img: np.ndarray, bbox: list = None) -> dict:
        """
        Analyze the image and return a liveness result.
        Returns:
            dict: {"is_live": bool, "score": float}
        """
        try:
            processed_img = self._preprocess(img, bbox)
            
            # Inference
            outputs = self.session.run(None, {self.input_name: processed_img})
            logits = outputs[0]
            
            # Output is usually 3 classes: [Real, 2D-Fake, 3D-Fake]
            # Probabilities
            probs = self._softmax(logits)[0]
            
            real_score = float(probs[0])
            # Threshold for liveness (e.g., 0.5)
            # In production, this threshold should be tuned.
            is_live = real_score > 0.5
            
            return {
                "is_live": is_live,
                "score": real_score
            }
        except Exception as e:
            # For simplicity, return a safe "not live" on error or raise
            # Depending on desired behavior. Here we raise for better visibility during dev.
            raise RuntimeError(f"Liveness inference failed: {e}")
