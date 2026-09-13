"""
Flask API Server for RPI Backend
Communicates with Flutter Mobile App
"""
from flask import Flask, jsonify, request
from sensors import SensorManager
from database import RPiDatabase
from datetime import datetime
import os


app = Flask(__name__)

# Initialize sensors and database
sensor_manager = SensorManager()
database = RPiDatabase("copra_data.db")


# Routes

@app.route('/api/health', methods=['GET'])
def health_check():
    """System health check"""
    database.log_event("HEALTH_CHECK", "API health check")
    return jsonify({
        "status": "online",
        "timestamp": datetime.now().isoformat(),
        "version": "1.0.0"
    }), 200


@app.route('/api/sensor/environmental', methods=['GET'])
def get_environmental_data():
    """Get current temperature and humidity"""
    try:
        data = sensor_manager.get_environmental_data()
        database.insert_environmental_data(data["temperature"], data["humidity"])
        database.log_event("SENSOR_READ", f"Temp: {data['temperature']}°C, RH: {data['humidity']}%")
        
        return jsonify({
            "success": True,
            "data": data
        }), 200
    except Exception as e:
        database.log_event("SENSOR_ERROR", str(e))
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500


@app.route('/api/sensor/environmental/history', methods=['GET'])
def get_environmental_history():
    """Get historical sensor data"""
    limit = request.args.get('limit', 10, type=int)
    try:
        data = database.get_latest_environmental_data(limit)
        return jsonify({
            "success": True,
            "data": data,
            "count": len(data)
        }), 200
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500


@app.route('/api/camera/capture', methods=['POST'])
def capture_image():
    """Capture image from camera"""
    try:
        filename = sensor_manager.capture_image()
        image_id = database.insert_image(filename, f"images/{filename}")
        database.log_event("IMAGE_CAPTURE", f"Image: {filename}")
        
        return jsonify({
            "success": True,
            "image_id": image_id,
            "filename": filename,
            "timestamp": datetime.now().isoformat()
        }), 200
    except Exception as e:
        database.log_event("CAMERA_ERROR", str(e))
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500


@app.route('/api/classification', methods=['POST'])
def classify_image():
    """Store classification result (ML placeholder)"""
    try:
        data = request.get_json()
        image_id = data.get('image_id')
        classification = data.get('classification')
        confidence = data.get('confidence')
        
        if not all([image_id, classification, confidence]):
            return jsonify({
                "success": False,
                "error": "Missing required fields"
            }), 400
        
        database.insert_classification(image_id, classification, confidence)
        database.log_event("CLASSIFICATION", f"{classification} ({confidence})")
        
        return jsonify({
            "success": True,
            "message": "Classification stored",
            "timestamp": datetime.now().isoformat()
        }), 200
    except Exception as e:
        database.log_event("CLASSIFICATION_ERROR", str(e))
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500


@app.route('/api/classifications/all', methods=['GET'])
def get_all_classifications():
    """Get all classifications"""
    try:
        data = database.get_all_classifications()
        return jsonify({
            "success": True,
            "data": data,
            "count": len(data)
        }), 200
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500


@app.route('/api/system/logs', methods=['GET'])
def get_system_logs():
    """Get system logs (placeholder)"""
    return jsonify({
        "success": True,
        "message": "System logs endpoint"
    }), 200


# Error handlers

@app.errorhandler(404)
def not_found(error):
    return jsonify({
        "success": False,
        "error": "Endpoint not found"
    }), 404


@app.errorhandler(500)
def internal_error(error):
    return jsonify({
        "success": False,
        "error": "Internal server error"
    }), 500


if __name__ == '__main__':
    print("Starting Copra Watch RPI Backend API...")
    print("Running on http://0.0.0.0:5000")
    database.log_event("STARTUP", "API Server started")
    
    # Run Flask app
    app.run(host='0.0.0.0', port=5000, debug=True)
