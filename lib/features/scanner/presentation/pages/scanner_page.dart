import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_bottom_navigation.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../database/database_helper.dart';
import '../../../../database/models/scan_result.dart';
import '../../../../services/api_service.dart';
import '../../../../services/ml_service.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({Key? key}) : super(key: key);

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  String? _selectedImage;
  File? _imageFile;
  String? _classificationResult;
  double? _confidence;
  bool _isClassifying = false;
  final ImagePicker _imagePicker = ImagePicker();
  final DatabaseHelper _db = DatabaseHelper();
  final ApiService _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Copra Quality Scanner',
        subtitle: 'ML-Based Classification',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Camera placeholder
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                border: Border.all(
                  color: AppTheme.dividerColor,
                  width: 2,
                ),
                borderRadius:
                    BorderRadius.circular(AppConstants.cardBorderRadius),
              ),
              child: _selectedImage != null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_imageFile != null)
                          Image.file(
                            _imageFile!,
                            width: double.infinity,
                            height: 280,
                            fit: BoxFit.cover,
                          )
                        else
                          Icon(
                            Icons.image_rounded,
                            size: 80,
                            color: AppTheme.primaryGreen,
                          ),
                        const SizedBox(height: 12),
                        Text(
                          'Image Ready for Classification',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: AppTheme.primaryGreen,
                              ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt_rounded,
                          size: 80,
                          color: AppTheme.textTertiary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Camera Placeholder',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ready for TensorFlow Lite integration',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: AppTheme.textTertiary,
                              ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectedImage == null
                    ? () => _showCameraOptions()
                    : null,
                icon: const Icon(Icons.camera_rounded),
                label: const Text('Capture Image'),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectedImage != null && !_isClassifying
                    ? _classifyImage
                    : null,
                icon: _isClassifying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.science_rounded),
                label: Text(_isClassifying ? 'Classifying...' : 'Classify'),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => setState(() {
                  _selectedImage = null;
                  _imageFile = null;
                  _classificationResult = null;
                  _confidence = null;
                }),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Clear'),
              ),
            ),
            const SizedBox(height: 24),

            if (_classificationResult != null) ...[
              Text(
                'Classification Result',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              _buildResultCard(),
              const SizedBox(height: 24),
            ],

            // Info section
            Text(
              'How It Works',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoItem(
                      context,
                      '1. Capture',
                      'Take a photo of the copra sample',
                      Icons.camera_alt_rounded,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoItem(
                      context,
                      '2. Process',
                      'Image is processed and features extracted',
                      Icons.image_rounded,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoItem(
                      context,
                      '3. Classify',
                      'ML model predicts drying quality',
                      Icons.psychology_rounded,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoItem(
                      context,
                      '4. Result',
                      'View classification and confidence score',
                      Icons.check_circle_rounded,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Model information
            Card(
              color: AppTheme.backgroundColor,
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Model Information',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _buildModelInfoRow('Model Name', 'CopraQuality v1.0'),
                    _buildModelInfoRow(
                        'Framework', 'TensorFlow Lite'),
                    _buildModelInfoRow(
                        'Input Size', '224x224 RGB'),
                    _buildModelInfoRow(
                        'Output Classes', 'Under-Dried, Optimally-Dried, Over-Dried'),
                    _buildModelInfoRow(
                        'Min Confidence', '75%'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigation(
        currentLocation: AppRoutes.scanner,
      ),
    );
  }

  Widget _buildResultCard() {
    final color = _getQualityColor(_classificationResult!);

    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quality Classification',
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _classificationResult!,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                Icon(
                  _getQualityIcon(_classificationResult!),
                  size: 48,
                  color: color,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Confidence
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Confidence Score',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                Text(
                  '${(_confidence! * 100).toStringAsFixed(1)}%',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _confidence,
                minHeight: 8,
                backgroundColor: color.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),

            const SizedBox(height: 16),

            // Details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Batch ID', 'Batch #2024-01-001'),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                      'Moisture', '${_generateMockMoisture()}%'),
                  const SizedBox(height: 8),
                  _buildDetailRow('Model', 'CopraQuality v1.0'),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                      'Timestamp', '${DateTime.now().hour}:${DateTime.now().minute}'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _classificationResult != null ? _saveResult : null,
                child: const Text('Save Result'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    String title,
    String description,
    IconData icon,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryGreen,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModelInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  void _mockCaptureImage() {
    setState(() {
      _selectedImage = 'mock_image.jpg';
      _classificationResult = null;
      _confidence = null;
    });
  }

  void _showCameraOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Camera Source'),
        content: const Text('Choose where to capture the image from'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _captureFromPhoneCamera();
            },
            child: const Text('Phone Camera'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _captureFromUSBCamera();
            },
            child: const Text('External USB Camera'),
          ),
        ],
      ),
    );
  }

  void _captureFromPhoneCamera() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _selectedImage = pickedFile.name;
          _classificationResult = null;
          _confidence = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _captureFromUSBCamera() {
    // TODO: RPI/USB camera integration
    // For now, allow gallery pick as fallback
    _pickFromGallery();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('USB camera - select from gallery for now')),
    );
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _selectedImage = pickedFile.name;
          _classificationResult = null;
          _confidence = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _classifyImage() async {
    if (_imageFile == null) return;

    setState(() => _isClassifying = true);

    try {
      final mlService = MLService();
      final result = await mlService.classifyImage(imagePath: _imageFile!.path);

      setState(() {
        _classificationResult = result.classification;
        _confidence = result.confidence;
        _isClassifying = false;
      });
    } catch (e) {
      setState(() => _isClassifying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Color _getQualityColor(String quality) {
    if (quality.contains('Optimally')) {
      return AppTheme.successColor;
    } else if (quality.contains('Under')) {
      return AppTheme.infoColor;
    } else {
      return AppTheme.warningColor;
    }
  }

  IconData _getQualityIcon(String quality) {
    if (quality.contains('Optimally')) {
      return Icons.check_circle_rounded;
    } else if (quality.contains('Under')) {
      return Icons.info_rounded;
    } else {
      return Icons.warning_rounded;
    }
  }

  double _generateMockMoisture() {
    return 12.5 + (DateTime.now().second % 5) * 0.5;
  }

  void _saveResult() async {
    final result = ScanResult(
      classification: _classificationResult!,
      confidence: _confidence!,
      imagePath: _imageFile?.path ?? '',
      moisture: _generateMockMoisture(),
      timestamp: DateTime.now(),
      batchId: 'Batch #${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-001',
    );

    await _db.insertScanResult(result);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Result saved successfully')),
      );
      
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _selectedImage = null;
            _imageFile = null;
            _classificationResult = null;
            _confidence = null;
          });
        }
      });
    }
  }
}
