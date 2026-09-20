"""
This Raspberry Pi code was developed by newbiely.com
This Raspberry Pi code is made available for public use without any restriction
For comprehensive instructions and wiring diagrams, please visit:
https://newbiely.com/tutorials/raspberry-pi/raspberry-pi-max6675-thermocouple-module
"""


import RPi.GPIO as GPIO
import time

# GPIO pins wired to the MAX6675 module
SCK_PIN = 25  # Serial clock, Raspberry Pi drives this
CS_PIN = 8    # Chip select, active LOW to start a reading
SO_PIN = 7    # Serial data out from the module (there is no MOSI, the chip is read-only)

# Setup GPIO
GPIO.setmode(GPIO.BCM)
GPIO.setup(SCK_PIN, GPIO.OUT)
GPIO.setup(CS_PIN, GPIO.OUT)
GPIO.setup(SO_PIN, GPIO.IN)

# Keep the module idle until we are ready to read from it
GPIO.output(CS_PIN, GPIO.HIGH)
GPIO.output(SCK_PIN, GPIO.LOW)


def read_celsius():
    # Pull CS LOW to tell the MAX6675 to start a conversion/output cycle
    GPIO.output(CS_PIN, GPIO.LOW)

    raw_value = 0
    for i in range(16):
        # The MAX6675 shifts out one bit of the 16-bit word on every clock pulse, MSB first
        GPIO.output(SCK_PIN, GPIO.HIGH)
        raw_value <<= 1
        if GPIO.input(SO_PIN):
            raw_value |= 1
        GPIO.output(SCK_PIN, GPIO.LOW)

    # Release the module
    GPIO.output(CS_PIN, GPIO.HIGH)

    # Bit D2 is the fault flag, it is set to 1 when no thermocouple is connected
    if raw_value & 0x4:
        return None

    # Bits D14:D3 hold the 12-bit temperature reading, each step is 0.25°C
    return (raw_value >> 3) * 0.25


try:
    while True:
        celsius = read_celsius()

        if celsius is None:
            print("No thermocouple attached, check the probe wiring")
        else:
            fahrenheit = celsius * 9 / 5 + 32
            print(f"Temperature: {celsius:.2f}°C  ~  {fahrenheit:.2f}°F")

        time.sleep(1)

except KeyboardInterrupt:
    print("\nExiting...")

finally:
    GPIO.cleanup()
