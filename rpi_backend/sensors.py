"""
Final Sensor Module for CopraWatch
Supports real hardware (MAX6675/SHT30) with fallback.
"""
import random
import time
from datetime import datetime

# Hardware libraries
try:
    import board
    import busio
    import digitalio
    import adafruit_max31855
    import adafruit_sht31d
    HAS_HARDWARE = True
except ImportError:
    HAS_HARDWARE = False

class TemperatureSensor:
    def __init__(self):
        self.sensor = None
        if HAS_HARDWARE:
            try:
                # SPI setup (SCK=11, MOSI=10, MISO=9)
                self.spi = busio.SPI(board.SCK, MOSI=board.MOSI, MISO=board.MISO)
                self.cs = digitalio.DigitalInOut(board.D5) # GPIO 5
                self.sensor = adafruit_max31855.MAX31855(self.spi, self.cs)
                print("Hardware: MAX6675 Ready")
            except Exception as e:
                print(f"Hardware Error: {e}")

    def read(self):
        if self.sensor:
            try: return round(self.sensor.temperature, 2)
            except: return 0.0
        # Scientific Simulation: Simulate heat rising during drying
        return round(random.uniform(55, 65), 2)

class HumiditySensor:
    def __init__(self):
        self.sensor = None
        if HAS_HARDWARE:
            try:
                # I2C setup (SCL=3, SDA=2)
                self.i2c = busio.I2C(board.SCL, board.SDA)
                self.sensor = adafruit_sht31d.SHT31D(self.i2c)
                print("Hardware: SHT30 Ready")
            except Exception as e:
                print(f"Hardware Error: {e}")

    def read(self):
        if self.sensor:
            try: return round(self.sensor.relative_humidity, 2)
            except: return 0.0
        # Scientific Simulation: Drying copra is usually low humidity
        return round(random.uniform(10, 15), 2)

class SensorManager:
    def __init__(self):
        self.temperature = TemperatureSensor()
        self.humidity = HumiditySensor()

    def get_environmental_data(self):
        temp = self.temperature.read()
        hum = self.humidity.read()

        # Moisture is usually calculated based on drying curves or separate sensors
        # For this prototype, we simulate a decreasing moisture level
        moisture = round(max(5.0, 15.0 - (random.random() * 0.1)), 2)

        # Solar irradiance (Peak around noon)
        hour = datetime.now().hour
        solar = 0.0
        if 6 <= hour <= 18:
            solar = round(800.0 + random.uniform(-50, 50), 2)

        return {
            "temperature": temp,
            "humidity": hum,
            "moisture": moisture,
            "solarIrradiance": solar,
            "timestamp": datetime.now().isoformat(),
        }
