import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/batch_model.dart';
import '../../../services/batch_service.dart';
import '../../monitor/services/sensor_provider.dart';
import '../presentation/models/dashboard_state.dart';

final dashboardStateProvider = StateNotifierProvider<
    DashboardNotifier,
    DashboardState>((ref) {
  return DashboardNotifier(ref);
});

class DashboardNotifier extends StateNotifier<DashboardState> {
  final Ref _ref;
  
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
  }

  void _init() async {
    state = state.copyWith(isLoading: true);

    final activeBatches = await BatchService().getActiveBatches();
    state = state.copyWith(
      currentBatch: activeBatches.isNotEmpty ? activeBatches.first : null,
      isLoading: false,
    );
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
}
