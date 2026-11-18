class ApiConstants {
  // API Base URL - This can be updated at runtime from Settings
  static String baseUrl = 'https://192.168.254.199:5000';
  static String apiKey = '';

  // Endpoints
  static String get healthCheck => '$baseUrl/api/health';
  static String get environmental => '$baseUrl/api/sensor/environmental';
  static String get environmentalHistory => '$baseUrl/api/sensor/environmental/history';
  static String get cameraStream => '$baseUrl/api/camera/stream';
  static String get classificationsAll => '$baseUrl/api/classifications/all';
  static String get exports => '$baseUrl/api/exports';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);

  /// Update the provisioned API key used for authenticated device requests.
  static void updateApiKey(String value) {
    apiKey = value.trim();
  }

  /// Update the device URL, always requiring encrypted HTTPS transport.
  /// An optional scheme in [ip] is stripped so `http://` cannot downgrade it.
  static void updateBaseUrl(String ip, int port) {
    final cleanHost = ip
        .trim()
        .replaceFirst(RegExp(r'^https?://', caseSensitive: false), '')
        .replaceFirst(RegExp(r'/+$'), '');
    if (cleanHost.isEmpty) return;
    if (cleanHost.contains('/') || cleanHost.contains('@')) {
      throw ArgumentError.value(ip, 'ip', 'Enter a hostname or IP address only.');
    }
    if (port < 1 || port > 65535) {
      throw ArgumentError.value(port, 'port', 'Port must be between 1 and 65535.');
    }

    baseUrl = 'https://$cleanHost:$port';
    print('API Base URL updated to: $baseUrl');
  }
}
