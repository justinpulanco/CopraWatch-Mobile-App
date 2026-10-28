"""
Automated Capture Workflow
Orchestrates the complete image capture and classification pipeline.

Workflow:
1. Get active batch ID
2. Capture image from camera
3. Save to dataset with timestamp
4. Run ML classification
5. Update batch record
6. Provide feedback
"""

import logging
from datetime import datetime
from typing import Optional, Dict, Any
import os


class CaptureWorkflow:
    """
    Orchestrates the automated capture workflow triggered by button press.
    """
    
    def __init__(self, 
                 camera_service,
                 ml_service,
                 dataset_manager,
                 batch_service,
                 gpio_service=None):
        """
        Initialize workflow with required services.
        
        Args:
            camera_service: Service for image capture
            ml_service: Service for ML classification
            dataset_manager: Service for dataset organization
            batch_service: Service for batch management
            gpio_service: Optional GPIO service for LED feedback
        """
        self.camera_service = camera_service
        self.ml_service = ml_service
        self.dataset_manager = dataset_manager
        self.batch_service = batch_service
        self.gpio_service = gpio_service
        
        logging.info("Capture workflow initialized")
    
    def execute(self) -> Dict[str, Any]:
        """
        Execute the complete capture workflow.
        
        Returns:
            dict: Workflow result with status and data
        """
        logging.info("=== STARTING CAPTURE WORKFLOW ===")
        
        try:
            # Step 1: Get active batch
            batch_id = self._get_active_batch()
            if not batch_id:
                logging.error("No active batch found. Aborting capture.")
                if self.gpio_service:
                    self.gpio_service.led_feedback_error()
                return {
                    'success': False,
                    'error': 'no_active_batch',
                    'message': 'No active batch. Please start a batch first.'
                }
            
            logging.info(f"Active batch: {batch_id}")
            
            # Step 2: Capture image
            image_path = self._capture_image(batch_id)
            if not image_path:
                logging.error("Image capture failed")
                if self.gpio_service:
                    self.gpio_service.led_feedback_error()
                return {
                    'success': False,
                    'error': 'capture_failed',
                    'message': 'Failed to capture image from camera'
                }
            
            logging.info(f"Image captured: {image_path}")
            
            # Step 3: Run ML classification
            classification_result = self._classify_image(image_path, batch_id)
            if not classification_result:
                logging.error("ML classification failed")
                # Don't abort - save image anyway
                classification_result = {
                    'classification': 'Unknown',
                    'confidence': 0.0,
                    'error': 'classification_failed'
                }
            
            logging.info(f"Classification: {classification_result.get('classification')} "
                        f"({classification_result.get('confidence', 0):.2%})")
            
            # Step 4: Save to dataset
            saved = self._save_to_dataset(image_path, batch_id, classification_result)
            if not saved:
                logging.warning("Failed to organize in dataset, but image is saved")
            
            # Step 5: Update batch record
            updated = self._update_batch(batch_id, image_path, classification_result)
            if not updated:
                logging.warning("Failed to update batch record")
            
            # Step 6: Success feedback
            if saved and updated:
                if self.gpio_service:
                    self.gpio_service.led_feedback_success()
                success = True
                error = None
                message = 'Capture, classification, and batch persistence complete.'
            else:
                if self.gpio_service:
                    self.gpio_service.led_feedback_error()
                success = False
                error = 'persistence_failed'
                message = 'Capture completed, but one or more results could not be saved.'

            logging.info("=== CAPTURE WORKFLOW COMPLETE ===")

            return {
                'success': success,
                'error': error,
                'message': message,
                'batch_id': batch_id,
                'image_path': image_path,
                'classification': classification_result.get('classification'),
                'confidence': classification_result.get('confidence'),
                'timestamp': datetime.now().isoformat()
            }
            
        except Exception as e:
            logging.error(f"Workflow error: {e}", exc_info=True)
            if self.gpio_service:
                self.gpio_service.led_feedback_error()
            return {
                'success': False,
                'error': 'workflow_error',
                'message': str(e)
            }
    
    def _get_active_batch(self) -> Optional[str]:
        """
        Get the currently active batch ID.
        
        Returns:
            str: Batch ID or None if no active batch
        """
        try:
            active_batch = self.batch_service.get_active_batch()
            if active_batch:
                return active_batch.get('batch_id')
            return None
        except Exception as e:
            logging.error(f"Error getting active batch: {e}")
            return None
    
    def _capture_image(self, batch_id: str) -> Optional[str]:
        """
        Capture image from camera with timestamp filename.
        
        Args:
            batch_id: Batch identifier
            
        Returns:
            str: Path to captured image or None on failure
        """
        try:
            # Generate timestamp-based filename
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"{timestamp}.jpg"
            
            # Capture image
            image_path = self.camera_service.capture_with_retry(
                filename=filename,
                batch_id=batch_id,
            )
            
            return image_path
            
        except Exception as e:
            logging.error(f"Error capturing image: {e}")
            return None
    
    def _classify_image(
        self,
        image_path: str,
        batch_id: str,
    ) -> Optional[Dict[str, Any]]:
        """
        Run ML classification on captured image.
        
        Args:
            image_path: Path to image file
            
        Returns:
            dict: Classification result or None on failure
        """
        try:
            result = self.ml_service.classify_image(
                image_path,
                batch_id=batch_id,
            )
            return result
        except Exception as e:
            logging.error(f"Error classifying image: {e}")
            return None
    
    def _save_to_dataset(self, 
                        image_path: str, 
                        batch_id: str, 
                        classification_result: Dict[str, Any]) -> bool:
        """
        Save image and result to organized dataset structure.
        
        Args:
            image_path: Path to captured image
            batch_id: Batch identifier
            classification_result: ML classification result
            
        Returns:
            bool: True if successful
        """
        try:
            return bool(self.dataset_manager.save_result(
                image_path=image_path,
                batch_id=batch_id,
                classification=classification_result.get('classification'),
                confidence=classification_result.get('confidence'),
                metadata={
                    'timestamp': datetime.now().isoformat(),
                    'model_name': classification_result.get('model_name', 'unknown'),
                    'captured_by': 'physical_button'
                }
            ))
        except Exception as e:
            logging.error(f"Error saving to dataset: {e}")
            return False
    
    def _update_batch(self, 
                     batch_id: str, 
                     image_path: str, 
                     classification_result: Dict[str, Any]) -> bool:
        """
        Update batch record with new quality assessment.
        
        Args:
            batch_id: Batch identifier
            image_path: Path to captured image
            classification_result: ML classification result
            
        Returns:
            bool: True if successful
        """
        try:
            self.batch_service.add_quality_assessment(
                batch_id=batch_id,
                image_path=image_path,
                classification=classification_result.get('classification'),
                confidence=classification_result.get('confidence'),
                timestamp=datetime.now().isoformat()
            )
            return True
        except Exception as e:
            logging.error(f"Error updating batch: {e}")
            return False
