# RPi Temperature & Humidity Display

Shows live Temperature & Humidity on OLED screen connected to Raspberry Pi.

## Hardware

- **Raspberry Pi 4/5**
- **128x64 OLED Display** (I2C) - SSD1306 or SH1106

## Wiring

```
OLED Pin → RPi Pin
VCC      → 3.3V (Pin 1)
GND      → GND (Pin 6)
SDA      → GPIO 2 (Pin 3)
SCL      → GPIO 3 (Pin 5)
```

## Setup

### 1. Install Dependencies

```bash
sudo apt-get update
sudo apt-get install -y python3-pip

pip3 install adafruit-circuitpython-ssd1306 pillow requests
```

### 2. Enable I2C

```bash
sudo raspi-config
# → Interfacing Options → I2C → Enable → Reboot
```

### 3. Run Display Monitor

```bash
python3 display_monitor.py
```

**Display shows:**
- Temperature (°C)
- Humidity (%)
- Updates every 2 seconds

## Autostart (Optional)

Add to crontab:
```bash
crontab -e
# Add: @reboot sleep 10 && python3 ~/RPI/display_monitor.py &
```

Or use systemd service (see full docs).

---

Simple, clean display for the drying site. 🥥
