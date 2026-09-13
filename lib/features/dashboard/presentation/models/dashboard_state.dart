import '../../../../models/batch_model.dart';

class DashboardState {
  final Batch? currentBatch;
  final SensorReading? latestReading;
  final int unreadNotifications;
  final bool isConnected;
  final bool isLoading;

  DashboardState({
    this.currentBatch,
    this.latestReading,
    this.unreadNotifications = 0,
    this.isConnected = false,
    this.isLoading = false,
  });

  double get dryingProgress {
    if (currentBatch == null) return 0;
    final duration = currentBatch!.dryingDuration.inMinutes;
    final estimated = 48 * 60; // 48 hours in minutes
    return (duration / estimated).clamp(0, 1);
  }

  DashboardState copyWith({
    Batch? currentBatch,
    SensorReading? latestReading,
    int? unreadNotifications,
    bool? isConnected,
    bool? isLoading,
  }) {
    return DashboardState(
      currentBatch: currentBatch ?? this.currentBatch,
      latestReading: latestReading ?? this.latestReading,
      unreadNotifications: unreadNotifications ?? this.unreadNotifications,
      isConnected: isConnected ?? this.isConnected,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
