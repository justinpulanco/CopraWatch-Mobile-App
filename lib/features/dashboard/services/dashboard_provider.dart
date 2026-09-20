import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/batch_model.dart';
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

    // Simulate initial loading
    await Future.delayed(const Duration(milliseconds: 500));
    
    // In a real app, you'd fetch the active batch from a database
    // For now, we'll keep the currentBatch logic as is or make it empty
    state = state.copyWith(
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
