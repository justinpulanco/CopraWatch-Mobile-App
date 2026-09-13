"""
SQLite Database for RPI Backend
Stores sensor readings, images, and classifications
"""
import sqlite3
from datetime import datetime
from pathlib import Path


class RPiDatabase:
    """RPI Backend Database"""
    
    def __init__(self, db_path="copra_data.db"):
        self.db_path = db_path
        self.init_database()
    
    def get_connection(self):
        """Get database connection"""
        return sqlite3.connect(self.db_path)
    
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
        
        conn.commit()
        conn.close()
    
    def insert_environmental_data(self, temperature, humidity):
        """Store sensor readings"""
        conn = self.get_connection()
        cursor = conn.cursor()
        
        cursor.execute('''
            INSERT INTO environmental_data (temperature, humidity, timestamp)
            VALUES (?, ?, ?)
        ''', (temperature, humidity, datetime.now().isoformat()))
        
        conn.commit()
        conn.close()
    
    def insert_image(self, filename, file_path):
        """Log captured image"""
        conn = self.get_connection()
        cursor = conn.cursor()
        
        cursor.execute('''
            INSERT INTO images (filename, capture_time, file_path)
            VALUES (?, ?, ?)
        ''', (filename, datetime.now().isoformat(), file_path))
        
        conn.commit()
        image_id = cursor.lastrowid
        conn.close()
        
        return image_id
    
    def insert_classification(self, image_id, classification, confidence):
        """Store ML classification result"""
        conn = self.get_connection()
        cursor = conn.cursor()
        
        cursor.execute('''
            INSERT INTO classifications (image_id, classification, confidence, classification_time)
            VALUES (?, ?, ?, ?)
        ''', (image_id, classification, confidence, datetime.now().isoformat()))
        
        conn.commit()
        conn.close()
    
    def get_latest_environmental_data(self, limit=10):
        """Get latest sensor readings"""
        conn = self.get_connection()
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT temperature, humidity, timestamp 
            FROM environmental_data 
            ORDER BY timestamp DESC 
            LIMIT ?
        ''', (limit,))
        
        results = cursor.fetchall()
        conn.close()
        
        return [
            {
                "temperature": row[0],
                "humidity": row[1],
                "timestamp": row[2]
            }
            for row in results
        ]
    
    def get_all_classifications(self):
        """Get all classification results"""
        conn = self.get_connection()
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT i.filename, c.classification, c.confidence, c.classification_time
            FROM classifications c
            JOIN images i ON c.image_id = i.id
            ORDER BY c.classification_time DESC
        ''')
        
        results = cursor.fetchall()
        conn.close()
        
        return [
            {
                "image": row[0],
                "classification": row[1],
                "confidence": row[2],
                "timestamp": row[3]
            }
            for row in results
        ]
    
    def log_event(self, event_type, message=None):
        """Log system events"""
        conn = self.get_connection()
        cursor = conn.cursor()
        
        cursor.execute('''
            INSERT INTO system_logs (event_type, message, timestamp)
            VALUES (?, ?, ?)
        ''', (event_type, message, datetime.now().isoformat()))
        
        conn.commit()
        conn.close()
