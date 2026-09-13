import 'dart:io';

/// Camera Service for image capture
/// Note: Camera functionality currently disabled. Use file_picker for image selection instead.

class CameraService {
  static final CameraService _instance = CameraService._internal();

  factory CameraService() => _instance;

  CameraService._internal();

  /// Initialize camera (stub - not implemented)
  Future<bool> initialize() async {
    return false;
  }

  /// Capture image (stub - not implemented)
  Future<String?> captureImage() async {
    return null;
  }

  /// Save image to file (stub - not implemented)
  Future<String?> saveImage({
    required String imagePath,
    required String fileName,
  }) async {
    return null;
  }

  /// Switch camera (stub - not implemented)
  Future<bool> switchCamera() async {
    return false;
  }

  /// Set flash mode (stub - not implemented)
  Future<void> setFlashMode(String mode) async {
    return;
  }

  /// Set zoom level (stub - not implemented)
  Future<void> setZoom(double zoom) async {
    return;
  }

  /// Dispose camera
  void dispose() {
    // No-op
  }
}
