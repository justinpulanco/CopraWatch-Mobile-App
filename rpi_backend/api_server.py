"""
Flask API Server for RPI Backend
Communicates with Flutter Mobile App
"""
from flask import Flask, jsonify, request, Response
from sensors import SensorManager
from database import RPiDatabase
from datetime import datetime
import os
import subprocess
import threading


app = Flask(__name__)

# Initialize sensors and database
sensor_manager = SensorManager()
database = RPiDatabase("copra_data.db")

# Camera stream process
camera_stream_process = None


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
        import subprocess
        from datetime import datetime
        
        # Generate filename
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"copra_{timestamp}.jpg"
        filepath = f"images/{filename}"
        
        # Create images directory if doesn't exist
        import os
        os.makedirs("images", exist_ok=True)
        
        # Capture using rpicam-still
        result = subprocess.run([
            "rpicam-still",
            "-n",  # No preview
            "-o", filepath,
            "-t", "100"  # 100ms timeout
        ], capture_output=True, text=True)
        
        if result.returncode == 0:
            image_id = database.insert_image(filename, filepath)
            database.log_event("IMAGE_CAPTURE", f"Image: {filename}")
            
            return jsonify({
                "success": True,
                "image_id": image_id,
                "filename": filename,
                "filepath": filepath,
                "timestamp": datetime.now().isoformat()
            }), 200
        else:
            raise Exception(f"rpicam-still failed: {result.stderr}")
            
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


@app.route('/api/camera/test', methods=['GET'])
def test_camera():
    """Test if camera is accessible"""
    try:
        # Try to capture a test image
        result = subprocess.run([
            'rpicam-still', '-t', '1', '-o', '-'
        ], capture_output=True, timeout=5)
        
        if result.returncode == 0:
            return jsonify({
                "success": True,
                "message": "Camera is working",
                "command": "rpicam-still"
            }), 200
        else:
            return jsonify({
                "success": False,
                "message": "Camera failed",
                "error": result.stderr.decode()
            }), 500
            
    except subprocess.TimeoutExpired:
        return jsonify({
            "success": False,
            "error": "Camera timeout"
        }), 500
    except FileNotFoundError:
        try:
            # Try old command
            result = subprocess.run([
                'libcamera-still', '-t', '1', '-o', '-'
            ], capture_output=True, timeout=5)
            
            if result.returncode == 0:
                return jsonify({
                    "success": True,
                    "message": "Camera is working",
                    "command": "libcamera-still"
                }), 200
            else:
                return jsonify({
                    "success": False,
                    "message": "Camera failed",
                    "error": result.stderr.decode()
                }), 500
        except Exception as e:
            return jsonify({
                "success": False,
                "error": f"Camera not found: {str(e)}"
            }), 500
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500


@app.route('/api/camera/preview')
def camera_preview():
    """Simple camera preview - returns a single JPEG that can be refreshed"""
    try:
        # Capture a quick preview image
        result = subprocess.run([
            'rpicam-still', '-t', '1', '--nopreview',
            '--width', '640', '--height', '480',
            '-o', '-'
        ], capture_output=True, timeout=2)
        
        if result.returncode == 0:
            return Response(result.stdout, mimetype='image/jpeg')
        else:
            return jsonify({"error": "Preview failed"}), 500
            
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route('/api/camera/snapshot')
def camera_snapshot():
    """Get a single camera snapshot (refreshable for pseudo-streaming)"""
    try:
        result = subprocess.run([
            'rpicam-still', '-t', '1', '--nopreview',
            '--width', '640', '--height', '480',
            '-o', '-'
        ], capture_output=True, timeout=3)
        
        if result.returncode == 0:
            return Response(result.stdout, mimetype='image/jpeg')
        else:
            return jsonify({"error": "Camera capture failed"}), 500
            
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route('/api/camera/stream')
def camera_stream():
    """Live camera stream endpoint (MJPEG) - Simplified version"""
    def generate_frames():
        # Use raspistill in timelapse mode for simpler streaming
        process = None
        try:
            process = subprocess.Popen([
                'rpicam-vid', '-t', '0', '--nopreview',
                '--width', '640', '--height', '480',
                '--codec', 'mjpeg', '--inline', '-n',
                '-o', '-', '--framerate', '5'  # Lower framerate for stability
            ], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, bufsize=0)
            
            print("Camera stream process started")
            
            while True:
                # Read chunks looking for JPEG boundaries
                chunk = process.stdout.read(4096)
                if not chunk:
                    break
                
                # Look for JPEG start (FF D8) and end (FF D9) markers
                start_idx = 0
                while start_idx < len(chunk) - 1:
                    if chunk[start_idx] == 0xFF and chunk[start_idx + 1] == 0xD8:
                        # Found JPEG start
                        jpeg_start = start_idx
                        # Read until we find end marker
                        jpeg_data = chunk[jpeg_start:]
                        
                        # Keep reading until we get end marker
                        while True:
                            if len(jpeg_data) > 2:
                                for i in range(len(jpeg_data) - 1):
                                    if jpeg_data[i] == 0xFF and jpeg_data[i + 1] == 0xD9:
                                        # Complete JPEG found
                                        complete_jpeg = jpeg_data[:i + 2]
                                        yield (b'--frame\r\n'
                                               b'Content-Type: image/jpeg\r\n\r\n' + 
                                               complete_jpeg + b'\r\n')
                                        start_idx = jpeg_start + i + 2
                                        break
                                else:
                                    # Need more data
                                    more_data = process.stdout.read(4096)
                                    if not more_data:
                                        break
                                    jpeg_data += more_data
                                    continue
                                break
                            else:
                                more_data = process.stdout.read(4096)
                                if not more_data:
                                    break
                                jpeg_data += more_data
                        break
                    start_idx += 1
                        
        except Exception as e:
            print(f"Stream error: {e}")
        finally:
            if process:
                try:
                    process.terminate()
                    process.wait(timeout=1)
                except:
                    process.kill()
            print("Camera stream stopped")
    
    return Response(generate_frames(),
                    mimetype='multipart/x-mixed-replace; boundary=frame')


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
    print("API running on http://0.0.0.0:5000")
    print("Camera stream available on http://0.0.0.0:5000/api/camera/stream")
    database.log_event("STARTUP", "API Server started")
    
    # Run Flask app
    app.run(host='0.0.0.0', port=5000, debug=True, threaded=True)
