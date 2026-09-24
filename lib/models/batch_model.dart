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
  }) : id = id ?? const Uuid().v4();

  Duration get dryingDuration =>
      (endDate ?? DateTime.now()).difference(startDate);

    double get moistureReduction => initialMoisture > 0
      ? ((initialMoisture - finalMoisture) / initialMoisture) * 100
      : 0;

  bool get isActive => status == 'active';

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
    };
  }

  factory Batch.fromMap(Map<String, dynamic> map) {
    return Batch(
      id: map['id'] ?? const Uuid().v4(),
      name: map['name'] ?? '',
      startDate: DateTime.parse(map['startDate'] ?? DateTime.now()),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      initialMoisture: map['initialMoisture'] ?? 0.0,
      finalMoisture: map['finalMoisture'] ?? 0.0,
      initialMoistureStatus: map['initialMoistureStatus'] ?? 'basa-basa',
      finalMoistureStatus: map['finalMoistureStatus'] ?? 'basa-basa',
      status: map['status'] ?? 'active',
      readings: [],
      qualityResult: map['qualityResult'],
      confidence: map['confidence'],
      notes: map['notes'],
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
