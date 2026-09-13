class ClassificationResult {
  final String image;
  final String classification;
  final double confidence;
  final DateTime timestamp;

  ClassificationResult({
    required this.image,
    required this.classification,
    required this.confidence,
    required this.timestamp,
  });

  factory ClassificationResult.fromJson(Map<String, dynamic> json) {
    return ClassificationResult(
      image: json['image'] as String,
      classification: json['classification'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'image': image,
      'classification': classification,
      'confidence': confidence,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
