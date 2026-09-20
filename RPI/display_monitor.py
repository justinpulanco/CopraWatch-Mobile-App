"""
RPi Display Monitor for Temperature & Humidity
Shows live sensor data on LCD/OLED screen
"""

import time
import requests
from datetime import datetime
from threading import Thread

# Try to import display libraries
try:
    import board
    import adafruit_ssd1306
    from PIL import Image, ImageDraw, ImageFont
    HAS_DISPLAY = True
except ImportError:
    HAS_DISPLAY = False
    print("⚠️  Display libraries not installed. Install with: pip install adafruit-circuitpython-ssd1306 pillow")


class DisplayMonitor:
    def __init__(self, api_url="http://localhost:5000"):
        self.api_url = api_url
        self.display = None
        self.running = False
        self.current_temp = 0
        self.current_humidity = 0
        
        if HAS_DISPLAY:
            try:
                # Initialize I2C and display (128x64 OLED)
                i2c = board.I2C()
                self.display = adafruit_ssd1306.SSD1306_I2C(128, 64, i2c)
                self.display.fill(0)
                self.display.show()
                print("✓ Display initialized")
            except Exception as e:
                print(f"✗ Display error: {e}")
                self.display = None
    
    def fetch_sensor_data(self):
        """Fetch latest sensor data from API"""
        try:
            response = requests.get(f"{self.api_url}/api/sensor/environmental", timeout=5)
            if response.status_code == 200:
                data = response.json()
                if data.get("success"):
                    self.current_temp = data["data"]["temperature"]
                    self.current_humidity = data["data"]["humidity"]
                    return True
        except Exception as e:
            print(f"Error fetching data: {e}")
        return False
    
    def draw_text_display(self):
        """Draw text-based display (fallback if PIL not available)"""
        if not self.display:
            return
        
        # Clear display
        self.display.fill(0)
        
        # Create image for drawing
        image = Image.new("1", (128, 64))
        draw = ImageDraw.Draw(image)
        
        # Try to use default font
        try:
            font_large = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 24)
            font_small = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 12)
        except:
            font_large = ImageFont.load_default()
            font_small = ImageFont.load_default()
        
        # Draw title
        draw.text((0, 0), "CopraWatch Monitor", fill=1, font=font_small)
        
        # Draw temperature
        draw.text((0, 15), f"Temp: {self.current_temp}C", fill=1, font=font_large)
        
        # Draw humidity
        draw.text((0, 40), f"Humidity: {self.current_humidity}%", fill=1, font=font_large)
        
        # Draw timestamp
        timestamp = datetime.now().strftime("%H:%M:%S")
        draw.text((0, 58), timestamp, fill=1, font=font_small)
        
        # Display image
        self.display.image(image)
        self.display.show()
    
    def run(self):
        """Main loop - continuously update display"""
        self.running = True
        print("Starting display monitor...")
        
        while self.running:
            try:
                # Fetch data every 2 seconds
                if self.fetch_sensor_data():
                    self.draw_text_display()
                    print(f"[{datetime.now().strftime('%H:%M:%S')}] Temp: {self.current_temp}°C | Humidity: {self.current_humidity}%")
                
                time.sleep(2)
                
            except Exception as e:
                print(f"Display error: {e}")
                time.sleep(1)
    
    def start_thread(self):
        """Start display monitor in background thread"""
        thread = Thread(target=self.run, daemon=True)
        thread.start()
        return thread
    
    def stop(self):
        """Stop the display monitor"""
        self.running = False
        if self.display:
            self.display.fill(0)
            self.display.show()


# Standalone usage
if __name__ == "__main__":
    print("CopraWatch RPi Display Monitor")
    print("Displays Temperature & Humidity on OLED screen")
    print("Press Ctrl+C to stop\n")
    
    monitor = DisplayMonitor()
    
    try:
        monitor.run()
    except KeyboardInterrupt:
        print("\nStopping display monitor...")
        monitor.stop()
