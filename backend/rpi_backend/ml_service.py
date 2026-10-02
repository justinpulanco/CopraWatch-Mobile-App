"""
Machine Learning Service for Raspberry Pi
Handles copra quality classification using TensorFlow Lite
"""
import os
import numpy as np
from PIL import Image
import ai_edge_litert.interpreter as tflite
from datetime import datetime


class MLService:
    """ML Service for copra classification on Raspberry Pi"""
    
    def __init__(self, model_path="copra_quality_model.tflite", labels_path="labels.txt"):
        self.model_path = model_path
        self.labels_path = labels_path
        self.interpreter = None
        self.input_details = None
        self.output_details = None
        self.labels = []
        self.input_size = 224
        
    def load_model(self):
        """Load TensorFlow Lite model and labels"""
        try:
            # Load TensorFlow Lite model
            self.interpreter = tflite.Interpreter(model_path=self.model_path)
            self.interpreter.allocate_tensors()
            
            # Get input and output details
            self.input_details = self.interpreter.get_input_details()
            self.output_details = self.interpreter.get_output_details()
            
            print(f"Model loaded successfully: {self.model_path}")
            print(f"Input shape: {self.input_details[0]['shape']}")
            print(f"Output shape: {self.output_details[0]['shape']}")
            
            # Load labels
            if os.path.exists(self.labels_path):
                with open(self.labels_path, 'r') as f:
                    self.labels = [line.strip() for line in f.readlines() if line.strip()]
                print(f"Loaded {len(self.labels)} labels: {self.labels}")
            else:
                # Default labels if file doesn't exist
                self.labels = ["Under-dried", "Optimally-dried", "Over-dried"]
                print("Using default labels")
                
            return True
            
        except Exception as e:
            print(f"Error loading model: {e}")
            return False
    
    def preprocess_image(self, image_path):
        """Preprocess image for model input (optimized)"""
        try:
            # Load and resize image efficiently
            image = Image.open(image_path)
            image = image.convert('RGB')
            
            # Use LANCZOS for better quality, but limit size
            image = image.resize((self.input_size, self.input_size), Image.LANCZOS)
            
            # Convert to numpy array and normalize efficiently
            image_array = np.array(image, dtype=np.float32)
            image_array = image_array / 255.0  # Normalize to [0,1]
            
            # Add batch dimension
            image_array = np.expand_dims(image_array, axis=0)
            
            return image_array
            
        except Exception as e:
            print(f"Error preprocessing image: {e}")
            return None
    
    def classify_image(self, image_path):
        """Classify copra image (optimized for speed)"""
        try:
            if self.interpreter is None:
                print("Loading model for first time...")
                if not self.load_model():
                    return None
            
            # Fast preprocessing
            start_time = datetime.now()
            input_data = self.preprocess_image(image_path)
            if input_data is None:
                return None
            
            # Run inference
            self.interpreter.set_tensor(self.input_details[0]['index'], input_data)
            self.interpreter.invoke()
            
            # Get output quickly
            output_data = self.interpreter.get_tensor(self.output_details[0]['index'])
            predictions = output_data[0]  # Remove batch dimension
            
            # Get predicted class and confidence
            predicted_class_idx = np.argmax(predictions)
            confidence = float(predictions[predicted_class_idx])
            
            # VALIDATION: Check if confidence is reasonable for copra
            if confidence < 0.5:  # Very low confidence = definitely not copra
                return {
                    "classification": "❌ No Copra Detected",
                    "confidence": confidence,
                    "error": "Image does not appear to contain copra coconut",
                    "all_predictions": {}
                }
            
            # Additional check: if all predictions are similar, likely not copra
            predictions_sorted = np.sort(predictions)
            if (predictions_sorted[-1] - predictions_sorted[-2]) < 0.15:  # Very close predictions = uncertain
                return {
                    "classification": "❌ Unclear Image Quality",
                    "confidence": confidence,
                    "error": "Please capture clearer image of copra coconut",
                    "all_predictions": {}
                }
            
            # Medium confidence check
            if confidence < 0.75:  # Medium confidence = might be copra but unclear
                return {
                    "classification": "⚠️ Poor Image Quality",
                    "confidence": confidence,
                    "error": "Copra detected but image quality is poor. Try better lighting or closer shot.",
                    "all_predictions": {}
                }
            
            # Get class label (remove number prefix)
            if predicted_class_idx < len(self.labels):
                predicted_class = self.labels[predicted_class_idx]
                # Remove "0 ", "1 ", "2 " prefix if exists
                if ' ' in predicted_class:
                    predicted_class = predicted_class.split(' ', 1)[1]
            else:
                predicted_class = f"Class_{predicted_class_idx}"
            
            result = {
                "classification": predicted_class,
                "confidence": confidence,
                "all_predictions": {
                    self.labels[i].split(' ', 1)[1] if ' ' in self.labels[i] else self.labels[i]: float(predictions[i]) 
                    for i in range(min(len(predictions), len(self.labels)))
                }
            }
            
            duration = (datetime.now() - start_time).total_seconds()
            print(f"ML inference completed in {duration:.3f} seconds: {result['classification']} ({result['confidence']:.3f})")
            
            return result
            
        except Exception as e:
            print(f"Error during classification: {e}")
            import traceback
            traceback.print_exc()
            return None
    
    def get_model_info(self):
        """Get model information"""
        if self.interpreter is None:
            return None
            
        return {
            "model_path": self.model_path,
            "input_shape": self.input_details[0]['shape'].tolist(),
            "output_shape": self.output_details[0]['shape'].tolist(),
            "labels": self.labels,
            "input_size": self.input_size
        }