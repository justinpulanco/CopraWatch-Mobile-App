import random
import time
from datetime import datetime

try:
    import RPi.GPIO as GPIO
    HAS_GPIO = True
except ImportError:
    HAS_GPIO = False

try:
    import board
    import adafruit_sht31d
    HAS_SHT30 = True
except ImportError:
    HAS_SHT30 = False

class TemperatureSensor:
    def __init__(self):
        # CORRECT PINS FROM WORKING CODE
        self.SCK = 25
        self.CS = 8
        self.SO = 7
        self.initialized = False
        
        if HAS_GPIO:
            try:
                GPIO.setmode(GPIO.BCM)
                GPIO.setup(self.SCK, GPIO.OUT)
                GPIO.setup(self.CS, GPIO.OUT)
                GPIO.setup(self.SO, GPIO.IN)
                GPIO.output(self.CS, GPIO.HIGH)
                GPIO.output(self.SCK, GPIO.LOW)
                self.initialized = True
                print("✓ MAX6675 Ready (GPIO 25, 8, 7)")
            except Exception as e:
                print(f"✗ MAX6675 Error: {e}")

    def read(self):
        if not self.initialized:
            return round(random.uniform(55, 65), 2)
        
        try:
            GPIO.output(self.CS, GPIO.LOW)
            time.sleep(0.001)
            
            value = 0
            for _ in range(16):
                GPIO.output(self.SCK, GPIO.HIGH)
                value <<= 1
                if GPIO.input(self.SO):
                    value |= 1
                GPIO.output(self.SCK, GPIO.LOW)
            
            GPIO.output(self.CS, GPIO.HIGH)
            
            if value & 0x04:
                return 0.0
            
            value >>= 3
            temp = value * 0.25
            return round(temp, 2)
        except:
            return 0.0

class HumiditySensor:
    def __init__(self):
        self.sensor = None
        self.initialized = False
        
        if HAS_SHT30:
            try:
                i2c = board.I2C()
                self.sensor = adafruit_sht31d.SHT31D(i2c)
                self.initialized = True
                print("✓ SHT30 Ready")
            except Exception as e:
                print(f"✗ SHT30 Error: {e}")

    def read(self):
        if self.initialized and self.sensor:
            try:
                return round(self.sensor.relative_humidity, 2)
            except:
                return 0.0
        return round(random.uniform(10, 15), 2)

class SensorManager:
    def __init__(self):
        print("\n=== Sensor Init ===")
        self.temperature = TemperatureSensor()
        self.humidity = HumiditySensor()
        print("=== Ready ===\n")

    def get_environmental_data(self):
        return {
            "temperature": self.temperature.read(),
            "humidity": self.humidity.read(),
            "timestamp": datetime.now().isoformat(),
        }
    
    def capture_image(self):
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"copra_{timestamp}.jpg"
        return filename
