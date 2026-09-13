import '../database/database_helper.dart';

class AlertService {
  final DatabaseHelper _db = DatabaseHelper();

  // Constants for thresholds
  static const double maxTemperature = 45.0;
  static const double minTemperature = 20.0;
  static const double maxHumidity = 85.0;
  static const double minHumidity = 30.0;

  // Check and create alerts
  Future<void> checkAndCreateAlert({
    required String batchId,
    required double temperature,
    required double humidity,
  }) async {
    // Temperature alerts
    if (temperature > maxTemperature) {
      await _createAlert(
        batchId: batchId,
        alertType: 'temperature_high',
        value: temperature,
        threshold: maxTemperature,
      );
    }

    if (temperature < minTemperature) {
      await _createAlert(
        batchId: batchId,
        alertType: 'temperature_low',
        value: temperature,
        threshold: minTemperature,
      );
    }

    // Humidity alerts
    if (humidity > maxHumidity) {
      await _createAlert(
        batchId: batchId,
        alertType: 'humidity_high',
        value: humidity,
        threshold: maxHumidity,
      );
    }

    if (humidity < minHumidity) {
      await _createAlert(
        batchId: batchId,
        alertType: 'humidity_low',
        value: humidity,
        threshold: minHumidity,
      );
    }
  }

  // Create alert
  Future<void> _createAlert({
    required String batchId,
    required String alertType,
    required double value,
    required double threshold,
  }) async {
    final alert = {
      'batchId': batchId,
      'alertType': alertType,
      'value': value,
      'threshold': threshold,
      'timestamp': DateTime.now().toIso8601String(),
      'acknowledged': 0,
    };
    await _db.insertAlert(alert);
  }

  // Get alerts for batch
  Future<List<Map<String, dynamic>>> getAlertsByBatch(String batchId) async {
    return _db.getAlertsByBatch(batchId);
  }

  // Get unacknowledged alerts
  Future<List<Map<String, dynamic>>> getUnacknowledgedAlerts(String batchId) async {
    final allAlerts = await _db.getAlertsByBatch(batchId);
    return allAlerts.where((a) => a['acknowledged'] == 0).toList();
  }

  // Acknowledge alert
  Future<void> acknowledgeAlert(int alertId) async {
    await _db.acknowledgeAlert(alertId);
  }

  // Get alert message
  String getAlertMessage(String alertType, double value, double threshold) {
    switch (alertType) {
      case 'temperature_high':
        return 'Temperature is too high: ${value.toStringAsFixed(1)}°C (Max: ${threshold.toStringAsFixed(1)}°C)';
      case 'temperature_low':
        return 'Temperature is too low: ${value.toStringAsFixed(1)}°C (Min: ${threshold.toStringAsFixed(1)}°C)';
      case 'humidity_high':
        return 'Humidity is too high: ${value.toStringAsFixed(1)}% (Max: ${threshold.toStringAsFixed(1)}%)';
      case 'humidity_low':
        return 'Humidity is too low: ${value.toStringAsFixed(1)}% (Min: ${threshold.toStringAsFixed(1)}%)';
      default:
        return 'Alert: $alertType';
    }
  }
}
