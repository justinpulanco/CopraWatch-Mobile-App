"""
RPi HDMI Display Monitor for Temperature & Humidity
Shows live sensor data on 5-inch HDMI LCD screen (800x480)
"""

import tkinter as tk
import requests
import threading
from datetime import datetime
from PIL import Image, ImageDraw, ImageFont

class HDMIDisplayMonitor:
    def __init__(self, api_url="http://localhost:5000"):
        self.api_url = api_url
        self.current_temp = 0.0
        self.current_humidity = 0.0
        self.running = True
        
        # Create Tkinter window (fullscreen on HDMI)
        self.root = tk.Tk()
        self.root.title("CopraWatch Monitor")
        self.root.geometry("800x480")
        self.root.configure(bg='#1a1a1a')
        
        # Remove window decorations for fullscreen
        self.root.attributes('-fullscreen', True)
        
        # Create main frame
        main_frame = tk.Frame(self.root, bg='#1a1a1a')
        main_frame.pack(fill=tk.BOTH, expand=True)
        
        # Title
        title_label = tk.Label(
            main_frame,
            text="CopraWatch Monitor",
            font=("Arial", 32, "bold"),
            fg="#4CAF50",
            bg='#1a1a1a'
        )
        title_label.pack(pady=20)
        
        # Temperature display
        temp_frame = tk.Frame(main_frame, bg='#1a1a1a')
        temp_frame.pack(pady=40)
        
        temp_label = tk.Label(
            temp_frame,
            text="Temperature",
            font=("Arial", 24),
            fg="#FFFFFF",
            bg='#1a1a1a'
        )
        temp_label.pack()
        
        self.temp_value = tk.Label(
            temp_frame,
            text="0.0°C",
            font=("Arial", 60, "bold"),
            fg="#FF6B6B",
            bg='#1a1a1a'
        )
        self.temp_value.pack()
        
        # Humidity display
        humidity_frame = tk.Frame(main_frame, bg='#1a1a1a')
        humidity_frame.pack(pady=40)
        
        humidity_label = tk.Label(
            humidity_frame,
            text="Humidity",
            font=("Arial", 24),
            fg="#FFFFFF",
            bg='#1a1a1a'
        )
        humidity_label.pack()
        
        self.humidity_value = tk.Label(
            humidity_frame,
            text="0.0%",
            font=("Arial", 60, "bold"),
            fg="#4CAF50",
            bg='#1a1a1a'
        )
        self.humidity_value.pack()
        
        # Status/Time
        self.status_label = tk.Label(
            main_frame,
            text="",
            font=("Arial", 16),
            fg="#999999",
            bg='#1a1a1a'
        )
        self.status_label.pack(pady=20)
        
        # Start update thread
        self.update_thread = threading.Thread(target=self.update_loop, daemon=True)
        self.update_thread.start()
        
        # Handle window close
        self.root.protocol("WM_DELETE_WINDOW", self.on_close)
    
    def fetch_sensor_data(self):
        """Fetch latest sensor data from API"""
        try:
            response = requests.get(
                f"{self.api_url}/api/sensor/environmental",
                timeout=5
            )
            if response.status_code == 200:
                data = response.json()
                if data.get("success"):
                    self.current_temp = data["data"]["temperature"]
                    self.current_humidity = data["data"]["humidity"]
                    return True
        except Exception as e:
            print(f"Error fetching data: {e}")
        return False
    
    def update_loop(self):
        """Background thread to fetch and update display"""
        import time
        
        while self.running:
            try:
                if self.fetch_sensor_data():
                    # Update temperature
                    self.temp_value.config(
                        text=f"{self.current_temp}°C"
                    )
                    
                    # Update humidity
                    self.humidity_value.config(
                        text=f"{self.current_humidity}%"
                    )
                    
                    # Update timestamp
                    timestamp = datetime.now().strftime("%H:%M:%S")
                    self.status_label.config(
                        text=f"Last update: {timestamp}"
                    )
                    
                    print(f"[{timestamp}] Temp: {self.current_temp}°C | Humidity: {self.current_humidity}%")
                
                time.sleep(2)
                
            except Exception as e:
                print(f"Update error: {e}")
                time.sleep(1)
    
    def on_close(self):
        """Handle window close"""
        self.running = False
        self.root.quit()
    
    def run(self):
        """Start the display"""
        print("Starting HDMI Display Monitor...")
        print("Press ESC to exit (or close window)")
        
        # Bind ESC key to close
        self.root.bind('<Escape>', lambda e: self.on_close())
        
        self.root.mainloop()


if __name__ == "__main__":
    print("CopraWatch HDMI Display Monitor")
    print("Displays Temperature & Humidity on 5-inch HDMI LCD")
    print("Press Escape or close window to exit\n")
    
    monitor = HDMIDisplayMonitor()
    monitor.run()
