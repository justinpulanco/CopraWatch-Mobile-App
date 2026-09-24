import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models/scan_result.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'copra_watch.db');

    return openDatabase(
      path,
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    final columns = await db.rawQuery('PRAGMA table_info(scan_results)');
    final columnNames = columns.map((column) => column['name']).toSet();
    if (!columnNames.contains('moisture')) {
      await db.execute(
        "ALTER TABLE scan_results ADD COLUMN moisture REAL NOT NULL DEFAULT 0",
      );
    }
    if (!columnNames.contains('moistureStatus')) {
      await db.execute(
        "ALTER TABLE scan_results ADD COLUMN moistureStatus TEXT NOT NULL DEFAULT 'unknown'",
      );
    }
    final batchColumns = await db.rawQuery('PRAGMA table_info(batches)');
    final batchColumnNames = batchColumns.map((column) => column['name']).toSet();
    if (!batchColumnNames.contains('initialMoistureStatus')) {
      await db.execute("ALTER TABLE batches ADD COLUMN initialMoistureStatus TEXT NOT NULL DEFAULT 'basa-basa'");
    }
    if (!batchColumnNames.contains('finalMoistureStatus')) {
      await db.execute("ALTER TABLE batches ADD COLUMN finalMoistureStatus TEXT NOT NULL DEFAULT 'basa-basa'");
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Scan results table
    await db.execute('''
      CREATE TABLE scan_results (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        classification TEXT NOT NULL,
        confidence REAL NOT NULL,
        imagePath TEXT NOT NULL,
        moisture REAL NOT NULL DEFAULT 0,
        moistureStatus TEXT NOT NULL DEFAULT 'unknown',
        timestamp TEXT NOT NULL,
        batchId TEXT NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Batches table for batch management
    await db.execute('''
      CREATE TABLE batches (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        startDate TEXT NOT NULL,
        endDate TEXT,
        initialMoisture REAL NOT NULL,
        finalMoisture REAL NOT NULL,
        initialMoistureStatus TEXT NOT NULL DEFAULT 'basa-basa',
        finalMoistureStatus TEXT NOT NULL DEFAULT 'basa-basa',
        status TEXT NOT NULL,
        qualityResult TEXT,
        confidence REAL,
        notes TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Alerts table for temp/humidity alerts
    await db.execute('''
      CREATE TABLE alerts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        batchId TEXT NOT NULL,
        alertType TEXT NOT NULL,
        value REAL NOT NULL,
        threshold REAL NOT NULL,
        timestamp TEXT NOT NULL,
        acknowledged INTEGER DEFAULT 0,
        FOREIGN KEY (batchId) REFERENCES batches(id)
      )
    ''');

    // Pending sync table for offline data
    await db.execute('''
      CREATE TABLE pending_sync (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dataType TEXT NOT NULL,
        dataId TEXT NOT NULL,
        data TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');
  }

  Future<int> insertScanResult(ScanResult result) async {
    final db = await database;
    return db.insert('scan_results', result.toMap());
  }

  Future<List<ScanResult>> getAllScanResults() async {
    final db = await database;
    final maps = await db.query('scan_results', orderBy: 'timestamp DESC');
    return maps.map((map) => ScanResult.fromMap(map)).toList();
  }

  Future<int> deleteScanResult(int id) async {
    final db = await database;
    return db.delete('scan_results', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteAllScanResults() async {
    final db = await database;
    return db.delete('scan_results');
  }

  // Batch management methods
  Future<int> insertBatch(Map<String, dynamic> batch) async {
    final db = await database;
    await db.insert('batches', batch);
    return 1;
  }

  Future<List<Map<String, dynamic>>> getAllBatches() async {
    final db = await database;
    return db.query('batches', orderBy: 'startDate DESC');
  }

  Future<Map<String, dynamic>?> getBatchById(String id) async {
    final db = await database;
    final result = await db.query('batches', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updateBatch(Map<String, dynamic> batch) async {
    final db = await database;
    return db.update('batches', batch, where: 'id = ?', whereArgs: [batch['id']]);
  }

  Future<int> deleteBatch(String id) async {
    final db = await database;
    return db.delete('batches', where: 'id = ?', whereArgs: [id]);
  }

  // Alert methods
  Future<int> insertAlert(Map<String, dynamic> alert) async {
    final db = await database;
    return db.insert('alerts', alert);
  }

  Future<List<Map<String, dynamic>>> getAlertsByBatch(String batchId) async {
    final db = await database;
    return db.query('alerts', where: 'batchId = ?', whereArgs: [batchId], orderBy: 'timestamp DESC');
  }

  Future<int> acknowledgeAlert(int alertId) async {
    final db = await database;
    return db.update('alerts', {'acknowledged': 1}, where: 'id = ?', whereArgs: [alertId]);
  }

  // Pending sync methods
  Future<int> insertPendingSync(Map<String, dynamic> data) async {
    final db = await database;
    return db.insert('pending_sync', data);
  }

  Future<List<Map<String, dynamic>>> getPendingSync() async {
    final db = await database;
    return db.query('pending_sync', where: 'synced = 0');
  }

  Future<int> markSyncComplete(int id) async {
    final db = await database;
    return db.update('pending_sync', {'synced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deletePendingSync(int id) async {
    final db = await database;
    return db.delete('pending_sync', where: 'id = ?', whereArgs: [id]);
  }
}
