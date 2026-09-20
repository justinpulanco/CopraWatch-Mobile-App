import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../../../models/batch_model.dart';
import '../../../models/notification_model.dart';
import '../../../services/raspberry_pi_service.dart';
import '../../../services/alert_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/sync_service.dart';
import '../../../widgets/alert_overlay.dart';
import '../../../main.dart';

final sensorDataProvider =
    StateNotifierProvider<SensorNotifier, SensorReadingList>((ref) {
  return SensorNotifier();
});

class SensorReadingList {
  final List<SensorReading> readings;
  final SensorReading? latest;
  final bool isConnected;

  SensorReadingList({
    required this.readings,
    this.latest,
    this.isConnected = false,
  });

  SensorReadingList copyWith({
    List<SensorReading>? readings,
    SensorReading? latest,
    bool? isConnected,
  }) {
    return SensorReadingList(
      readings: readings ?? this.readings,
      latest: latest ?? this.latest,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}

class SensorNotifier extends StateNotifier<SensorReadingList> {
  Timer? _timer;
  final RaspberryPiService _rpiService = RaspberryPiService();
  final AlertService _alertService = AlertService();
  final NotificationService _notificationService = NotificationService();
  final SyncService _syncService = SyncService();
  
  // Alert cooldown tracking
  DateTime? _lastTempAlert;
  DateTime? _lastHumidityAlert;
  static const _alertCooldown = Duration(minutes: 5);

  SensorNotifier()
      : super(SensorReadingList(
          readings: [],
          latest: null,
          isConnected: false,
        )) {
    _startAutoUpdate();
  }

  void _startAutoUpdate() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      _fetchRealData();
    });
  }

  Future<void> _fetchRealData() async {
    try {
      final envData = await _rpiService.getSensorData();
      
      print('DEBUG: Fetched sensor data: $envData');

      if (envData != null) {
        print('DEBUG: Setting isConnected = true');
        final newReading = SensorReading(
          timestamp: envData.timestamp,
          temperature: envData.temperature,
          humidity: envData.humidity,
        );

        final readings = [...state.readings, newReading];
        if (readings.length > 50) {
          readings.removeAt(0);
        }

        state = state.copyWith(
          readings: readings,
          latest: newReading,
          isConnected: true,
        );
        
        // Queue sensor reading for offline sync
        await _syncService.addPendingSync(
          dataType: 'sensor_reading',
          dataId: newReading.id,
          data: newReading.toMap(),
        );
        
        // Check thresholds and create alerts
        await _checkThresholds(newReading);
      } else {
        print('DEBUG: envData is null, setting isConnected = false');
        // If data is null, the connection is lost
        state = state.copyWith(isConnected: false);
      }
    } catch (e) {
      print('DEBUG: Error fetching sensor data: $e');
      state = state.copyWith(isConnected: false);
    }
  }
  
  Future<void> _checkThresholds(SensorReading reading) async {
    final prefs = await SharedPreferences.getInstance();
    final tempThreshold = prefs.getDouble('tempThreshold') ?? 80.0;
    final humidityThreshold = prefs.getDouble('humidityThreshold') ?? 15.0;
    
    final now = DateTime.now();
    
    // Check temperature (with cooldown)
    if (reading.temperature > tempThreshold) {
      if (_lastTempAlert == null || now.difference(_lastTempAlert!) > _alertCooldown) {
        _lastTempAlert = now;
        
        final message = 'Temperature ${reading.temperature.toStringAsFixed(1)}°C exceeds threshold ${tempThreshold.toStringAsFixed(1)}°C';
        
        await _alertService.createAlert(
          type: NotificationType.warning,
          title: 'High Temperature Alert',
          message: message,
          value: reading.temperature,
          threshold: tempThreshold,
        );
        
        // Show notification with sound
        await _notificationService.showAlert(
          title: '🔥 High Temperature!',
          body: message,
          isUrgent: true,
        );
        
        // Show popup overlay
        final context = navigatorKey.currentContext;
        if (context != null) {
          AlertOverlay.show(
            context,
            title: 'High Temperature Alert',
            message: message,
            isUrgent: true,
          );
        }
      }
    } else {
      // Reset cooldown when temp is normal
      _lastTempAlert = null;
    }
    
    // Check humidity (with cooldown)
    if (reading.humidity < humidityThreshold) {
      if (_lastHumidityAlert == null || now.difference(_lastHumidityAlert!) > _alertCooldown) {
        _lastHumidityAlert = now;
        
        final message = 'Humidity ${reading.humidity.toStringAsFixed(1)}% below threshold ${humidityThreshold.toStringAsFixed(1)}%';
        
        await _alertService.createAlert(
          type: NotificationType.warning,
          title: 'Low Humidity Alert',
          message: message,
          value: reading.humidity,
          threshold: humidityThreshold,
        );
        
        // Show notification with sound
        await _notificationService.showAlert(
          title: '💧 Low Humidity!',
          body: message,
          isUrgent: false,
        );
        
        // Show popup overlay
        final context = navigatorKey.currentContext;
        if (context != null) {
          AlertOverlay.show(
            context,
            title: 'Low Humidity Alert',
            message: message,
            isUrgent: false,
          );
        }
      }
    } else {
      // Reset cooldown when humidity is normal
      _lastHumidityAlert = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
