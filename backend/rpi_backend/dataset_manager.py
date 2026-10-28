"""
Dataset Manager Service
Manages organized storage of copra images and classification results.

Features:
- Organize images by batch and timestamp
- Store classification results alongside images
- Monitor storage capacity
- Retrieve batch images
- Data archival and cleanup
"""

import os
import json
import shutil
import logging
from datetime import datetime
from typing import List, Dict, Any, Optional


class DatasetManager:
    """
    Service for managing dataset organization and storage.
    """
    
    def __init__(self, 
                 dataset_root: str = "dataset",
                 storage_warning_threshold_gb: float = 1.0,
                 storage_critical_threshold_gb: float = 0.1):
        """
        Initialize dataset manager.
        
        Args:
            dataset_root: Root directory for dataset storage
            storage_warning_threshold_gb: Warn when free space below this (GB)
            storage_critical_threshold_gb: Critical when below this (GB)
        """
        self.dataset_root = dataset_root
        self.storage_warning_threshold = storage_warning_threshold_gb * 1024 * 1024 * 1024
        self.storage_critical_threshold = storage_critical_threshold_gb * 1024 * 1024 * 1024
        
        # Create root dataset directory
        os.makedirs(dataset_root, exist_ok=True)
        
        logging.info(f"Dataset manager initialized (root={dataset_root})")
    
    def save_result(self,
                   image_path: str,
                   batch_id: str,
                   classification: str,
                   confidence: float,
                   metadata: Optional[Dict[str, Any]] = None) -> bool:
        """
        Save classification result alongside image.
        
        Args:
            image_path: Path to captured image
            batch_id: Batch identifier
            classification: Classification result
            confidence: Confidence score
            metadata: Additional metadata
            
        Returns:
            bool: True if successful
        """
        try:
            # Extract filename from path
            filename = os.path.basename(image_path)
            base_name = os.path.splitext(filename)[0]
            
            # Create batch directory and keep each image beside its metadata.
            batch_dir = os.path.join(self.dataset_root, batch_id)
            os.makedirs(batch_dir, exist_ok=True)
            dataset_image_path = os.path.join(batch_dir, filename)
            source_path = os.path.abspath(image_path)
            destination_path = os.path.abspath(dataset_image_path)
            if source_path != destination_path:
                if not os.path.isfile(source_path):
                    raise FileNotFoundError(f"Captured image not found: {source_path}")
                shutil.copy2(source_path, destination_path)

            # Build result data
            result_data = {
                'batch_id': batch_id,
                'filename': filename,
                'image_path': dataset_image_path,
                'classification': classification,
                'confidence': confidence,
                'timestamp': datetime.now().isoformat(),
                'metadata': metadata or {}
            }
            
            # Save result as JSON
            result_filename = f"{base_name}.json"
            result_path = os.path.join(batch_dir, result_filename)
            
            with open(result_path, 'w') as f:
                json.dump(result_data, f, indent=2)
            
            logging.info(f"Result saved: {result_path}")
            return True
            
        except Exception as e:
            logging.error(f"Failed to save result: {e}")
            return False
    
    def get_batch_images(self, batch_id: str) -> List[Dict[str, Any]]:
        """
        Get all images and results for a batch.
        
        Args:
            batch_id: Batch identifier
            
        Returns:
            list: List of image data with results
        """
        batch_dir = os.path.join(self.dataset_root, batch_id)
        
        if not os.path.exists(batch_dir):
            logging.warning(f"Batch directory not found: {batch_dir}")
            return []
        
        images = []
        
        try:
            # Find all JSON result files
            for filename in os.listdir(batch_dir):
                if filename.endswith('.json'):
                    result_path = os.path.join(batch_dir, filename)
                    
                    with open(result_path, 'r') as f:
                        result_data = json.load(f)
                        images.append(result_data)
            
            # Sort by timestamp
            images.sort(key=lambda x: x.get('timestamp', ''))
            
            logging.info(f"Found {len(images)} images for batch {batch_id}")
            return images
            
        except Exception as e:
            logging.error(f"Error retrieving batch images: {e}")
            return []
    
    def check_storage_capacity(self) -> Dict[str, Any]:
        """
        Check available storage capacity.
        
        Returns:
            dict: Storage information and status
        """
        try:
            stat = shutil.disk_usage(self.dataset_root)
            
            free_bytes = stat.free
            total_bytes = stat.total
            used_bytes = stat.used
            
            free_gb = free_bytes / (1024 ** 3)
            total_gb = total_bytes / (1024 ** 3)
            used_gb = used_bytes / (1024 ** 3)
            
            # Determine status
            if free_bytes < self.storage_critical_threshold:
                status = 'critical'
                logging.error(f"CRITICAL: Storage space critically low ({free_gb:.2f} GB free)")
            elif free_bytes < self.storage_warning_threshold:
                status = 'warning'
                logging.warning(f"WARNING: Storage space low ({free_gb:.2f} GB free)")
            else:
                status = 'ok'
            
            return {
                'status': status,
                'free_gb': round(free_gb, 2),
                'used_gb': round(used_gb, 2),
                'total_gb': round(total_gb, 2),
                'free_percent': round((free_bytes / total_bytes) * 100, 2)
            }
            
        except Exception as e:
            logging.error(f"Error checking storage: {e}")
            return {
                'status': 'error',
                'error': str(e)
            }
    
    def get_dataset_stats(self) -> Dict[str, Any]:
        """
        Get statistics about the dataset.
        
        Returns:
            dict: Dataset statistics
        """
        try:
            total_images = 0
            total_batches = 0
            classification_counts = {}
            
            # Count batches
            if os.path.exists(self.dataset_root):
                batches = [d for d in os.listdir(self.dataset_root) 
                          if os.path.isdir(os.path.join(self.dataset_root, d))]
                total_batches = len(batches)
                
                # Count images and classifications per batch
                for batch_id in batches:
                    images = self.get_batch_images(batch_id)
                    total_images += len(images)
                    
                    for img in images:
                        classification = img.get('classification', 'Unknown')
                        classification_counts[classification] = \
                            classification_counts.get(classification, 0) + 1
            
            return {
                'total_batches': total_batches,
                'total_images': total_images,
                'classification_distribution': classification_counts,
                'dataset_root': self.dataset_root
            }
            
        except Exception as e:
            logging.error(f"Error getting dataset stats: {e}")
            return {
                'error': str(e)
            }
    
    def archive_batch(self, batch_id: str, archive_dir: str = "archive") -> bool:
        """
        Move a batch to archive directory.
        
        Args:
            batch_id: Batch to archive
            archive_dir: Archive directory name
            
        Returns:
            bool: True if successful
        """
        try:
            batch_path = os.path.join(self.dataset_root, batch_id)
            
            if not os.path.exists(batch_path):
                logging.warning(f"Batch not found: {batch_id}")
                return False
            
            # Create archive directory
            archive_path = os.path.join(self.dataset_root, archive_dir)
            os.makedirs(archive_path, exist_ok=True)
            
            # Move batch to archive
            dest_path = os.path.join(archive_path, batch_id)
            shutil.move(batch_path, dest_path)
            
            logging.info(f"Batch {batch_id} archived to {dest_path}")
            return True
            
        except Exception as e:
            logging.error(f"Error archiving batch {batch_id}: {e}")
            return False
    
    def cleanup_old_batches(self, days_to_keep: int = 90) -> int:
        """
        Clean up batches older than specified days.
        
        Args:
            days_to_keep: Keep batches from last N days
            
        Returns:
            int: Number of batches cleaned up
        """
        from datetime import timedelta
        
        try:
            cutoff_date = datetime.now() - timedelta(days=days_to_keep)
            cleaned_count = 0
            
            if not os.path.exists(self.dataset_root):
                return 0
            
            batches = [d for d in os.listdir(self.dataset_root)
                      if os.path.isdir(os.path.join(self.dataset_root, d))]
            
            for batch_id in batches:
                batch_path = os.path.join(self.dataset_root, batch_id)
                
                # Get batch creation time
                batch_ctime = os.path.getctime(batch_path)
                batch_date = datetime.fromtimestamp(batch_ctime)
                
                # Archive if older than cutoff
                if batch_date < cutoff_date:
                    if self.archive_batch(batch_id):
                        cleaned_count += 1
            
            logging.info(f"Cleaned up {cleaned_count} old batches")
            return cleaned_count
            
        except Exception as e:
            logging.error(f"Error during cleanup: {e}")
            return 0
    
    def get_batch_directory(self, batch_id: str) -> str:
        """
        Get full path to batch directory.
        
        Args:
            batch_id: Batch identifier
            
        Returns:
            str: Full path to batch directory
        """
        return os.path.join(self.dataset_root, batch_id)
    
    def ensure_batch_directory(self, batch_id: str) -> str:
        """
        Ensure batch directory exists and return path.
        
        Args:
            batch_id: Batch identifier
            
        Returns:
            str: Full path to batch directory
        """
        batch_dir = self.get_batch_directory(batch_id)
        os.makedirs(batch_dir, exist_ok=True)
        return batch_dir
