"""
Startup/Initialization Service for Raspberry Pi Backend
Coordinates initialization of all backend services in the correct order.
"""

import os
import time
import logging
from datetime import datetime
from typing import Dict, Any, Optional

# Import all backend services
from sensors import SensorManager
from database import RPiDatabase
from ml_service import MLService
from camera_service import CameraService
from gpio_button_service import GPIOButtonService
from dataset_manager import DatasetManager
from capture_workflow import CaptureWorkflow
from batch_service import BatchService


class StartupService:
    """
    Service to manage startup and initialization of all backend components.

    This service ensures that all backend components are initialized
    in the correct order with proper error handling and recovery.
    """

    def __init__(self):
        """Initialize the startup service with default configuration."""
        self.logger = logging.getLogger(__name__)

        # Service instances (initialized to None)
        self.sensor_manager: Optional[SensorManager] = None
        self.database: Optional[RPiDatabase] = None
        self.ml_service: Optional[MLService] = None
        self.camera_service: Optional[CameraService] = None
        self.gpio_button_service: Optional[GPIOButtonService] = None
        self.dataset_manager: Optional[DatasetManager] = None
        self.capture_workflow: Optional[CaptureWorkflow] = None
        self.batch_service: Optional[BatchService] = None

        # Initialization status tracking
        self.initialized_services: Dict[str, bool] = {}
        self.initialization_errors: Dict[str, str] = {}

        # Resolve backend data paths from this module so service startup does not
        # depend on the caller's current working directory.
        self.backend_dir = os.path.dirname(os.path.abspath(__file__))
        self.model_path = os.path.join(self.backend_dir, "copra_quality_model.tflite")
        self.labels_path = os.path.join(self.backend_dir, "labels.txt")
        self.database_path = os.path.join(self.backend_dir, "copra_data.db")
        self.dataset_root = os.path.join(self.backend_dir, "dataset")
        self.images_dir = os.path.join(self.backend_dir, "images")
        self.exports_dir = os.path.join(self.backend_dir, "exports")

        # Directories to create
        self.directories_to_create = [
            self.dataset_root,
            self.images_dir,
            self.exports_dir
        ]

    def initialize_all(self) -> bool:
        """
        Initialize all backend services in the correct order.

        Returns:
            bool: True if all services initialized successfully, False otherwise
        """
        self.logger.info("Starting backend initialization...")
        start_time = time.time()

        # Reset initialization tracking
        self.initialized_services = {}
        self.initialization_errors = {}

        try:
            # Step 1: Create necessary directories
            self._initialize_directories()

            # Step 2: Initialize database (foundational service)
            self._initialize_database()

            # Step 3: Initialize sensors
            self._initialize_sensors()

            # Step 4: Initialize ML service
            self._initialize_ml_service()

            # Step 5: Initialize camera service
            self._initialize_camera_service()

            # Step 6: Initialize GPIO button service
            self._initialize_gpio_button_service()

            # Step 7: Initialize dataset manager
            self._initialize_dataset_manager()

            # Step 8: Initialize batch service
            self._initialize_batch_service()

            # Step 9: Initialize capture workflow (depends on other services)
            self._initialize_capture_workflow()

            # Log successful initialization
            elapsed_time = time.time() - start_time
            self.logger.info(f"All services initialized successfully in {elapsed_time:.2f} seconds")

            # Log initialization summary
            self._log_initialization_summary()

            return True

        except Exception as e:
            self.logger.error(f"Failed to initialize backend services: {e}")
            self._log_initialization_summary()
            return False

    def _initialize_directories(self) -> None:
        """Create necessary directories for the application."""
        self.logger.info("Creating necessary directories...")
        for directory in self.directories_to_create:
            try:
                os.makedirs(directory, exist_ok=True)
                self.logger.debug(f"Created directory: {directory}")
            except Exception as e:
                self.logger.warning(f"Failed to create directory {directory}: {e}")
                # Don't fail initialization for directory creation issues

        self.initialized_services["directories"] = True

    def _initialize_database(self) -> None:
        """Initialize the database service."""
        try:
            self.logger.info("Initializing database...")
            self.database = RPiDatabase(self.database_path)
            self.initialized_services["database"] = True
            self.logger.info("Database initialized successfully")
        except Exception as e:
            error_msg = f"Failed to initialize database: {e}"
            self.initialization_errors["database"] = error_msg
            self.logger.error(error_msg)
            raise

    def _initialize_sensors(self) -> None:
        """Initialize the sensor manager."""
        try:
            self.logger.info("Initializing sensors...")
            self.sensor_manager = SensorManager()
            self.initialized_services["sensors"] = True
            self.logger.info("Sensors initialized successfully")
        except Exception as e:
            error_msg = f"Failed to initialize sensors: {e}"
            self.initialization_errors["sensors"] = error_msg
            self.logger.error(error_msg)
            raise

    def _initialize_ml_service(self) -> None:
        """Initialize the ML service and load the model."""
        try:
            self.logger.info("Initializing ML service...")
            self.ml_service = MLService(self.model_path, self.labels_path)

            # Load the ML model
            self.logger.info("Loading ML model...")
            if not self.ml_service.load_model():
                raise RuntimeError("Failed to load ML model")

            self.initialized_services["ml_service"] = True
            self.logger.info("ML service initialized successfully")
        except Exception as e:
            error_msg = f"Failed to initialize ML service: {e}"
            self.initialization_errors["ml_service"] = error_msg
            self.logger.error(error_msg)
            raise

    def _initialize_camera_service(self) -> None:
        """Initialize the camera service."""
        try:
            self.logger.info("Initializing camera service...")
            self.camera_service = CameraService(
                output_dir=self.images_dir,
                resolution=(1920, 1080),
                quality=95
            )
            self.camera_service.initialize()
            self.initialized_services["camera_service"] = True
            self.logger.info("Camera service initialized successfully")
        except Exception as e:
            error_msg = f"Failed to initialize camera service: {e}"
            self.initialization_errors["camera_service"] = error_msg
            self.logger.error(error_msg)
            raise

    def _initialize_gpio_button_service(self) -> None:
        """Initialize the GPIO button service."""
        try:
            self.logger.info("Initializing GPIO button service...")
            self.gpio_button_service = GPIOButtonService(
                button_pin=17,
                led_pin=18,
                debounce_ms=300
            )
            self.gpio_button_service.initialize()
            self.initialized_services["gpio_button_service"] = True
            self.logger.info("GPIO button service initialized successfully")
        except Exception as e:
            error_msg = f"Failed to initialize GPIO button service: {e}"
            self.initialization_errors["gpio_button_service"] = error_msg
            self.logger.error(error_msg)
            # Note: We don't raise here because GPIO might not be available in all environments
            # This allows the system to continue without button functionality
            self.logger.warning("Continuing without GPIO button service")
            self.initialized_services["gpio_button_service"] = False

    def _initialize_dataset_manager(self) -> None:
        """Initialize the dataset manager."""
        try:
            self.logger.info("Initializing dataset manager...")
            self.dataset_manager = DatasetManager(
                dataset_root=self.dataset_root,
                storage_warning_threshold_gb=1.0,
                storage_critical_threshold_gb=0.1
            )
            self.initialized_services["dataset_manager"] = True
            self.logger.info("Dataset manager initialized successfully")
        except Exception as e:
            error_msg = f"Failed to initialize dataset manager: {e}"
            self.initialization_errors["dataset_manager"] = error_msg
            self.logger.error(error_msg)
            raise

    def _initialize_batch_service(self) -> None:
        """Initialize the batch service."""
        try:
            self.logger.info("Initializing batch service...")
            self.batch_service = BatchService(self.database_path)
            self.initialized_services["batch_service"] = True
            self.logger.info("Batch service initialized successfully")
        except Exception as e:
            error_msg = f"Failed to initialize batch service: {e}"
            self.initialization_errors["batch_service"] = error_msg
            self.logger.error(error_msg)
            raise

    def _initialize_capture_workflow(self) -> None:
        """Initialize the capture workflow (depends on other services)."""
        try:
            self.logger.info("Initializing capture workflow...")
            # The capture workflow depends on several other services
            if not all([
                self.camera_service,
                self.ml_service,
                self.dataset_manager,
                self.batch_service
            ]):
                missing_services = []
                if not self.camera_service:
                    missing_services.append("camera_service")
                if not self.ml_service:
                    missing_services.append("ml_service")
                if not self.dataset_manager:
                    missing_services.append("dataset_manager")
                if not self.batch_service:
                    missing_services.append("batch_service")

                raise RuntimeError(f"Cannot initialize capture workflow: missing services {missing_services}")

            self.capture_workflow = CaptureWorkflow(
                camera_service=self.camera_service,
                ml_service=self.ml_service,
                dataset_manager=self.dataset_manager,
                batch_service=self.batch_service,
                gpio_service=self.gpio_button_service
            )

            self.initialized_services["capture_workflow"] = True
            self.logger.info("Capture workflow initialized successfully")
        except Exception as e:
            error_msg = f"Failed to initialize capture workflow: {e}"
            self.initialization_errors["capture_workflow"] = error_msg
            self.logger.error(error_msg)
            raise

    def get_initialization_status(self) -> Dict[str, Any]:
        """
        Get the initialization status of all services.

        Returns:
            dict: Status information for each service
        """
        status = {}
        for service_name in [
            "directories", "database", "sensors", "ml_service",
            "camera_service", "gpio_button_service", "dataset_manager",
            "batch_service", "capture_workflow"
        ]:
            status[service_name] = {
                "initialized": self.initialized_services.get(service_name, False),
                "error": self.initialization_errors.get(service_name)
            }
        return status

    def is_service_initialized(self, service_name: str) -> bool:
        """
        Check if a specific service is initialized.

        Args:
            service_name: Name of the service to check

        Returns:
            bool: True if service is initialized, False otherwise
        """
        return self.initialized_services.get(service_name, False)

    def get_initialization_error(self, service_name: str) -> Optional[str]:
        """
        Get the initialization error for a specific service.

        Args:
            service_name: Name of the service

        Returns:
            str: Error message if initialization failed, None otherwise
        """
        return self.initialization_errors.get(service_name)

    def are_all_services_initialized(self) -> bool:
        """
        Check if all critical services are initialized.

        Returns:
            bool: True if all critical services are initialized, False otherwise
        """
        critical_services = [
            "database", "sensors", "ml_service",
            "camera_service", "dataset_manager",
            "batch_service", "capture_workflow"
        ]

        return all(self.is_service_initialized(service) for service in critical_services)

    def cleanup(self) -> None:
        """Clean up all initialized services."""
        self.logger.info("Cleaning up services...")

        # Cleanup in reverse order of initialization
        cleanup_services = [
            "capture_workflow",
            "gpio_button_service",
            "camera_service",
            "dataset_manager",
            "batch_service",
            "ml_service",
            "sensors",
            "database"
        ]

        for service_name in cleanup_services:
            try:
                service = getattr(self, service_name, None)
                if service and hasattr(service, 'cleanup') and callable(getattr(service, 'cleanup')):
                    service.cleanup()
                    self.logger.debug(f"Cleaned up {service_name}")
                elif service and hasattr(service, 'close') and callable(getattr(service, 'close')):
                    service.close()
                    self.logger.debug(f"Closed {service_name}")
            except Exception as e:
                self.logger.warning(f"Error cleaning up {service_name}: {e}")

        self.logger.info("Service cleanup completed")

    def _log_initialization_summary(self) -> None:
        """Log a summary of the initialization status."""
        self.logger.info("=== Initialization Summary ===")
        for service_name, status in self.get_initialization_status().items():
            status_str = "✓ INITIALIZED" if status["initialized"] else "✗ FAILED"
            error_str = f" ({status['error']})" if status["error"] else ""
            self.logger.info(f"{service_name}: {status_str}{error_str}")
        self.logger.info("================================")