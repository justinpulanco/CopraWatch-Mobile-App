"""
Flask API Server for RPI Backend
Communicates with Flutter Mobile App
"""
from flask import Flask, jsonify, request, Response, send_from_directory
from werkzeug.utils import secure_filename
from sensors import SensorManager
from database import RPiDatabase
from ml_service import MLService
from datetime import datetime
import os
import subprocess
import threading
import time


app = Flask(__name__)
app.config['MAX_CONTENT_LENGTH'] = 10 * 1024 * 1024

# Initialize sensors, database, and ML service
sensor_manager = SensorManager()
database = RPiDatabase("copra_data.db")
ml_service = MLService("copra_quality_model.tflite", "labels.txt")

# Load ML model on startup
print("Loading ML model...")
if ml_service.load_model():
    print("✓ ML model loaded successfully")
else:
    print("✗ Failed to load ML model")

# Camera stream process
camera_stream_process = None
BACKEND_VERSION = "2.0.0-exports"
EXPORTS_DIRECTORY = os.path.join(os.path.dirname(os.path.abspath(__file__)), "exports")
IMAGES_DIRECTORY = os.path.join(os.path.dirname(os.path.abspath(__file__)), "images")
os.makedirs(EXPORTS_DIRECTORY, exist_ok=True)
os.makedirs(IMAGES_DIRECTORY, exist_ok=True)


# Routes

