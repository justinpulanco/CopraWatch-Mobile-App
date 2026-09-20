class ScanResult {
  final int? id;
  final String classification;
  final double confidence;
  final String imagePath;
  final String moistureStatus; // Descriptive: "Masyadong Basang", "Perpekto Na", "Sobrang Tuyo"
  final DateTime timestamp;
  final String batchId;

  ScanResult({
    this.id,
    required this.classification,
    required this.confidence,
    required this.imagePath,
    required this.moistureStatus,
    required this.timestamp,
    required this.batchId,
  });

  /// Get moisture description in English
  String get moistureDescriptionEn {
    switch (moistureStatus) {
      case 'too_wet':
        return 'Too Wet';
      case 'slightly_squishy':
        return 'Slightly Squishy';
      case 'perfect':
        return 'Perfect';
      case 'slightly_dry':
        return 'Slightly Dry';
      case 'too_dry':
        return 'Too Dry';
      default:
        return 'Unknown';
    }
  }

  /// Get moisture description in Tagalog
  String get moistureDescriptionTl {
    switch (moistureStatus) {
      case 'too_wet':
        return 'Masyadong Basang';
      case 'slightly_squishy':
        return 'Kaunting Lata';
      case 'perfect':
        return 'Perpekto Na';
      case 'slightly_dry':
        return 'Medyo Tuyo Na';
      case 'too_dry':
        return 'Sobrang Tuyo';
      default:
        return 'Hindi Alam';
    }
  }

  /// Get color indicator based on moisture status
  String get moistureColor {
    switch (moistureStatus) {
      case 'too_wet':
        return '#FF6B6B'; // Red
      case 'slightly_squishy':
        return '#FFA500'; // Orange
      case 'perfect':
        return '#4CAF50'; // Green
      case 'slightly_dry':
        return '#8B7355'; // Brown
      case 'too_dry':
        return '#3E2723'; // Dark Brown
      default:
        return '#9E9E9E'; // Gray
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'classification': classification,
      'confidence': confidence,
      'imagePath': imagePath,
      'moistureStatus': moistureStatus,
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
      moistureStatus: map['moistureStatus'] ?? 'unknown',
      timestamp: DateTime.parse(map['timestamp']),
      batchId: map['batchId'],
    );
  }
}
