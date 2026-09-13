import 'dart:convert';
import '../database/database_helper.dart';
import 'api_service.dart';

class SyncService {
  final DatabaseHelper _db = DatabaseHelper();
  final ApiService _api = ApiService();

  // Add data to pending sync
  Future<void> addPendingSync({
    required String dataType,
    required String dataId,
    required Map<String, dynamic> data,
  }) async {
    final pendingData = {
      'dataType': dataType,
      'dataId': dataId,
      'data': jsonEncode(data),
      'timestamp': DateTime.now().toIso8601String(),
      'synced': 0,
    };
    await _db.insertPendingSync(pendingData);
  }

  // Sync all pending data
  Future<void> syncAllPendingData() async {
    final pendingItems = await _db.getPendingSync();

    for (var item in pendingItems) {
      try {
        final data = jsonDecode(item['data']);
        bool success = false;

        // Sync based on dataType
        switch (item['dataType']) {
          case 'scan_result':
            success = await _api.sendClassification(
              imageId: item['dataId'],
              classification: data['classification'],
              confidence: data['confidence'],
            );
            break;
          case 'batch':
            success = await _api.sendBatchUpdate(
              batchId: item['dataId'],
              data: data,
            );
            break;
          case 'alert':
            success = await _api.sendAlert(
              alertId: item['dataId'],
              data: data,
            );
            break;
          default:
            success = false;
        }

        // Mark as synced if successful
        if (success) {
          await _db.markSyncComplete(item['id']);
        }
      } catch (e) {
        print('Sync error for ${item['dataId']}: $e');
        // Continue with next item
      }
    }
  }

  // Get pending count
  Future<int> getPendingCount() async {
    final pending = await _db.getPendingSync();
    return pending.length;
  }

  // Clear all pending (after manual confirmation)
  Future<void> clearAllPending() async {
    final pending = await _db.getPendingSync();
    for (var item in pending) {
      await _db.deletePendingSync(item['id']);
    }
  }
}