@app.route('/api/health', methods=['GET'])
def health_check():
    """System health check"""
    database.log_event("HEALTH_CHECK", "API health check")
    return jsonify({
        "status": "online",
        "timestamp": datetime.now().isoformat(),
        "version": BACKEND_VERSION,
        "exports_directory": os.path.abspath(EXPORTS_DIRECTORY),
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
    """Capture image from camera and classify with ML"""
    try:
        import subprocess
        import platform
        from datetime import datetime
        
        # Generate filename
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"copra_{timestamp}.jpg"
        filepath = os.path.join(IMAGES_DIRECTORY, filename)
        
        # Create images directory if doesn't exist
        import os
        os.makedirs(IMAGES_DIRECTORY, exist_ok=True)
        
        # Check if running on Windows (for testing)
        if platform.system() == 'Windows':
            # For Windows - show error message to use real RPi
            return jsonify({
                "success": False,
                "error": "Camera capture requires Raspberry Pi hardware. Please run on actual RPi for real capture and ML processing.",
                "classification": "❌ Hardware Required",
                "confidence": 0.0
            }), 400
        else:
            # Raspberry Pi camera capture
            try:
                # Kill any existing camera processes first
                try:
                    subprocess.run(["sudo", "pkill", "-f", "rpicam"], check=False)
                    subprocess.run(["sudo", "pkill", "-f", "libcamera"], check=False)
                    time.sleep(0.5)  # Wait for processes to die
                except:
                    pass
                
                # Simple single capture command
                result = subprocess.run([
                    "rpicam-still",
                    "-n",  # No preview
                    "-o", filepath,
                    "--timeout", "500",  # 500ms timeout
                    "--width", "224", 
                    "--height", "224",
                    "--quality", "70"
                ], capture_output=True, text=True, timeout=8)
                
                if result.returncode != 0:
                    # Try alternative camera command
                    result = subprocess.run([
                        "libcamera-still",
                        "-n", "-o", filepath, "-t", "500"
                    ], capture_output=True, text=True, timeout=8)
                
                if result.returncode != 0:
                    raise Exception(f"Camera capture failed: {result.stderr}")
                    
            except subprocess.TimeoutExpired:
                raise Exception("Camera timeout - camera may be busy or disconnected")
            except Exception as e:
                raise Exception(f"Camera error: {str(e)}")
        
        # Check if image file was created
        if os.path.exists(filepath):
            print(f"Image captured successfully: {filepath}")
            image_id = database.insert_image(filename, filepath)
            database.log_event("IMAGE_CAPTURE", f"Image: {filename}")
            
            # Perform ML classification with timing
            print("Starting ML classification...")
            start_time = datetime.now()
            classification_result = ml_service.classify_image(filepath)
            end_time = datetime.now()
            ml_duration = (end_time - start_time).total_seconds()
            print(f"ML classification took {ml_duration:.2f} seconds")
            
            if classification_result:
                # Store classification result in database
                database.insert_classification(
                    image_id, 
                    classification_result["classification"], 
                    classification_result["confidence"]
                )
                database.log_event("CLASSIFICATION", 
                    f"{classification_result['classification']} ({classification_result['confidence']:.2f})")
                
                # Auto-complete active batch if classification is done
                try:
                    conn = database.get_connection()
                    cursor = conn.cursor()
                    cursor.execute('SELECT batch_id FROM active_batch WHERE status = "active" LIMIT 1')
                    active_batch = cursor.fetchone()
                    
                    if active_batch:
                        # Get current environmental data for batch completion
                        current_data = sensor_manager.get_environmental_data()
                        
                        # Complete the batch automatically
                        cursor.execute('SELECT * FROM active_batch WHERE status = "active" LIMIT 1')
                        batch_data = cursor.fetchone()
                        (batch_id, batch_name, start_time, end_time, start_temp,
                         start_hum, end_temp, end_hum, avg_temp_db, avg_hum_db,
                         saved_quality, saved_confidence, status) = batch_data
                        
                        avg_temp = (start_temp + current_data["temperature"]) / 2
                        avg_hum = (start_hum + current_data["humidity"]) / 2
                        
                        cursor.execute('''
                            UPDATE active_batch SET 
                            status = "completed",
                            end_time = ?,
                            end_temperature = ?,
                            end_humidity = ?,
                            average_temperature = ?,
                            average_humidity = ?,
                            quality_result = ?,
                            confidence = ?
                            WHERE batch_id = ?
                        ''', (datetime.now().isoformat(), current_data["temperature"], current_data["humidity"],
                              avg_temp, avg_hum, classification_result["classification"], 
                              classification_result["confidence"], batch_id))
                        
                        conn.commit()
                        database.log_event("BATCH_AUTO_COMPLETE", f"Auto-completed batch {batch_id}")
                    
                    conn.close()
                except Exception as e:
                    print(f"Error auto-completing batch: {e}")
                
                return jsonify({
                    "success": True,
                    "image_id": image_id,
                    "filename": filename,
                    "filepath": filepath,
                    "timestamp": datetime.now().isoformat(),
                    "classification": classification_result["classification"],
                    "confidence": classification_result["confidence"],
                    "all_predictions": classification_result.get("all_predictions", {}),
                    "error": classification_result.get("error"),
                    "ml_duration": ml_duration
                }), 200
            else:
                # Image captured but classification failed
                database.log_event("CLASSIFICATION_ERROR", "ML classification failed")
                return jsonify({
                    "success": False,
                    "error": "ML classification failed - check model file",
                    "image_id": image_id,
                    "filename": filename,
                    "ml_duration": ml_duration
                }), 500
        else:
            raise Exception("Image file was not created")
            
    except Exception as e:
        database.log_event("CAMERA_ERROR", str(e))
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500


@app.route('/api/camera/image/<filename>', methods=['GET'])
def download_image(filename):
    """Download captured image"""
    try:
        import os
        from flask import send_file
        
        safe_name = secure_filename(filename)
        if not safe_name or safe_name != filename:
            return jsonify({
                "success": False,
                "error": "Invalid filename"
            }), 400

        filepath = os.path.join(IMAGES_DIRECTORY, safe_name)
        
        if os.path.exists(filepath):
            database.log_event("IMAGE_DOWNLOAD", f"Downloaded: {filename}")
            return send_from_directory(IMAGES_DIRECTORY, safe_name, mimetype='image/jpeg')
        else:
            return jsonify({
                "success": False,
                "error": "Image not found"
            }), 404
            
    except Exception as e:
        database.log_event("IMAGE_DOWNLOAD_ERROR", str(e))
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


@app.route('/api/alert/send', methods=['POST'])
def send_alert():
    """Record an alert delivered by the mobile app."""
    try:
        data = request.get_json() or {}
        alert_id = data.get('alert_id')
        if not alert_id:
            return jsonify({'success': False, 'error': 'Missing alert_id'}), 400

        database.log_event('ALERT_SYNC', f'Alert synced: {alert_id}')
        return jsonify({'success': True, 'alert_id': alert_id}), 200
    except Exception as e:
        database.log_event('ALERT_SYNC_ERROR', str(e))
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/batch/start', methods=['POST'])
def start_batch():
    """Start a new drying batch with environmental conditions"""
    try:
        data = request.get_json()
        batch_name = data.get('batch_name', f"Batch_{datetime.now().strftime('%Y%m%d_%H%M%S')}")
        
        # Get current environmental conditions
        current_data = sensor_manager.get_environmental_data()
        
        batch_data = {
            "batch_id": f"CPR_{datetime.now().strftime('%Y%m%d_%H%M%S')}",
            "batch_name": batch_name,
            "start_time": datetime.now().isoformat(),
            "start_temperature": current_data["temperature"],
            "start_humidity": current_data["humidity"],
            "status": "active"
        }
        
        # Store in database (you'll need to add batch storage to database.py)
        conn = database.get_connection()
        cursor = conn.cursor()
        
        cursor.execute('''
            INSERT OR REPLACE INTO active_batch 
            (batch_id, batch_name, start_time, start_temperature, start_humidity, status)
            VALUES (?, ?, ?, ?, ?, ?)
        ''', (batch_data["batch_id"], batch_data["batch_name"], batch_data["start_time"], 
              batch_data["start_temperature"], batch_data["start_humidity"], batch_data["status"]))
        
        conn.commit()
        conn.close()
        
        database.log_event("BATCH_START", f"Started batch: {batch_data['batch_id']}")
        
        return jsonify({
            "success": True,
            "batch": batch_data
        }), 200
        
    except Exception as e:
        database.log_event("BATCH_ERROR", str(e))
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500


@app.route('/api/batch/update', methods=['POST'])
def update_batch():
    """Create or update a batch sent from the mobile app."""
    try:
        data = request.get_json() or {}
        batch_id = data.get('batch_id') or data.get('id')
        if not batch_id:
            return jsonify({'success': False, 'error': 'Missing batch_id'}), 400

        conn = database.get_connection()
        cursor = conn.cursor()
        cursor.execute('''
            INSERT INTO active_batch (
                batch_id, batch_name, start_time, end_time,
                start_temperature, start_humidity, end_temperature,
                end_humidity, average_temperature, average_humidity,
                quality_result, confidence, status
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(batch_id) DO UPDATE SET
                batch_name = excluded.batch_name,
                start_time = excluded.start_time,
                end_time = excluded.end_time,
                start_temperature = excluded.start_temperature,
                start_humidity = excluded.start_humidity,
                end_temperature = excluded.end_temperature,
                end_humidity = excluded.end_humidity,
                average_temperature = excluded.average_temperature,
                average_humidity = excluded.average_humidity,
                quality_result = excluded.quality_result,
                confidence = excluded.confidence,
                status = excluded.status
        ''', (
            batch_id,
            data.get('name', data.get('batch_name', batch_id)),
            data.get('startDate', data.get('start_time', datetime.now().isoformat())),
            data.get('endDate', data.get('end_time')),
            data.get('startTemperature', data.get('start_temperature')),
            data.get('startHumidity', data.get('start_humidity')),
            data.get('endTemperature', data.get('end_temperature')),
            data.get('endHumidity', data.get('end_humidity')),
            data.get('averageTemperature', data.get('average_temperature')),
            data.get('averageHumidity', data.get('average_humidity')),
            data.get('qualityResult', data.get('quality_result')),
            data.get('confidence'),
            data.get('status', 'active'),
        ))
        conn.commit()
        conn.close()
        database.log_event('BATCH_UPDATE', f'Updated batch: {batch_id}')
        return jsonify({'success': True, 'batch_id': batch_id}), 200
    except Exception as e:
        database.log_event('BATCH_UPDATE_ERROR', str(e))
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/batch/complete', methods=['POST'])
def complete_batch():
    """Complete current batch and store final data"""
    try:
        data = request.get_json()
        quality_result = data.get('quality_result')
        confidence = data.get('confidence')
        
        # Get current environmental conditions
        current_data = sensor_manager.get_environmental_data()
        
        # Get active batch
        conn = database.get_connection()
        cursor = conn.cursor()
        
        cursor.execute('SELECT * FROM active_batch WHERE status = "active" LIMIT 1')
        active_batch = cursor.fetchone()
        
        if not active_batch:
            return jsonify({
                "success": False,
                "error": "No active batch found"
            }), 400
        
        batch_id, batch_name, start_time, end_time, start_temp, start_hum, end_temp, end_hum, avg_temp_db, avg_hum_db, saved_quality, saved_confidence, status = active_batch
        
        # Calculate averages (simplified - you'd want to get actual sensor readings over time)
        avg_temp = (start_temp + current_data["temperature"]) / 2
        avg_hum = (start_hum + current_data["humidity"]) / 2
        
        # Update batch as completed
        cursor.execute('''
            UPDATE active_batch SET 
            status = "completed",
            end_time = ?,
            end_temperature = ?,
            end_humidity = ?,
            average_temperature = ?,
            average_humidity = ?,
            quality_result = ?,
            confidence = ?
            WHERE batch_id = ?
        ''', (datetime.now().isoformat(), current_data["temperature"], current_data["humidity"],
              avg_temp, avg_hum, quality_result, confidence, batch_id))
        
        conn.commit()
        conn.close()
        
        database.log_event("BATCH_COMPLETE", f"Completed batch: {batch_id} - {quality_result}")
        
        return jsonify({
            "success": True,
            "batch_id": batch_id,
            "quality_result": quality_result,
            "environmental_summary": {
                "start_temperature": start_temp,
                "end_temperature": current_data["temperature"],
                "average_temperature": avg_temp,
                "start_humidity": start_hum,
                "end_humidity": current_data["humidity"],
                "average_humidity": avg_hum
            }
        }), 200
        
    except Exception as e:
        database.log_event("BATCH_ERROR", str(e))
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500


@app.route('/api/batch/current', methods=['GET'])
def get_current_batch():
    """Get current active batch info"""
    try:
        conn = database.get_connection()
        cursor = conn.cursor()
        
        cursor.execute('SELECT * FROM active_batch WHERE status = "active" LIMIT 1')
        active_batch = cursor.fetchone()
        conn.close()
        
        if active_batch:
            batch_id, batch_name, start_time, end_time, start_temp, start_hum, end_temp, end_hum, avg_temp, avg_hum, quality_result, confidence, status = active_batch
            return jsonify({
                "success": True,
                "batch": {
                    "batch_id": batch_id,
                    "batch_name": batch_name,
                    "start_time": start_time,
                    "start_temperature": start_temp,
                    "start_humidity": start_hum,
                    "status": status
                }
            }), 200
        else:
            return jsonify({
                "success": True,
                "batch": None,
                "message": "No active batch"
            }), 200
            
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500


@app.route('/api/analytics/conditions-quality', methods=['GET'])
def analyze_conditions_quality():
    """Analyze relationship between environmental conditions and copra quality"""
    try:
        conn = database.get_connection()
        cursor = conn.cursor()
        
        # Get batches with both environmental data and quality results
        cursor.execute('''
            SELECT 
                average_temperature, average_humidity, quality_result, confidence,
                start_temperature, start_humidity, end_temperature, end_humidity
            FROM active_batch
            WHERE status = 'completed'
            AND quality_result IS NOT NULL
            AND average_temperature IS NOT NULL
            AND average_humidity IS NOT NULL
        ''')
        
        batches = cursor.fetchall()
        conn.close()
        
        if len(batches) < 3:
            # Not enough data for meaningful analysis
            return jsonify({
                "success": True,
                "message": "Insufficient data for analysis. Need at least 3 completed batches.",
                "batch_count": len(batches),
                "recommendations": {
                    "optimal_temperature": "60-65°C (Based on research)",
                    "optimal_humidity": "10-15% (Based on research)",
                    "note": "Complete more batches to get personalized insights"
                }
            }), 200
        
        # Analyze data by quality categories
        quality_analysis = {}
        
        for batch in batches:
            avg_temp, avg_hum, quality, confidence, start_temp, start_hum, end_temp, end_hum = batch
            
            if quality not in quality_analysis:
                quality_analysis[quality] = {
                    "count": 0,
                    "temperatures": [],
                    "humidities": [],
                    "confidences": []
                }
            
            quality_analysis[quality]["count"] += 1
            quality_analysis[quality]["temperatures"].append(avg_temp)
            quality_analysis[quality]["humidities"].append(avg_hum)
            quality_analysis[quality]["confidences"].append(confidence)
        
        # Calculate optimal ranges
        optimal_batches = quality_analysis.get("Optimally-dried", {})
        
        if optimal_batches.get("count", 0) > 0:
            optimal_temp_avg = sum(optimal_batches["temperatures"]) / len(optimal_batches["temperatures"])
            optimal_hum_avg = sum(optimal_batches["humidities"]) / len(optimal_batches["humidities"])
            
            temp_range_min = optimal_temp_avg - 3
            temp_range_max = optimal_temp_avg + 3
            hum_range_min = max(0, optimal_hum_avg - 2)
            hum_range_max = optimal_hum_avg + 2
        else:
            # Fallback to research-based recommendations
            optimal_temp_avg = 62.5
            optimal_hum_avg = 12.5
            temp_range_min = 60
            temp_range_max = 65
            hum_range_min = 10
            hum_range_max = 15
        
        # Generate insights
        insights = {
            "optimal_conditions": {
                "temperature_range": f"{temp_range_min:.1f}-{temp_range_max:.1f}°C",
                "humidity_range": f"{hum_range_min:.1f}-{hum_range_max:.1f}%",
                "average_optimal_temp": f"{optimal_temp_avg:.1f}°C",
                "average_optimal_humidity": f"{optimal_hum_avg:.1f}%"
            },
            "success_rate": {
                "total_batches": len(batches),
                "optimal_count": quality_analysis.get("Optimally-dried", {}).get("count", 0),
                "under_dried_count": quality_analysis.get("Under-dried", {}).get("count", 0),
                "over_dried_count": quality_analysis.get("Over-dried", {}).get("count", 0)
            },
            "recommendations": []
        }
        
        # Add specific recommendations
        if quality_analysis.get("Under-dried", {}).get("count", 0) > 0:
            under_temps = quality_analysis["Under-dried"]["temperatures"]
            avg_under_temp = sum(under_temps) / len(under_temps)
            if avg_under_temp < optimal_temp_avg - 5:
                insights["recommendations"].append(
                    f"Under-dried batches averaged {avg_under_temp:.1f}°C. Increase temperature to {temp_range_min:.1f}°C minimum."
                )
        
        if quality_analysis.get("Over-dried", {}).get("count", 0) > 0:
            over_temps = quality_analysis["Over-dried"]["temperatures"]
            avg_over_temp = sum(over_temps) / len(over_temps)
            if avg_over_temp > optimal_temp_avg + 5:
                insights["recommendations"].append(
                    f"Over-dried batches averaged {avg_over_temp:.1f}°C. Keep temperature below {temp_range_max:.1f}°C."
                )
        
        if not insights["recommendations"]:
            insights["recommendations"].append("Your drying conditions are consistent. Continue current practices.")
        
        database.log_event("ANALYTICS_REQUEST", "Environmental conditions analysis")
        
        return jsonify({
            "success": True,
            "insights": insights,
            "quality_breakdown": quality_analysis
        }), 200
        
    except Exception as e:
        database.log_event("ANALYTICS_ERROR", str(e))
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


@app.route('/api/exports', methods=['POST'])
def save_export():
    """Save a PDF or CSV export on the Raspberry Pi storage."""
    try:
        filename = secure_filename(request.args.get('filename', 'export.bin'))
        if not filename:
            return jsonify({'success': False, 'error': 'Invalid filename'}), 400

        os.makedirs(EXPORTS_DIRECTORY, exist_ok=True)
        filepath = os.path.join(EXPORTS_DIRECTORY, filename)
        with open(filepath, 'wb') as export_file:
            export_file.write(request.get_data())

        file_size = os.path.getsize(filepath)
        if file_size == 0:
            os.remove(filepath)
            raise Exception('Export received no data')

        database.log_event('EXPORT_SAVED', f'Export: {filename}')
        return jsonify({
            'success': True,
            'filename': filename,
            'filepath': os.path.abspath(filepath),
            'size': file_size,
            'verified': os.path.isfile(filepath),
        }), 200
    except Exception as e:
        database.log_event('EXPORT_ERROR', str(e))
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/exports', methods=['GET'])
def list_exports():
    """List files saved in the Raspberry Pi export directory."""
    try:
        os.makedirs(EXPORTS_DIRECTORY, exist_ok=True)
        files = []
        for filename in sorted(os.listdir(EXPORTS_DIRECTORY)):
            filepath = os.path.join(EXPORTS_DIRECTORY, filename)
            if os.path.isfile(filepath):
                files.append({
                    'filename': filename,
                    'filepath': os.path.abspath(filepath),
                    'size': os.path.getsize(filepath),
                })
        return jsonify({
            'success': True,
            'directory': os.path.abspath(EXPORTS_DIRECTORY),
            'files': files,
        }), 200
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/exports/<filename>', methods=['GET'])
def download_export(filename):
    """Download a saved PDF or CSV export from the Raspberry Pi."""
    safe_name = secure_filename(filename)
    if not safe_name or safe_name != filename:
        return jsonify({'success': False, 'error': 'Invalid filename'}), 400
    filepath = os.path.join(EXPORTS_DIRECTORY, safe_name)
    if not os.path.isfile(filepath):
        return jsonify({'success': False, 'error': 'Export not found'}), 404
    return send_from_directory(EXPORTS_DIRECTORY, safe_name, as_attachment=True)


@app.route('/api/system/logs', methods=['GET'])
def get_system_logs():
    """Get system logs (placeholder)"""
    return jsonify({
        "success": True,
        "message": "System logs endpoint"
    }), 200


@app.route('/api/camera/unlock', methods=['POST'])
def unlock_camera():
    """Force unlock camera if stuck"""
    try:
        # Kill camera processes
        subprocess.run(["sudo", "pkill", "-f", "rpicam"], check=False)
        subprocess.run(["sudo", "pkill", "-f", "libcamera"], check=False)
        subprocess.run(["sudo", "pkill", "-f", "camera"], check=False)
        
        time.sleep(1)
        
        # Reset camera module
        subprocess.run(["sudo", "modprobe", "-r", "bcm2835-v4l2"], check=False)
        time.sleep(0.5)
        subprocess.run(["sudo", "modprobe", "bcm2835-v4l2"], check=False)
        
        return jsonify({
            "success": True,
            "message": "Camera unlocked successfully"
        }), 200
        
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500


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
    print(f"Exports saved to {os.path.abspath(EXPORTS_DIRECTORY)}")
    print("Camera stream available on http://0.0.0.0:5000/api/camera/stream")
    database.log_event("STARTUP", "API Server started")
    
    # Run Flask app
    app.run(host='0.0.0.0', port=5000, debug=False, threaded=True)
