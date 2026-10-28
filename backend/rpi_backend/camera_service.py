"""
Camera Service
Handles Raspberry Pi camera operations for copra image capture.

Features:
- Capture images with timestamp filenames
- Save with batch_id association
- Configurable image quality and resolution
- Error handling and retry logic
"""

import io
import logging
import os
import threading
from datetime import datetime
from typing import Optional
from picamera2 import Picamera2
from PIL import Image


class CameraService:
    """
    Service for capturing images from Raspberry Pi camera.
    """
    
    def __init__(self, 
                 output_dir: str = "images",
                 resolution: tuple = (1920, 1080),
                 quality: int = 95):
        """
        Initialize camera service.
        
        Args:
            output_dir: Directory to save captured images
            resolution: Image resolution (width, height)
            quality: JPEG quality (1-100)
        """
        self.output_dir = output_dir
        self.resolution = resolution
        self.quality = quality
        self.camera = None
        self._camera_lock = threading.Lock()
        
        # Create output directory if it doesn't exist
        os.makedirs(output_dir, exist_ok=True)
        
        logging.info(f"Camera service initialized (output_dir={output_dir}, "
                    f"resolution={resolution}, quality={quality})")
    
    def initialize(self):
        """Initialize camera hardware."""
        try:
            self.camera = Picamera2()
            
            # Configure camera
            config = self.camera.create_still_configuration(
                main={"size": self.resolution}
            )
            self.camera.configure(config)
            
            # Start camera
            self.camera.start()
            
            logging.info("Camera initialized and started")
            
        except Exception as e:
            logging.error(f"Failed to initialize camera: {e}")
            raise
    
    def capture_image(self, 
                     filename: Optional[str] = None,
                     batch_id: Optional[str] = None) -> str:
        """
        Capture image from camera.
        
        Args:
            filename: Custom filename (default: timestamp-based)
            batch_id: Batch identifier to include in path
            
        Returns:
            str: Full path to captured image
            
        Raises:
            RuntimeError: If camera not initialized or capture fails
        """
        if not self.camera:
            raise RuntimeError("Camera not initialized. Call initialize() first.")
        
        try:
            # Generate filename if not provided
            if not filename:
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                filename = f"{timestamp}.jpg"
            
            # Ensure filename has .jpg extension
            if not filename.lower().endswith('.jpg'):
                filename += '.jpg'
            
            # Build file path
            if batch_id:
                # Save in batch-specific subdirectory
                batch_dir = os.path.join(self.output_dir, batch_id)
                os.makedirs(batch_dir, exist_ok=True)
                filepath = os.path.join(batch_dir, filename)
            else:
                filepath = os.path.join(self.output_dir, filename)
            
            # Serialize preview and saved captures on the shared camera instance.
            logging.info(f"Capturing image: {filepath}")
            with self._camera_lock:
                self.camera.capture_file(filepath)
            
            # Verify file was created
            if not os.path.exists(filepath):
                raise RuntimeError(f"Image file not created: {filepath}")
            
            # Verify file size (should be > 0)
            file_size = os.path.getsize(filepath)
            if file_size == 0:
                raise RuntimeError(f"Captured image is empty: {filepath}")
            
            logging.info(f"Image captured successfully: {filepath} ({file_size} bytes)")
            
            return filepath
            
        except Exception as e:
            logging.error(f"Failed to capture image: {e}")
            raise
    
    def get_preview_frame(self) -> bytes:
        """Return one JPEG frame in memory without saving or classifying it."""
        if not self.camera:
            raise RuntimeError("Camera not initialized")

        output = io.BytesIO()
        with self._camera_lock:
            if not self.camera:
                raise RuntimeError("Camera not initialized")
            self.camera.capture_file(output, format="jpeg")

        frame = output.getvalue()
        if not frame:
            raise RuntimeError("Camera returned an empty preview frame")
        return frame

    def capture_with_retry(self,
                          filename: Optional[str] = None,
                          batch_id: Optional[str] = None,
                          max_retries: int = 3,
                          retry_delay: float = 1.0) -> Optional[str]:
        """
        Capture image with automatic retry on failure.
        
        Args:
            filename: Custom filename
            batch_id: Batch identifier
            max_retries: Maximum number of retry attempts
            retry_delay: Delay between retries in seconds
            
        Returns:
            str: Path to captured image or None if all retries fail
        """
        import time
        
        for attempt in range(1, max_retries + 1):
            try:
                filepath = self.capture_image(filename=filename, batch_id=batch_id)
                return filepath
            except Exception as e:
                logging.warning(f"Capture attempt {attempt}/{max_retries} failed: {e}")
                
                if attempt < max_retries:
                    logging.info(f"Retrying in {retry_delay} seconds...")
                    time.sleep(retry_delay)
                else:
                    logging.error(f"All {max_retries} capture attempts failed")
                    return None
    
    def get_camera_info(self) -> dict:
        """
        Get camera information and status.
        
        Returns:
            dict: Camera information
        """
        if not self.camera:
            return {
                'initialized': False,
                'status': 'not_initialized'
            }
        
        try:
            return {
                'initialized': True,
                'status': 'ready',
                'resolution': self.resolution,
                'quality': self.quality,
                'output_dir': self.output_dir
            }
        except Exception as e:
            return {
                'initialized': True,
                'status': 'error',
                'error': str(e)
            }
    
    def close(self):
        """Stop and close camera."""
        if self.camera:
            try:
                self.camera.stop()
                self.camera.close()
                self.camera = None
                logging.info("Camera stopped and closed")
            except Exception as e:
                logging.error(f"Error closing camera: {e}")
    
    def __enter__(self):
        """Context manager entry."""
        self.initialize()
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit."""
        self.close()
