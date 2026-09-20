import '../database/database_helper.dart';
import '../models/batch_model.dart';
import 'sync_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class BatchService {
  final DatabaseHelper _db = DatabaseHelper();
  final SyncService _sync = SyncService();

  // Create new batch
  Future<Batch> createBatch({
    required String name,
    required double initialMoisture,
  }) async {
    final batch = Batch(
      name: name,
      startDate: DateTime.now(),
      initialMoisture: initialMoisture,
      finalMoisture: initialMoisture,
      status: 'active',
      readings: [],
    );

    final batchMap = {
      ...batch.toMap(),
      'createdAt': DateTime.now().toIso8601String(),
    };

    await _db.insertBatch(batchMap);
    
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

  // Get active batches
  Future<List<Batch>> getActiveBatches() async {
    final allBatches = await getAllBatches();
    return allBatches.where((b) => b.isActive).toList();
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
