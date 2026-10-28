import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../../models/batch_model.dart';
import '../../../services/batch_service.dart';
import '../../../services/raspberry_pi_service.dart';
import '../../monitor/services/sensor_provider.dart';
import '../presentation/models/dashboard_state.dart';

final dashboardStateProvider = StateNotifierProvider<
    DashboardNotifier,
    DashboardState>((ref) {
  return DashboardNotifier(ref);
});

class DashboardNotifier extends StateNotifier<DashboardState> {
  final Ref _ref;
  final BatchService _batchService = BatchService();
  final RaspberryPiService _piService = RaspberryPiService();
  Timer? _batchRefreshTimer;
  Timer? _qualityRefreshTimer;

  DashboardNotifier(this._ref) : super(DashboardState()) {
    _init();

    // Get initial sensor state immediately
    final initialSensorState = _ref.read(sensorDataProvider);
    updateFromSensors(initialSensorState);

    // Listen to sensor updates
    _ref.listen<SensorReadingList>(
      sensorDataProvider,
      (previous, next) {
        updateFromSensors(next);
      },
    );

    // Periodically refresh active batches to detect new batch creation
    _startBatchRefreshTimer();

    // Periodically fetch latest quality result from backend
    _startQualityRefreshTimer();
  }

  void _startBatchRefreshTimer() {
    _batchRefreshTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _refreshActiveBatches(),
    );
  }

  void _startQualityRefreshTimer() {
    _qualityRefreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _fetchLatestQuality(),
    );
  }

  void _init() async {
    state = state.copyWith(isLoading: true);
    await _refreshActiveBatches();
    await _fetchLatestQuality();
  }

  Future<void> _refreshActiveBatches() async {
    try {
      final activeBatches = await _batchService.getActiveBatches();
      final currentBatch = activeBatches.isNotEmpty ? activeBatches.first : null;

      // Only update if batch actually changed to avoid unnecessary rebuilds
      if (state.currentBatch?.id != currentBatch?.id) {
        state = state.copyWith(
          currentBatch: currentBatch,
          isLoading: false,
        );
      } else if (state.isLoading) {
        // Mark as loaded even if batch didn't change
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      print('Error refreshing active batches: $e');
      // Still mark as loaded even if error
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _fetchLatestQuality() async {
    try {
      final qualityResult = await _piService.getLatestQualityResult();
      if (!mounted) return; // Safety check

      // Save quality result to the specific batch if batch_id is present
      if (qualityResult != null && qualityResult.isNotEmpty) {
        final batchId = qualityResult['batch_id'] as String?;
        if (batchId != null && batchId.isNotEmpty) {
          final classification = qualityResult['classification'] as String?;
          final confidence = qualityResult['confidence'] as double?;
          if (classification != null && confidence != null) {
            await _batchService.saveQualityResult(
              batchId: batchId,
              classification: classification,
              confidence: confidence,
            );
          }
        }
      }

      state = state.copyWith(
        latestQualityResult: qualityResult,
      );
    } catch (e) {
      print('Error fetching latest quality: $e');
      // Don't update state on error, keep previous result
    }
  }

  // Public method to force refresh (e.g. when batch is completed)
  Future<void> refreshBatches() async {
    await _refreshActiveBatches();
  }

  void updateFromSensors(SensorReadingList sensorState) {
    state = state.copyWith(
      latestReading: sensorState.latest,
      isConnected: sensorState.isConnected,
    );
    
    // If we have an active batch, update its readings
    if (state.currentBatch != null && sensorState.latest != null) {
      final updatedBatch = state.currentBatch!.copyWith(
        readings: [...state.currentBatch!.readings, sensorState.latest!],
      );
      state = state.copyWith(currentBatch: updatedBatch);
    }
  }

  void markNotificationsAsRead() {
    state = state.copyWith(unreadNotifications: 0);
  }

  @override
  void dispose() {
    _batchRefreshTimer?.cancel();
    _qualityRefreshTimer?.cancel();
    super.dispose();
  }
}
