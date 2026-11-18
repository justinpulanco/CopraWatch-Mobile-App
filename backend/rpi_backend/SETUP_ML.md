# ML Setup Instructions for Raspberry Pi

## 1. Install Dependencies

```bash
cd rpi_backend
pip3 install -r requirements.txt
```

If you get errors, install TFLite runtime explicitly:

```bash
# For Raspberry Pi 4/5 (arm64)
pip3 install tflite-runtime

# Or use AI Edge TFLite (newer, recommended)
pip3 install ai-edge-litert
```

## 2. Copy Model Files

Copy these files from your Flutter app to the RPi backend directory:

```bash
# From: assets/copra_quality_model.tflite/model_unquant.tflite
# To: rpi_backend/copra_quality_model.tflite

# From: assets/copra_quality_model.tflite/labels.txt  
# To: rpi_backend/labels.txt
```

## 3. Test ML Service

```bash
python3 -c "
from ml_service import MLService
ml = MLService()
result = ml.load_model()
print('Model loaded:', result)
if result:
    print('Model info:', ml.get_model_info())
else:
    print('ERROR: Model failed to load - check copra_quality_model.tflite file')
"
```

## 4. Start API Server

```bash
python3 api_server.py
```

The server will log "✓ ML model loaded successfully" if working.

## 5. Test Camera + ML

```bash
# Use the certificate hostname configured for this Pi and a provisioned API key.
curl --cacert /path/to/trusted-ca.pem \
  -H "X-API-Key: $COPRAWATCH_API_KEY" \
  https://pi.your-domain.example:5000/api/health
```

Should return classification result or detailed error message.

## Troubleshooting

### Issue: "RPi returned 500" in mobile app

1. **Check server logs** - Run the server in terminal to see actual error:
   ```bash
   python3 api_server.py
   # Watch for error messages during capture
   ```

2. **TensorFlow/TFLite import error**:
   The code now supports multiple import paths:
   - ai_edge_litert (Google AI Edge - newest)
   - tflite_runtime (Raspberry Pi standard)
   - tensorflow.lite (fallback)
   
   If none work, install explicitly:
   ```bash
   pip3 install tflite-runtime --index-url https://google-coral.github.io/py-repo/
   ```

3. **Model file not found**:
   ```bash
   ls -la copra_quality_model.tflite
   ls -la labels.txt
   ```
   If missing, copy from Flutter app's assets folder

4. **Camera not detected**:
   ```bash
   rpicam-still --list-cameras
   libcamera-still --list-cameras
   ```
   Camera must be enabled in raspi-config

5. **Classification returns "❌ Model Not Loaded"**:
   - Check PIL/Pillow installed: `pip3 install pillow`
   - Check NumPy: `pip3 install numpy`

## API Response Examples

### Successful Capture:
```json
{
  "success": true,
  "image_id": 1,
  "filename": "copra_20261028_143022.jpg",
  "filepath": "/home/pi/rpi_backend/images/copra_20261028_143022.jpg",
  "classification": "Optimally-dried",
  "confidence": 0.87,
  "all_predictions": {
    "Under-dried": 0.05,
    "Optimally-dried": 0.87, 
    "Over-dried": 0.08
  },
  "ml_duration": 0.325
}
```

### Classification Error (with image saved):
```json
{
  "success": false,
  "error": "ML classification failed - ensure model file (copra_quality_model.tflite) exists",
  "image_id": 1,
  "filename": "copra_20261028_143022.jpg",
  "filepath": "/home/pi/rpi_backend/images/copra_20261028_143022.jpg",
  "ml_duration": 0.05
}
```

### Camera Error:
```json
{
  "success": false,
  "error": "Camera not available: [FileNotFoundError] rpicam-still not found"
}
```