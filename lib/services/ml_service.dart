import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import '../core/constants/app_constants.dart';

/// Machine Learning Service using TensorFlow Lite
/// Handles copra quality classification
class MLService {
  static final MLService _instance = MLService._internal();

  factory MLService() => _instance;

  MLService._internal();

  Interpreter? _interpreter;
  List<String>? _labels;
  bool _isModelLoaded = false;

  bool get isModelLoaded => _isModelLoaded;

  /// Load ML model and labels
  Future<bool> loadModel() async {
    try {
      print('Loading model from assets/copra_quality_model.tflite/model_unquant.tflite');
      // Load Interpreter from assets
      _interpreter = await Interpreter.fromAsset('assets/copra_quality_model.tflite/model_unquant.tflite');
      
      print('Loading labels from assets/copra_quality_model.tflite/labels.txt');
      // Load labels from assets
      final labelsData = await rootBundle.loadString('assets/copra_quality_model.tflite/labels.txt');
      _labels = labelsData.split('\n').where((s) => s.isNotEmpty).map((s) {
        // Remove index prefix if exists (e.g., "0 Under-dried" -> "Under-dried")
        final parts = s.trim().split(' ');
        if (parts.length > 1 && int.tryParse(parts[0]) != null) {
          return parts.sublist(1).join(' ');
        }
        return s.trim();
      }).toList();

      print('Model loaded successfully with ${_labels?.length} classes: $_labels');
      _isModelLoaded = true;
      return true;
    } catch (e) {
      print('Error loading model: $e');
      _isModelLoaded = false;
      return false;
    }
  }

  /// Classify copra image
  Future<ClassificationResult> classifyImage({
    String? imagePath,
    Uint8List? imageBytes,
  }) async {
    if (!_isModelLoaded || _interpreter == null) {
      await loadModel();
      if (!_isModelLoaded) throw Exception('Failed to load ML model');
    }

    try {
      Uint8List bytes;
      if (imageBytes != null) {
        bytes = imageBytes;
      } else if (imagePath != null) {
        bytes = await File(imagePath).readAsBytes();
      } else {
        throw Exception('Either imagePath or imageBytes must be provided');
      }

      // 1. Preprocess
      final input = preprocessImage(bytes);

      // 2. Prepare output buffer
      // Teachable Machine typically outputs [1, num_classes]
      var output = List.filled(1 * _labels!.length, 0.0).reshape([1, _labels!.length]);

      // 3. Run inference
      _interpreter!.run(input, output);

      // 4. Post-process
      return postprocessOutput(output[0]);
    } catch (e) {
      print('Classification error: $e');
      throw Exception('Classification failed: $e');
    }
  }

  /// Preprocess image for model (224x224 RGB Float32)
  List<dynamic> preprocessImage(Uint8List imageBytes) {
    final image = img.decodeImage(imageBytes);
    if (image == null) throw Exception('Could not decode image');

    // Resize to 224x224 (Standard for Teachable Machine/MobileNet)
    final resized = img.copyResize(image, width: 224, height: 224);

    // Convert to float array [1, 224, 224, 3]
    var input = List.generate(
      1,
      (index) => List.generate(
        224,
        (y) => List.generate(
          224,
          (x) {
            final pixel = resized.getPixel(x, y);
            // Normalize to [0, 1] as Teachable Machine usually does
            // Some models might need [-1, 1], adjust if necessary
            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          },
        ),
      ),
    );

    return input;
  }

  /// Post-process model outputs
  ClassificationResult postprocessOutput(List<double> probabilities) {
    int bestIndex = 0;
    double maxProb = -1.0;
    Map<String, double> probMap = {};

    for (int i = 0; i < probabilities.length; i++) {
      final label = _labels![i];
      final prob = probabilities[i];
      probMap[label] = prob;

      if (prob > maxProb) {
        maxProb = prob;
        bestIndex = i;
      }
    }

    return ClassificationResult(
      classification: _labels![bestIndex],
      confidence: maxProb,
      probabilities: probMap,
    );
  }

  /// Dispose ML resources
  void dispose() {
    _interpreter?.close();
    _isModelLoaded = false;
  }
}

/// Result of copra quality classification
class ClassificationResult {
  final String classification;
  final double confidence;
  final Map<String, double> probabilities;

  ClassificationResult({
    required this.classification,
    required this.confidence,
    required this.probabilities,
  });

  bool get isConfident => confidence >= AppConstants.mlConfidenceThreshold;

  @override
  String toString() => 'Classification: $classification (${(confidence * 100).toStringAsFixed(1)}%)';
}
