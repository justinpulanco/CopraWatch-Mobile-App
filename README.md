# CopraWatch

A mobile and Raspberry Pi system for monitoring copra drying and assessing copra quality.

> BSIT capstone project

## Overview

CopraWatch collects temperature and humidity readings during drying, tracks batches, and uses a TensorFlow Lite model on the Raspberry Pi to classify captured copra as under-dried, optimally dried, or over-dried. The mobile app displays sensor readings, batch information, quality results, and alerts.

## How it works

1. Sensors connected to the Raspberry Pi provide temperature and humidity readings.
2. The enclosure's physical button captures an image for classification on the Pi.
3. The Flutter app connects to the Pi API to display readings, batches, and results.

## Main components

| Component | Technology |
|---|---|
| Mobile app | Flutter / Dart |
| Device API | Flask on Raspberry Pi |
| Quality assessment | TensorFlow Lite |
| Sensors | MAX6675 temperature sensor and SHT30 humidity sensor |

## Run the app

Requirements: Flutter SDK, a connected device or emulator, and access to a configured Raspberry Pi for live data.

```bash
flutter pub get
flutter run
```

For a local build:

```bash
flutter build apk --debug
```

## Raspberry Pi setup

Backend installation, hardware wiring, and model setup are documented in [`backend/rpi_backend/README.md`](backend/rpi_backend/README.md) and [`backend/rpi_backend/SETUP_ML.md`](backend/rpi_backend/SETUP_ML.md).

The API requires HTTPS. A technician must configure a phone-trusted TLS certificate and private key before starting the service. See [`backend/rpi_backend/SECURITY_SETUP.md`](backend/rpi_backend/SECURITY_SETUP.md) for setup instructions.

## Development checks

```bash
flutter test
```

## Repository layout

- `lib/` — Flutter app
- `backend/rpi_backend/` — Raspberry Pi API, sensor/camera workflow, and ML integration
- `assets/` — app images and model assets
- `test/` — Flutter tests
