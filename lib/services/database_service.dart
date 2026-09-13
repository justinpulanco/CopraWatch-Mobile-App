import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../core/constants/app_constants.dart';

/// SQLite Database Service
/// Manages local data persistence

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, AppConstants.databaseName);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  /// Create database tables
  Future<void> _createDatabase(Database db, int version) async {
    // Batches table
    await db.execute('''
      CREATE TABLE batches(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        startDate TEXT NOT NULL,
        endDate TEXT,
        initialMoisture REAL NOT NULL,
        finalMoisture REAL NOT NULL,
        status TEXT NOT NULL,
        qualityResult TEXT,
        confidence REAL,
        notes TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Sensor readings table
    await db.execute('''
      CREATE TABLE sensor_readings(
        id TEXT PRIMARY KEY,
        batchId TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        temperature REAL NOT NULL,
        humidity REAL NOT NULL,
        moisture REAL NOT NULL,
        solarIrradiance REAL NOT NULL,
        FOREIGN KEY(batchId) REFERENCES batches(id)
      )
    ''');

    // Notifications table
    await db.execute('''
      CREATE TABLE notifications(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        type TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        isRead INTEGER NOT NULL,
        actionUrl TEXT,
        batchId TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Quality predictions table
    await db.execute('''
      CREATE TABLE quality_predictions(
        id TEXT PRIMARY KEY,
        batchId TEXT NOT NULL,
        imagePath TEXT,
        classification TEXT NOT NULL,
        confidence REAL NOT NULL,
        timestamp TEXT NOT NULL,
        modelName TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  /// Upgrade database schema
  Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Handle migrations here
    if (oldVersion < newVersion) {
      // TODO: Add migration logic
    }
  }

  // BATCH OPERATIONS

  /// Insert new batch
  Future<int> insertBatch(Map<String, dynamic> batch) async {
    final db = await database;
    return await db.insert('batches', batch);
  }

  /// Get all batches
  Future<List<Map<String, dynamic>>> getAllBatches() async {
    final db = await database;
    return await db.query('batches', orderBy: 'startDate DESC');
  }

  /// Get batch by ID
  Future<Map<String, dynamic>?> getBatchById(String id) async {
    final db = await database;
    final results = await db.query('batches', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  /// Update batch
  Future<int> updateBatch(Map<String, dynamic> batch) async {
    final db = await database;
    return await db.update(
      'batches',
      batch,
      where: 'id = ?',
      whereArgs: [batch['id']],
    );
  }

  /// Delete batch
  Future<int> deleteBatch(String id) async {
    final db = await database;
    return await db.delete('batches', where: 'id = ?', whereArgs: [id]);
  }

  // SENSOR READING OPERATIONS

  /// Insert sensor reading
  Future<int> insertSensorReading(Map<String, dynamic> reading) async {
    final db = await database;
    return await db.insert('sensor_readings', reading);
  }

  /// Get sensor readings for batch
  Future<List<Map<String, dynamic>>> getSensorReadingsByBatch(
    String batchId,
  ) async {
    final db = await database;
    return await db.query(
      'sensor_readings',
      where: 'batchId = ?',
      whereArgs: [batchId],
      orderBy: 'timestamp ASC',
    );
  }

  /// Delete sensor readings for batch
  Future<int> deleteSensorReadingsByBatch(String batchId) async {
    final db = await database;
    return await db.delete(
      'sensor_readings',
      where: 'batchId = ?',
      whereArgs: [batchId],
    );
  }

  // NOTIFICATION OPERATIONS

  /// Insert notification
  Future<int> insertNotification(Map<String, dynamic> notification) async {
    final db = await database;
    return await db.insert('notifications', notification);
  }

  /// Get all notifications
  Future<List<Map<String, dynamic>>> getAllNotifications() async {
    final db = await database;
    return await db.query('notifications', orderBy: 'timestamp DESC');
  }

  /// Get unread notifications
  Future<List<Map<String, dynamic>>> getUnreadNotifications() async {
    final db = await database;
    return await db.query(
      'notifications',
      where: 'isRead = ?',
      whereArgs: [0],
      orderBy: 'timestamp DESC',
    );
  }

  /// Update notification
  Future<int> updateNotification(Map<String, dynamic> notification) async {
    final db = await database;
    return await db.update(
      'notifications',
      notification,
      where: 'id = ?',
      whereArgs: [notification['id']],
    );
  }

  /// Delete notification
  Future<int> deleteNotification(String id) async {
    final db = await database;
    return await db.delete('notifications', where: 'id = ?', whereArgs: [id]);
  }

  // QUALITY PREDICTION OPERATIONS

  /// Insert quality prediction
  Future<int> insertQualityPrediction(
    Map<String, dynamic> prediction,
  ) async {
    final db = await database;
    return await db.insert('quality_predictions', prediction);
  }

  /// Get quality predictions for batch
  Future<List<Map<String, dynamic>>> getQualityPredictionsByBatch(
    String batchId,
  ) async {
    final db = await database;
    return await db.query(
      'quality_predictions',
      where: 'batchId = ?',
      whereArgs: [batchId],
      orderBy: 'timestamp DESC',
    );
  }

  /// Clear old data (for maintenance)
  Future<void> clearOldData({int daysToKeep = 90}) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

    await db.delete(
      'notifications',
      where: 'timestamp < ?',
      whereArgs: [cutoffDate.toIso8601String()],
    );

    await db.delete(
      'quality_predictions',
      where: 'timestamp < ?',
      whereArgs: [cutoffDate.toIso8601String()],
    );
  }

  /// Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
