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

## Deployment

One-time installation is a technician task: enable SPI/I2C, install the Raspberry Pi camera/GPIO and Python dependencies in a backend `.venv`, provision the API key, and install the systemd service as described in [SECURITY_SETUP.md](SECURITY_SETUP.md). The service starts on boot and restarts after failure. End users do not start the backend from a terminal during routine operation.

The server listens over HTTPS on port 5000 on the private network. A technician must provision a certificate trusted by the phone before starting the service. Configure the app with the certificate hostname (or matching IP) and enter the provisioned API key in Settings. See [SECURITY_SETUP.md](SECURITY_SETUP.md) for TLS provisioning and [ENCLOSURE_SETUP.md](ENCLOSURE_SETUP.md) for required physical capture setup and acceptance checks.

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

### Live camera preview
```
GET /api/camera/stream
```

This authenticated MJPEG stream is read-only. It does not save images, run classification, or change batch state. Saved captures and classifications are initiated only by pressing the physical button on the Raspberry Pi enclosure. Batch lifecycle controls remain available in the app.

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

A technician installs and enables `coprawatch.service` once using `install_service.sh`; see [SECURITY_SETUP.md](SECURITY_SETUP.md). Routine operators use the mobile app and do not need to start or manage the backend from a terminal.
