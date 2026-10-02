# ML Setup Instructions for Raspberry Pi

## 1. Install Dependencies

```bash
cd rpi_backend
pip3 install -r requirements.txt
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
print('Model loaded:', ml.load_model())
print('Model info:', ml.get_model_info())
"
```

## 4. Start API Server

```bash
python3 api_server.py
```

## 5. Test Camera + ML

```bash
curl -X POST http://localhost:5000/api/camera/capture
```

Should return classification result along with image info.

## Troubleshooting

1. **TensorFlow Lite not found**:
   ```bash
   pip3 install tflite-runtime
   ```

2. **Model file not found**:
   - Check `copra_quality_model.tflite` is in rpi_backend folder
   - Check `labels.txt` is in rpi_backend folder

3. **Classification fails**:
   - Check image file exists and is readable
   - Check model input size matches preprocessing (224x224)

## New API Response

Camera capture now returns:
```json
{
  "success": true,
  "image_id": 1,
  "filename": "copra_20261028_143022.jpg",
  "classification": "Optimally-dried",
  "confidence": 0.87,
  "all_predictions": {
    "Under-dried": 0.05,
    "Optimally-dried": 0.87, 
    "Over-dried": 0.08
  }
}
```