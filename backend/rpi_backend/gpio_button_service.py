"""
GPIO Button Handler Service
Handles physical button press events for automated copra image capture.

This service:
- Initializes GPIO pin for button input
- Detects button press with debouncing
- Triggers automated capture workflow
- Provides LED feedback
"""

import time
import logging
from typing import Callable, Optional
import RPi.GPIO as GPIO


class GPIOButtonService:
    """
    Service to handle physical button press for automated image capture.
    
    Hardware Setup:
    - Button connected to GPIO pin (default: GPIO17)
    - LED feedback on GPIO pin (default: GPIO18)
    - 10kΩ pull-up resistor on button
    - 220Ω resistor on LED
    """
    
    def __init__(self, 
                 button_pin: int = 17,
                 led_pin: int = 18,
                 debounce_ms: int = 300):
        """
        Initialize GPIO button service.
        
        Args:
            button_pin: GPIO pin number for button (BCM numbering)
            led_pin: GPIO pin number for LED feedback (BCM numbering)
            debounce_ms: Debounce time in milliseconds
        """
        self.button_pin = button_pin
        self.led_pin = led_pin
        self.debounce_ms = debounce_ms
        self.callback: Optional[Callable] = None
        self.is_running = False
        
        logging.info(f"Initializing GPIO Button Service (button_pin={button_pin}, led_pin={led_pin})")
    
    def initialize(self):
        """Initialize GPIO pins and setup button detection."""
        try:
            # Set GPIO mode to BCM (Broadcom pin numbering)
            GPIO.setmode(GPIO.BCM)
            
            # Setup button pin as input with pull-up resistor
            GPIO.setup(self.button_pin, GPIO.IN, pull_up_down=GPIO.PUD_UP)
            
            # Setup LED pin as output
            GPIO.setup(self.led_pin, GPIO.OUT)
            
            # Turn off LED initially
            GPIO.output(self.led_pin, False)
            
            self.is_running = True
            logging.info("GPIO initialized successfully")
            
        except Exception as e:
            logging.error(f"Failed to initialize GPIO: {e}")
            raise
    
    def register_callback(self, callback: Callable):
        """
        Register callback function to be called on button press.
        
        Args:
            callback: Function to call when button is pressed.
                     Should be async-compatible or handle its own threading.
        """
        self.callback = callback
        logging.info("Button press callback registered")
    
    def start_listening(self):
        """Start listening for button press events."""
        if not self.is_running:
            raise RuntimeError("GPIO not initialized. Call initialize() first.")
        
        if not self.callback:
            raise RuntimeError("No callback registered. Call register_callback() first.")
        
        try:
            # Setup interrupt on falling edge (button pressed)
            # Falling edge because we're using pull-up resistor
            GPIO.add_event_detect(
                self.button_pin,
                GPIO.FALLING,
                callback=self._on_button_press,
                bouncetime=self.debounce_ms
            )
            
            logging.info(f"Listening for button press on GPIO{self.button_pin}")
            
        except Exception as e:
            logging.error(f"Failed to start listening: {e}")
            raise
    
    def _on_button_press(self, channel):
        """
        Internal callback when button press is detected.
        Provides LED feedback and calls user callback.
        
        Args:
            channel: GPIO channel that triggered the interrupt
        """
        logging.info(f"Button press detected on GPIO{channel}")
        
        try:
            # Provide immediate LED feedback
            self.led_feedback_start()
            
            # Call user callback
            if self.callback:
                self.callback()
            
            # Turn off LED after callback completes
            time.sleep(0.5)  # Keep LED on for 500ms
            self.led_feedback_stop()
            
        except Exception as e:
            logging.error(f"Error in button press handler: {e}")
            # Show error pattern on LED (3 quick blinks)
            self.led_feedback_error()
    
    def led_feedback_start(self):
        """Turn on LED to indicate processing started."""
        try:
            GPIO.output(self.led_pin, True)
            logging.debug("LED feedback: ON")
        except Exception as e:
            logging.error(f"Failed to turn on LED: {e}")
    
    def led_feedback_stop(self):
        """Turn off LED to indicate processing complete."""
        try:
            GPIO.output(self.led_pin, False)
            logging.debug("LED feedback: OFF")
        except Exception as e:
            logging.error(f"Failed to turn off LED: {e}")
    
    def led_feedback_error(self):
        """Blink LED rapidly to indicate error."""
        try:
            for _ in range(3):
                GPIO.output(self.led_pin, True)
                time.sleep(0.1)
                GPIO.output(self.led_pin, False)
                time.sleep(0.1)
            logging.debug("LED feedback: ERROR pattern")
        except Exception as e:
            logging.error(f"Failed to show error pattern: {e}")
    
    def led_feedback_success(self):
        """
        Blink LED slowly to indicate success.
        Call this from your callback after successful capture.
        """
        try:
            for _ in range(2):
                GPIO.output(self.led_pin, True)
                time.sleep(0.3)
                GPIO.output(self.led_pin, False)
                time.sleep(0.3)
            logging.debug("LED feedback: SUCCESS pattern")
        except Exception as e:
            logging.error(f"Failed to show success pattern: {e}")
    
    def cleanup(self):
        """Clean up GPIO resources."""
        try:
            self.is_running = False
            GPIO.cleanup()
            logging.info("GPIO cleaned up")
        except Exception as e:
            logging.error(f"Failed to cleanup GPIO: {e}")
    
    def __enter__(self):
        """Context manager entry."""
        self.initialize()
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit."""
        self.cleanup()




def create_button_workflow_handler(capture_workflow):
    """
    Create a button press handler that triggers the capture workflow.
    
    Args:
        capture_workflow: CaptureWorkflow instance
        
    Returns:
        Callable: Handler function for button press
    """
    def handler():
        """Handle button press by executing capture workflow."""
        logging.info("Button pressed - starting capture workflow")
        result = capture_workflow.execute()
        
        if result['success']:
            logging.info(f"Workflow succeeded: {result.get('classification')} "
                        f"({result.get('confidence', 0):.2%})")
        else:
            logging.error(f"Workflow failed: {result.get('message', 'Unknown error')}")
    
    return handler
