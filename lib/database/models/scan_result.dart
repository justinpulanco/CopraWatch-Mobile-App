class ScanResult {
  final int? id;
  final String classification;
  final double confidence;
  final String imagePath;
  final double moisture;
  final DateTime timestamp;
  final String batchId;

  ScanResult({
    this.id,
    required this.classification,
    required this.confidence,
    required this.imagePath,
    required this.moisture,
    required this.timestamp,
    required this.batchId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'classification': classification,
      'confidence': confidence,
      'imagePath': imagePath,
      'moisture': moisture,
      'timestamp': timestamp.toIso8601String(),
      'batchId': batchId,
    };
  }

  factory ScanResult.fromMap(Map<String, dynamic> map) {
    return ScanResult(
      id: map['id'],
      classification: map['classification'],
      confidence: map['confidence'],
      imagePath: map['imagePath'],
      moisture: map['moisture'],
      timestamp: DateTime.parse(map['timestamp']),
      batchId: map['batchId'],
    );
  }
}
