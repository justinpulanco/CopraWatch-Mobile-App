# Copra Watch RPI Backend

Python backend for Raspberry Pi with mock sensors and API server.

## Features

- **Mock Sensors**: Temperature, humidity, camera (replace with real when hardware arrives)
- **SQLite Database**: Stores environmental data, images, classifications
- **Flask API**: REST endpoints for mobile app communication
- **System Logging**: Track all events

## Setup

### Prerequisites
- Raspberry Pi 4B+
- Python 3.8+
- pip

### Installation

```bash
cd rpi_backend
pip install -r requirements.txt
```

### Running the Server

```bash
python api_server.py
```

Server runs on `http://0.0.0.0:5000`

## API Endpoints

### Health Check
```
GET /api/health
```

### Environmental Sensors
```
GET /api/sensor/environmental
GET /api/sensor/environmental/history?limit=10
```

### Camera
```
POST /api/camera/capture
```

### Classification
```
POST /api/classification
{
  "image_id": 1,
  "classification": "Optimally-Dried",
  "confidence": 0.92
}
```

### History
```
GET /api/classifications/all
```

## Mock Data

All sensors currently return mock data:
- Temperature: 20-40°C (random walk)
- Humidity: 50-90% (random walk)
- Camera: Mock filename
- Classifications: Stored in database

## Swapping Mock to Real

Replace functions in `sensors.py` when hardware arrives:

```python
# Current (mock)
def read(self):
    return random.uniform(25, 35)

# TODO: Replace with real sensor code
# def read(self):
#     return sensor.read_value()
```

## Database

Tables:
- `environmental_data` - Sensor readings
- `images` - Captured images
- `classifications` - ML results
- `system_logs` - Events

## Next Steps

1. Test API endpoints locally
2. Deploy to Raspberry Pi
3. Connect Flutter app to API
4. Add real sensor integration when hardware arrives
