import 'api_service.dart';
import '../models/environmental_data.dart';

/// Real service for Raspberry Pi integration
/// Communicates with the RPi Flask API via ApiService
class RaspberryPiService {
  static final RaspberryPiService _instance = RaspberryPiService._internal();

  factory RaspberryPiService() => _instance;

  RaspberryPiService._internal();

  final ApiService _api = ApiService();
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  /// Connect to Raspberry Pi (Performs a health check)
  Future<bool> connect({
    required String ipAddress,
    required int port,
  }) async {
    // Note: In a real implementation, you'd update ApiConstants.baseUrl here
    // For now, we assume the health check determines connectivity
    _isConnected = await _api.healthCheck();
    return _isConnected;
  }

  /// Get real-time sensor data from the RPi
  Future<EnvironmentalData?> getSensorData() async {
    final data = await _api.getEnvironmentalData();
    _isConnected = data != null;
    return data;
  }

  /// Get device status
  Future<Map<String, dynamic>> getStatus() async {
    final connected = await _api.healthCheck();
    _isConnected = connected;
    return {
      'connected': _isConnected,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Disconnect
  Future<void> disconnect() async {
    _isConnected = false;
  }
}
