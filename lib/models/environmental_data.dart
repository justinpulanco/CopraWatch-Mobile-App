class EnvironmentalData {
  final double temperature;
  final double humidity;
  final double moisture;
  final double solarIrradiance;
  final DateTime timestamp;

  EnvironmentalData({
    required this.temperature,
    required this.humidity,
    required this.moisture,
    required this.solarIrradiance,
    required this.timestamp,
  });

  factory EnvironmentalData.fromJson(Map<String, dynamic> json) {
    return EnvironmentalData(
      temperature: (json['temperature'] as num).toDouble(),
      humidity: (json['humidity'] as num).toDouble(),
      moisture: (json['moisture'] as num?)?.toDouble() ?? 0.0,
      solarIrradiance: (json['solarIrradiance'] as num?)?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'moisture': moisture,
      'solarIrradiance': solarIrradiance,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
