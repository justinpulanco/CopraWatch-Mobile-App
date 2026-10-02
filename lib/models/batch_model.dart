import 'package:uuid/uuid.dart';

class Batch {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime? endDate;
  final double initialMoisture;
  final double finalMoisture;
  final String initialMoistureStatus;
  final String finalMoistureStatus;
  final String status; // 'active', 'completed', 'paused'
  final List<SensorReading> readings;
  final String? qualityResult;
  final double? confidence;
  final String? notes;
  // Environmental data
  final double? startTemperature;
  final double? startHumidity;
  final double? endTemperature;
  final double? endHumidity;
  final double? averageTemperature;
  final double? averageHumidity;
  // Pause tracking
  final DateTime? pausedAt;
  final int pausedDurationMinutes; // Total minutes paused

  Batch({
    String? id,
    required this.name,
    required this.startDate,
    this.endDate,
    required this.initialMoisture,
    required this.finalMoisture,
    this.initialMoistureStatus = 'basa-basa',
    this.finalMoistureStatus = 'basa-basa',
    required this.status,
    required this.readings,
    this.qualityResult,
    this.confidence,
    this.notes,
    this.startTemperature,
    this.startHumidity,
    this.endTemperature,
    this.endHumidity,
    this.averageTemperature,
    this.averageHumidity,
    this.pausedAt,
    this.pausedDurationMinutes = 0,
  }) : id = id ?? const Uuid().v4();

  // Actual drying duration (excluding paused time)
  Duration get dryingDuration {
    final endTime = endDate ?? DateTime.now();
    final totalDuration = endTime.difference(startDate);
    
    // Current pause time if currently paused
    int currentPauseMinutes = 0;
    if (status == 'paused' && pausedAt != null) {
      currentPauseMinutes = DateTime.now().difference(pausedAt!).inMinutes;
    }
    
    final totalPausedMinutes = pausedDurationMinutes + currentPauseMinutes;
    final actualDuration = totalDuration.inMinutes - totalPausedMinutes;
    
    return Duration(minutes: actualDuration < 0 ? 0 : actualDuration);
  }

    double get moistureReduction => initialMoisture > 0
      ? ((initialMoisture - finalMoisture) / initialMoisture) * 100
      : 0;

  bool get isActive => status == 'active';
  bool get isPaused => status == 'paused';
  bool get isCompleted => status == 'completed';

  factory Batch.empty() {
    return Batch(
      name: '',
      startDate: DateTime.now(),
      initialMoisture: 0,
      finalMoisture: 0,
      status: 'active',
      readings: [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'initialMoisture': initialMoisture,
      'finalMoisture': finalMoisture,
      'initialMoistureStatus': initialMoistureStatus,
      'finalMoistureStatus': finalMoistureStatus,
      'status': status,
      'qualityResult': qualityResult,
      'confidence': confidence,
      'notes': notes,
      'startTemperature': startTemperature,
      'startHumidity': startHumidity,
      'endTemperature': endTemperature,
      'endHumidity': endHumidity,
      'averageTemperature': averageTemperature,
      'averageHumidity': averageHumidity,
      'pausedAt': pausedAt?.toIso8601String(),
      'pausedDurationMinutes': pausedDurationMinutes,
    };
  }

  factory Batch.fromMap(Map<String, dynamic> map) {
    return Batch(
      id: map['id'] ?? const Uuid().v4(),
      name: map['name'] ?? '',
      startDate: map['startDate'] != null 
          ? DateTime.parse(map['startDate']) 
          : DateTime.now(),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      initialMoisture: map['initialMoisture']?.toDouble() ?? 0.0,
      finalMoisture: map['finalMoisture']?.toDouble() ?? 0.0,
      initialMoistureStatus: map['initialMoistureStatus'] ?? 'basa-basa',
      finalMoistureStatus: map['finalMoistureStatus'] ?? 'basa-basa',
      status: map['status'] ?? 'active',
      readings: [],
      qualityResult: map['qualityResult'],
      confidence: map['confidence']?.toDouble(),
      notes: map['notes'],
      startTemperature: map['startTemperature']?.toDouble(),
      startHumidity: map['startHumidity']?.toDouble(),
      endTemperature: map['endTemperature']?.toDouble(),
      endHumidity: map['endHumidity']?.toDouble(),
      averageTemperature: map['averageTemperature']?.toDouble(),
      averageHumidity: map['averageHumidity']?.toDouble(),
      pausedAt: map['pausedAt'] != null ? DateTime.parse(map['pausedAt']) : null,
      pausedDurationMinutes: map['pausedDurationMinutes'] ?? 0,
    );
  }

  Batch copyWith({
    String? id,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    double? initialMoisture,
    double? finalMoisture,
    String? initialMoistureStatus,
    String? finalMoistureStatus,
    String? status,
    List<SensorReading>? readings,
    String? qualityResult,
    double? confidence,
    String? notes,
    double? startTemperature,
    double? startHumidity,
    double? endTemperature,
    double? endHumidity,
    double? averageTemperature,
    double? averageHumidity,
  }) {
    return Batch(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      initialMoisture: initialMoisture ?? this.initialMoisture,
      finalMoisture: finalMoisture ?? this.finalMoisture,
      initialMoistureStatus: initialMoistureStatus ?? this.initialMoistureStatus,
      finalMoistureStatus: finalMoistureStatus ?? this.finalMoistureStatus,
      status: status ?? this.status,
      readings: readings ?? this.readings,
      qualityResult: qualityResult ?? this.qualityResult,
      confidence: confidence ?? this.confidence,
      notes: notes ?? this.notes,
      startTemperature: startTemperature ?? this.startTemperature,
      startHumidity: startHumidity ?? this.startHumidity,
      endTemperature: endTemperature ?? this.endTemperature,
      endHumidity: endHumidity ?? this.endHumidity,
      averageTemperature: averageTemperature ?? this.averageTemperature,
      averageHumidity: averageHumidity ?? this.averageHumidity,
    );
  }
}

class SensorReading {
  final String id;
  final DateTime timestamp;
  final double temperature;
  final double humidity;

  SensorReading({
    String? id,
    required this.timestamp,
    required this.temperature,
    required this.humidity,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'temperature': temperature,
      'humidity': humidity,
    };
  }

  factory SensorReading.fromMap(Map<String, dynamic> map) {
    return SensorReading(
      id: map['id'] ?? const Uuid().v4(),
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      temperature: map['temperature'] ?? 0.0,
      humidity: map['humidity'] ?? 0.0,
    );
  }
}

class QualityPrediction {
  final String batchId;
  final String imagePath;
  final String classification;
  final double confidence;
  final DateTime timestamp;
  final String modelName;

  QualityPrediction({
    required this.batchId,
    required this.imagePath,
    required this.classification,
    required this.confidence,
    required this.timestamp,
    required this.modelName,
  });

  bool get isConfident => confidence >= 0.75;

  Map<String, dynamic> toMap() {
    return {
      'batchId': batchId,
      'imagePath': imagePath,
      'classification': classification,
      'confidence': confidence,
      'timestamp': timestamp.toIso8601String(),
      'modelName': modelName,
    };
  }

  factory QualityPrediction.fromMap(Map<String, dynamic> map) {
    return QualityPrediction(
      batchId: map['batchId'] ?? '',
      imagePath: map['imagePath'] ?? '',
      classification: map['classification'] ?? '',
      confidence: map['confidence'] ?? 0.0,
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      modelName: map['modelName'] ?? '',
    );
  }
}
