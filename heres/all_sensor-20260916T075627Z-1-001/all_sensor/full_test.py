import time
import csv
import subprocess
from datetime import datetime

import board
import adafruit_sht31d
import RPi.GPIO as GPIO

# SHT30-D
i2c = board.I2C()
sht30 = adafruit_sht31d.SHT31D(i2c)

# MAX6675
SCK = 25
CS = 8
SO = 7

GPIO.setmode(GPIO.BCM)
GPIO.setup(SCK, GPIO.OUT)
GPIO.setup(CS, GPIO.OUT)
GPIO.setup(SO, GPIO.IN)

def read_max6675():
    GPIO.output(CS, GPIO.LOW)
    time.sleep(0.001)

    value = 0

    for _ in range(16):
        GPIO.output(SCK, GPIO.HIGH)
        value <<= 1
        GPIO.output(SCK, GPIO.LOW)
        value |= GPIO.input(SO)

    GPIO.output(CS, GPIO.HIGH)

    if value & 0x04:
        return None

    value >>= 3
    return value * 0.25

try:
    with open("sensor_data.csv", "a", newline="") as f:
        writer = csv.writer(f)

        while True:
            now = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")

            max_temp = read_max6675()
            sht_temp = sht30.temperature
            humidity = sht30.relative_humidity

            photo = f"photo_{now}.jpg"

            subprocess.run([
                "rpicam-still",
                "-n",
                "-o",
                photo
            ], stdout=subprocess.DEVNULL)

            writer.writerow([
                now,
                max_temp,
                sht_temp,
                humidity,
                photo
            ])
            f.flush()

            print(f"Time: {now}")
            print(f"MAX6675: {max_temp:.2f} °C")
            print(f"SHT30-D: {sht_temp:.2f} °C")
            print(f"Humidity: {humidity:.2f} %")
            print(f"Photo: {photo}")
            print("------------------------")

            time.sleep(5)

except KeyboardInterrupt:
    print("\nFull test stopped.")

finally:
    GPIO.cleanup()