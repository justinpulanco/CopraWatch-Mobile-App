# CopraWatch Raspberry Pi Backend

Flask API server for copra monitoring with MAX6675 and SHT30 sensors.

## Hardware Setup

### MAX6675 (Temperature)
```
MAX6675 → Raspberry Pi
VCC     → 3.3V (Pin 1)
GND     → GND (Pin 6)
SCK     → GPIO 11 (Pin 23)
CS      → GPIO 8 (Pin 24)
SO      → GPIO 9 (Pin 21)
```

### SHT30 (Humidity)
```
SHT30   → Raspberry Pi
VCC     → 3.3V (Pin 1)
GND     → GND (Pin 6)
SDA     → GPIO 2 (Pin 3)
SCL     → GPIO 3 (Pin 5)
```

## Software Setup

### 1. Enable SPI (for MAX6675)
```bash
sudo raspi-config
# Interface Options → SPI → Enable → Reboot
```

### 2. Enable I2C (for SHT30)
```bash
sudo raspi-config
# Interface Options → I2C → Enable → Reboot
```

### 3. Install Dependencies
```bash
pip3 install -r requirements.txt --break-system-packages
```

Or install manually:
```bash
pip3 install Flask Flask-CORS RPi.GPIO --break-system-packages
```

For SHT30 (optional):
```bash
pip3 install adafruit-circuitpython-sht31d --break-system-packages
```

## Usage

### Test Sensors Only
```bash
python3 test_sensors.py
```

### Start API Server
```bash
python3 api_server.py
```

Or use the startup script:
```bash
chmod +x start.sh
./start.sh
```

Server runs on: `http://0.0.0.0:5000`

## API Endpoints

### Health Check
```
GET /api/health
```

### Get Current Sensor Data
```
GET /api/sensor/environmental
Response: {"temperature": 60.5, "humidity": 12.3, "timestamp": "..."}
```

### Get Historical Data
```
GET /api/sensor/environmental/history?limit=10
```

### Capture Image
```
POST /api/camera/capture
```

### Store Classification
```
POST /api/classification
Body: {"image_id": 1, "classification": "Optimally-Dried", "confidence": 0.95}
```

### Get All Classifications
```
GET /api/classifications/all
```

### Save and list exports
Exports are saved on the Raspberry Pi SD card in the backend `exports/` folder.
```
POST /api/exports?filename=report.pdf
GET /api/exports
GET /api/exports/<filename>
```

## Troubleshooting

### No sensor readings?
1. Check wiring
2. Verify SPI/I2C enabled: `ls /dev/spi*` and `ls /dev/i2c*`
3. Run with sudo: `sudo python3 test_sensors.py`

### Permission denied?
```bash
sudo usermod -a -G gpio,spi,i2c $USER
# Log out and back in
```

### Mock data instead of real readings?
- System automatically uses mock data if sensors not connected
- Check console output for "✓" (working) or "✗" (mock)

## Mobile App Connection

Get your Pi's IP:
```bash
hostname -I
```

In Flutter app Settings, enter:
- IP: `192.168.x.x` (your Pi's IP)
- Port: `5000`

## Auto-Start on Boot

Create systemd service:
```bash
sudo nano /etc/systemd/system/coprawatch.service
```

Add:
```
[Unit]
Description=CopraWatch API Server
After=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/Desktop/rpi_backend
ExecStart=/usr/bin/python3 /home/pi/Desktop/rpi_backend/api_server.py
Restart=always

[Install]
WantedBy=multi-user.target
```

Enable:
```bash
sudo systemctl enable coprawatch
sudo systemctl start coprawatch
sudo systemctl status coprawatch
```
