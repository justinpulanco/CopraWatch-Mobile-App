import '../database/database_helper.dart';
import '../models/batch_model.dart';
import 'sync_service.dart';
import 'api_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class BatchService {
  final DatabaseHelper _db = DatabaseHelper();
  final SyncService _sync = SyncService();
  final ApiService _api = ApiService();

  // Create new batch
  Future<Batch> createBatch({
    required String name,
    required double initialMoisture,
    String initialMoistureStatus = 'basa-basa',
  }) async {
    final batch = Batch(
      name: name,
      startDate: DateTime.now(),
      initialMoisture: initialMoisture,
      initialMoistureStatus: initialMoistureStatus,
      finalMoisture: initialMoisture,
      finalMoistureStatus: initialMoistureStatus, // Set same as initial
      status: 'active',
      readings: [],
    );

    final batchMap = {
      ...batch.toMap(),
      'createdAt': DateTime.now().toIso8601String(),
    };

    try {
      await _db.insertBatch(batchMap);
      print('Batch created successfully: ${batch.id}');
    } catch (e) {
      print('Error creating batch: $e');
      rethrow;
    }
    
    // Queue for sync if offline
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      await _sync.addPendingSync(
        dataType: 'batch',
        dataId: batch.id,
        data: batchMap,
      );
    }
    
    return batch;
  }

  // Get all batches
  Future<List<Batch>> getAllBatches() async {
    final maps = await _db.getAllBatches();
    return maps.map((map) => Batch.fromMap(map)).toList();
  }

  // Get batch by ID
  Future<Batch?> getBatchById(String id) async {
    final map = await _db.getBatchById(id);
    return map != null ? Batch.fromMap(map) : null;
  }

  // Update batch status
  Future<void> updateBatchStatus(String batchId, String status) async {
    final batch = await _db.getBatchById(batchId);
    if (batch != null) {
      final updatedBatch = {
        ...batch,
        'status': status,
        'endDate': status == 'completed' ? DateTime.now().toIso8601String() : null,
      };
      await _db.updateBatch(updatedBatch);
    }
  }

  // Complete batch
  Future<void> completeBatch(String batchId, double finalMoisture) async {
    final batch = await _db.getBatchById(batchId);
    if (batch != null) {
      final updatedBatch = {
        ...batch,
        'status': 'completed',
        'finalMoisture': finalMoisture,
        'endDate': DateTime.now().toIso8601String(),
      };
      await _db.updateBatch(updatedBatch);
    }
  }

  Future<void> completeBatchWithStatus(
    String batchId,
    double finalMoisture,
    String finalMoistureStatus,
  ) async {
    try {
      final batch = await _db.getBatchById(batchId);
      if (batch != null) {
        // Fetch current environmental data
        final envData = await _api.getEnvironmentalData();
        
        final endTemp = envData?.temperature ?? 0.0;
        final endHumid = envData?.humidity ?? 0.0;
        
        // Calculate averages
        final startTemp = batch['startTemperature'] ?? endTemp;
        final startHumid = batch['startHumidity'] ?? endHumid;
        final avgTemp = (startTemp + endTemp) / 2;
        final avgHumid = (startHumid + endHumid) / 2;
        
        await _db.updateBatch({
          ...batch,
          'status': 'completed',
          'finalMoisture': finalMoisture,
          'finalMoistureStatus': finalMoistureStatus,
          'endDate': DateTime.now().toIso8601String(),
          'endTemperature': endTemp,
          'endHumidity': endHumid,
          'averageTemperature': avgTemp,
          'averageHumidity': avgHumid,
        });
        
        print('Batch completed with temp: ${endTemp}°C, humidity: ${endHumid}%');
      }
    } catch (e) {
      print('Error completing batch: $e');
      rethrow;
    }
  }

  // Pause batch
  Future<void> pauseBatch(String batchId) async {
    final batch = await _db.getBatchById(batchId);
    if (batch != null && batch['status'] == 'active') {
      await _db.updateBatch({
        ...batch,
        'status': 'paused',
        'pausedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  // Resume batch
  Future<void> resumeBatch(String batchId) async {
    final batch = await _db.getBatchById(batchId);
    if (batch != null && batch['status'] == 'paused') {
      // Calculate paused duration
      final pausedAt = batch['pausedAt'] != null 
          ? DateTime.parse(batch['pausedAt']) 
          : DateTime.now();
      final pausedMinutes = DateTime.now().difference(pausedAt).inMinutes;
      final totalPausedMinutes = (batch['pausedDurationMinutes'] ?? 0) + pausedMinutes;
      
      await _db.updateBatch({
        ...batch,
        'status': 'active',
        'pausedAt': null,
        'pausedDurationMinutes': totalPausedMinutes,
      });
    }
  }

  // Get active batches
  Future<List<Batch>> getActiveBatches() async {
    final allBatches = await getAllBatches();
    return allBatches.where((b) => b.isActive).toList();
  }

  Future<void> saveQualityResult({
    required String batchId,
    required String classification,
    required double confidence,
  }) async {
    final batch = await _db.getBatchById(batchId);
    if (batch == null) throw Exception('Batch not found');

    await _db.updateBatch({
      ...batch,
      'qualityResult': classification,
      'confidence': confidence,
    });
  }

  // Get batch statistics
  Future<Map<String, dynamic>> getBatchStats(String batchId) async {
    final batch = await _db.getBatchById(batchId);
    if (batch == null) return {};

    final duration = Batch.fromMap(batch).dryingDuration;
    final moistureReduction = Batch.fromMap(batch).moistureReduction;

    return {
      'durationMinutes': duration.inMinutes,
      'durationHours': duration.inHours,
      'moistureReduction': moistureReduction,
      'startDate': batch['startDate'],
      'endDate': batch['endDate'],
      'qualityResult': batch['qualityResult'],
      'confidence': batch['confidence'],
    };
  }
}
