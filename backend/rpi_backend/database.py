"""
SQLite Database for RPI Backend
Stores sensor readings, images, and classifications
"""
import sqlite3
import time
from datetime import datetime
from pathlib import Path


class RPiDatabase:
    """RPI Backend Database"""

    def __init__(self, db_path="copra_data.db"):
        self.db_path = db_path
        self.init_database()

    def get_connection(self):
        """Get database connection with retry logic"""
        max_retries = 3
        retry_delay = 0.1  # Start with 100ms delay

        for attempt in range(max_retries):
            try:
                conn = sqlite3.connect(self.db_path)
                # Enable foreign key constraints
                conn.execute("PRAGMA foreign_keys = ON")
                return conn
            except sqlite3.OperationalError as e:
                if "database is locked" in str(e).lower() and attempt < max_retries - 1:
                    # Wait and retry for locked database
                    time.sleep(retry_delay)
                    retry_delay *= 2  # Exponential backoff
                    continue
                else:
                    # Re-raise if it's not a lock error or we've exhausted retries
                    raise
            except Exception as e:
                # Re-raise any other exceptions
                raise

        # This should never be reached due to the retry logic, but just in case
        raise sqlite3.OperationalError("Failed to get database connection after retries")
    
    def init_database(self):
        """Initialize database tables"""
        conn = self.get_connection()
        cursor = conn.cursor()
        
        # Environmental data table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS environmental_data (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                temperature REAL NOT NULL,
                humidity REAL NOT NULL,
                timestamp TEXT NOT NULL
            )
        ''')
        
        # Image capture log table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS images (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                filename TEXT NOT NULL,
                capture_time TEXT NOT NULL,
                file_path TEXT NOT NULL
            )
        ''')
        
        # ML classification results table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS classifications (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                image_id INTEGER NOT NULL,
                classification TEXT NOT NULL,
                confidence REAL NOT NULL,
                classification_time TEXT NOT NULL,
                FOREIGN KEY(image_id) REFERENCES images(id)
            )
        ''')
        
        # System logs table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS system_logs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                event_type TEXT NOT NULL,
                message TEXT,
                timestamp TEXT NOT NULL
            )
        ''')
        
        # Active batch tracking table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS active_batch (
                batch_id TEXT PRIMARY KEY,
                batch_name TEXT NOT NULL,
                start_time TEXT NOT NULL,
                end_time TEXT,
                start_temperature REAL,
                start_humidity REAL,
                end_temperature REAL,
                end_humidity REAL,
                average_temperature REAL,
                average_humidity REAL,
                quality_result TEXT,
                confidence REAL,
                status TEXT DEFAULT 'active'
            )
        ''')

        cursor.execute('''
            CREATE TABLE IF NOT EXISTS quality_assessments (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                batch_id TEXT NOT NULL,
                image_path TEXT NOT NULL,
                classification TEXT NOT NULL,
                confidence REAL NOT NULL,
                timestamp TEXT NOT NULL,
                FOREIGN KEY(batch_id) REFERENCES active_batch(batch_id)
            )
        ''')
        
        conn.commit()
        conn.close()
    
    def insert_environmental_data(self, temperature, humidity):
        """Store sensor readings with error handling"""
        conn = None
        try:
            conn = self.get_connection()
            cursor = conn.cursor()

            cursor.execute('''
                INSERT INTO environmental_data (temperature, humidity, timestamp)
                VALUES (?, ?, ?)
            ''', (temperature, humidity, datetime.now().isoformat()))

            conn.commit()
        except Exception as e:
            # Log the error but don't crash - sensor data loss is preferable to system failure
            print(f"Warning: Failed to store environmental data: {e}")
            raise  # Re-raise so callers can handle it if needed
        finally:
            if conn:
                conn.close()
    
    def insert_image(self, filename, file_path):
        """Log captured image with error handling"""
        conn = None
        try:
            conn = self.get_connection()
            cursor = conn.cursor()

            cursor.execute('''
                INSERT INTO images (filename, capture_time, file_path)
                VALUES (?, ?, ?)
            ''', (filename, datetime.now().isoformat(), file_path))

            conn.commit()
            image_id = cursor.lastrowid

            return image_id
        except Exception as e:
            # Log the error but don't crash - image logging failure is preferable to system failure
            print(f"Warning: Failed to log captured image: {e}")
            raise  # Re-raise so callers can handle it if needed
        finally:
            if conn:
                conn.close()
    
    def insert_classification(self, image_id, classification, confidence):
        """Store ML classification result with error handling"""
        conn = None
        try:
            conn = self.get_connection()
            cursor = conn.cursor()

            cursor.execute('''
                INSERT INTO classifications (image_id, classification, confidence, classification_time)
                VALUES (?, ?, ?, ?)
            ''', (image_id, classification, confidence, datetime.now().isoformat()))

            conn.commit()
        except Exception as e:
            # Log the error but don't crash - classification storage failure is preferable to system failure
            print(f"Warning: Failed to store classification result: {e}")
            raise  # Re-raise so callers can handle it if needed
        finally:
            if conn:
                conn.close()
    
    def get_latest_quality_assessment(self):
        """Return the most recent device-captured assessment, if one exists."""
        conn = self.get_connection()
        conn.row_factory = sqlite3.Row
        try:
            row = conn.execute('''
                SELECT id, batch_id, image_path, classification, confidence, timestamp
                FROM quality_assessments
                ORDER BY timestamp DESC, id DESC
                LIMIT 1
            ''').fetchone()
            return dict(row) if row else None
        finally:
            conn.close()

    def get_quality_assessments_for_batch(self, batch_id):
        """Return a batch's quality assessments newest first."""
        conn = self.get_connection()
        conn.row_factory = sqlite3.Row
        try:
            rows = conn.execute('''
                SELECT id, batch_id, image_path, classification, confidence, timestamp
                FROM quality_assessments
                WHERE batch_id = ?
                ORDER BY timestamp DESC, id DESC
            ''', (batch_id,)).fetchall()
            return [dict(row) for row in rows]
        finally:
            conn.close()

    def get_latest_environmental_data(self, limit=10):
        """Get latest sensor readings with error handling"""
        conn = None
        try:
            conn = self.get_connection()
            cursor = conn.cursor()

            cursor.execute('''
                SELECT temperature, humidity, timestamp
                FROM environmental_data
                ORDER BY timestamp DESC
                LIMIT ?
            ''', (limit,))

            results = cursor.fetchall()

            return [
                {
                    "temperature": row[0],
                    "humidity": row[1],
                    "timestamp": row[2]
                }
                for row in results
            ]
        except Exception as e:
            # Log the error but don't crash - returning empty list is preferable to system failure
            print(f"Warning: Failed to get latest environmental data: {e}")
            return []  # Return empty list on error
        finally:
            if conn:
                conn.close()
    
    def get_all_classifications(self):
        """Get all classification results with error handling"""
        conn = None
        try:
            conn = self.get_connection()
            cursor = conn.cursor()

            cursor.execute('''
                SELECT i.filename, c.classification, c.confidence, c.classification_time
                FROM classifications c
                JOIN images i ON c.image_id = i.id
                ORDER BY c.classification_time DESC
            ''')

            results = cursor.fetchall()

            return [
                {
                    "image": row[0],
                    "classification": row[1],
                    "confidence": row[2],
                    "timestamp": row[3]
                }
                for row in results
            ]
        except Exception as e:
            # Log the error but don't crash - returning empty list is preferable to system failure
            print(f"Warning: Failed to get all classifications: {e}")
            return []  # Return empty list on error
        finally:
            if conn:
                conn.close()
    
    def log_event(self, event_type, message=None):
        """Log system events with error handling"""
        conn = None
        try:
            conn = self.get_connection()
            cursor = conn.cursor()

            cursor.execute('''
                INSERT INTO system_logs (event_type, message, timestamp)
                VALUES (?, ?, ?)
            ''', (event_type, message, datetime.now().isoformat()))

            conn.commit()
        except Exception as e:
            # Log the error but don't crash - event logging failure is preferable to system failure
            # Note: We avoid recursive logging by using print instead of calling log_event itself
            print(f"Warning: Failed to log system event: {e}")
        finally:
            if conn:
                conn.close()
