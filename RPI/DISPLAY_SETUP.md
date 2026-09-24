# RPi Temperature & Humidity Display

Shows live Temperature & Humidity on 5-inch HDMI LCD screen (800x480).

## Hardware

- **Raspberry Pi 4/5**
- **5-inch HDMI LCD 800x480** (USB Touch, RoHS Compliant)

## Wiring

```
HDMI LCD Pin → RPi Connection
HDMI         → HDMI Port
USB Power    → USB Port OR 5V Power
USB Touch    → USB Port (optional)
```

## Setup

### 1. Install Dependencies

```bash
sudo apt-get update
sudo apt-get install -y python3-pip

pip3 install pillow requests
```

### 2. Verify HDMI Display

```bash
# Check if display is detected
tvservice -s
# Should show: HDMI:EDID OK / connected
```

### 3. Run Display Monitor

```bash
python3 hdmi_display_monitor.py
```

**Display shows:**
- Temperature (°C) - Large red text
- Humidity (%) - Large green text
- Last update timestamp
- Updates every 2 seconds
- Fullscreen mode (800x480)

## Exit

Press **ESC** key or close window to exit.

## Autostart (Optional)

Add to crontab:
```bash
crontab -e
# Add: @reboot sleep 10 && python3 ~/RPI/hdmi_display_monitor.py &
```

---

Live monitoring on the HDMI screen at the drying site. 🥥
