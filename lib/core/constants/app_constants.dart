class AppConstants {
  // App Info
  static const String appName = 'CopraWatch';
  static const String appVersion = '1.0.0';
  static const String appSubtitle = 'IoT Copra Drying Monitor';

  // Sensor Thresholds
  static const double minTemperature = 30.0;
  static const double maxTemperature = 80.0;
  static const double optimalTemperature = 60.0;
  static const double temperatureWarningThreshold = 70.0;
  static const double temperatureCriticalThreshold = 75.0;

  static const double minHumidity = 5.0;
  static const double maxHumidity = 95.0;
  static const double optimalHumidity = 12.0;
  static const double humidityWarningThreshold = 20.0;
  static const double humidityCriticalThreshold = 30.0;

  static const double minMoisture = 5.0;
  static const double maxMoisture = 50.0;
  static const double optimalMoisture = 12.0;
  static const double moistureWarningThreshold = 18.0;
  static const double moistureCriticalThreshold = 25.0;

  static const double minSolarIrradiance = 0.0;
  static const double maxSolarIrradiance = 1200.0;

  // Drying Duration
  static const int estimatedDryingHours = 48;
  static const int minDryingHours = 24;
  static const int maxDryingHours = 72;

  // API Configuration
  static const String raspberryPiDefaultIP = '192.168.1.100';
  static const int raspberryPiDefaultPort = 5000;
  static const String apiBaseUrl = 'http://192.168.1.100:5000/api';
  static const int apiTimeoutSeconds = 30;
  static const int retryAttempts = 3;

  // Database
  static const String databaseName = 'copra_watch.db';
  static const int databaseVersion = 1;

  // ML Model
  static const String mlModelName = 'copra_quality_model.tflite';
  static const double mlConfidenceThreshold = 0.75;

  // Camera
  static const int cameraImageQuality = 90;
  static const String cameraImageFormat = 'jpg';

  // Notifications
  static const int notificationCheckIntervalSeconds = 30;
  static const int maxNotificationsToStore = 100;

  // UI Configuration
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const double cardBorderRadius = 12.0;
  static const double buttonBorderRadius = 8.0;
  static const double chipBorderRadius = 20.0;

  // Chart Configuration
  static const int chartMaxDataPoints = 50;
  static const int chartAnimationDuration = 1500;

  // Sensor Update Interval
  static const int sensorUpdateIntervalSeconds = 5;
  static const int historyRefreshIntervalSeconds = 60;

  // Quality Classes
  static const String qualityUnderDried = 'Under-Dried';
  static const String qualityOptimallyDried = 'Optimally-Dried';
  static const String qualityOverDried = 'Over-Dried';

  // Asset Paths
  static const String iconPath = 'assets/icons/';
  static const String imagePath = 'assets/images/';
  static const String dataPath = 'assets/data/';
}

class ApiEndpoints {
  static const String sensors = '/sensors';
  static const String sensorHistory = '/sensors/history';
  static const String batches = '/batches';
  static const String batchCreate = '/batches/create';
  static const String batchStart = '/batches/start';
  static const String batchStop = '/batches/stop';
  static const String status = '/status';
  static const String classify = '/classify';
  static const String settings = '/settings';
  static const String calibrate = '/calibrate';
}

class PreferenceKeys {
  static const String userId = 'user_id';
  static const String raspberryPiIP = 'raspberry_pi_ip';
  static const String raspberryPiPort = 'raspberry_pi_port';
  static const String autoConnectRaspberryPi = 'auto_connect_raspberry_pi';
  static const String notificationsEnabled = 'notifications_enabled';
  static const String temperatureUnit = 'temperature_unit';
  static const String darkModeEnabled = 'dark_mode_enabled';
  static const String lastBatchId = 'last_batch_id';
  static const String sensorCalibrationDate = 'sensor_calibration_date';
}
