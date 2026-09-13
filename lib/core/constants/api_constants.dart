class ApiConstants {
  // API Base URL - This can be updated at runtime from Settings
  static String baseUrl = 'http://192.168.1.100:5000';

  // Endpoints
  static String get healthCheck => '$baseUrl/api/health';
  static String get environmental => '$baseUrl/api/sensor/environmental';
  static String get environmentalHistory => '$baseUrl/api/sensor/environmental/history';
  static String get captureImage => '$baseUrl/api/camera/capture';
  static String get classification => '$baseUrl/api/classification';
  static String get classificationsAll => '$baseUrl/api/classifications/all';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);

  /// Method to update the base URL dynamically
  static void updateBaseUrl(String ip, int port) {
    // Basic validation to prevent malformed URLs
    if (ip.isEmpty) return;

    // Ensure the IP has http:// prefix if missing
    String prefix = 'http://';
    String cleanIp = ip.trim();
    if (cleanIp.startsWith('http://') || cleanIp.startsWith('https://')) {
      prefix = '';
    }

    baseUrl = '$prefix$cleanIp:$port';
    print('API Base URL updated to: $baseUrl');
  }
}
