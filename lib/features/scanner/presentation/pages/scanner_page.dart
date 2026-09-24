import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_bottom_navigation.dart';
import '../../../../core/widgets/mjpeg_preview.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/utils/moisture_mapper.dart';
import '../../../../database/database_helper.dart';
import '../../../../database/models/scan_result.dart';
import '../../../../services/api_service.dart';
import '../../../../services/ml_service.dart';
import '../../../../services/batch_service.dart';

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
  bool _showingRPICameraPreview = false;
  bool _isLoadingPreview = false;
  String? _lastPreviewUrl;
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
            // Camera buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isClassifying ? null : () async {
                      if (!_showingRPICameraPreview) {
                        // Opening preview - load image
                        setState(() => _showingRPICameraPreview = true);
                        await _loadRPICameraImage();
                      } else {
                        // Closing preview
                        setState(() {
                          _showingRPICameraPreview = false;
                          _lastPreviewUrl = null;
                        });
                      }
                    },
                    icon: Icon(_showingRPICameraPreview ? Icons.close : Icons.videocam),
                    label: Text(_showingRPICameraPreview ? 'Close Preview' : 'RPI Camera'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: _showingRPICameraPreview ? Colors.red : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isClassifying ? null : _captureFromPhone,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Phone Camera'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.accentOrange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // RPI Camera Preview or Captured Image
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
              child: _showingRPICameraPreview
                  ? Stack(
                      children: [
                        // Live preview with cached image
                        if (_lastPreviewUrl != null)
                          MjpegPreview(
                            url: _lastPreviewUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context) {
                              return Container(
                                color: Colors.black,
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.error, size: 60, color: Colors.white),
                                      SizedBox(height: 12),
                                      Text('Camera Error', 
                                        style: TextStyle(color: Colors.white)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          )
                        else
                          Container(
                            color: Colors.black,
                            child: const Center(
                              child: CircularProgressIndicator(color: Colors.white),
                            ),
                          ),
                        // Loading overlay
                        if (_isLoadingPreview)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black26,
                              child: const Center(
                                child: CircularProgressIndicator(color: Colors.white),
                              ),
                            ),
                          ),
                        // Capture button overlay
                        Positioned(
                          bottom: 16,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: ElevatedButton.icon(
                              onPressed: _isLoadingPreview ? null : _captureFromRPI,
                              icon: const Icon(Icons.camera),
                              label: const Text('CAPTURE'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 16),
                                backgroundColor: AppTheme.primaryGreen,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : _selectedImage != null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_imageFile != null)
                          Flexible(
                            child: Image.file(
                              _imageFile!,
                              width: double.infinity,
                              fit: BoxFit.contain,
                            ),
                          )
                        else
                          Icon(
                            Icons.image_rounded,
                            size: 80,
                            color: AppTheme.primaryGreen,
                          ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            'Image Ready for Classification',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: AppTheme.primaryGreen),
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
                          'Ready to Capture',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: AppTheme.primaryGreen,
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
                onPressed: (_selectedImage != null || _imageFile != null) && !_isClassifying
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
                        'Output Classes', 'Basa-basa, Tuyo, Sunog'),
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
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 240),
                      child: Text(
                        _classificationResult!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(color: color, fontWeight: FontWeight.bold),
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
                  _buildDetailRow('Classification', _classificationResult!),
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
                onPressed: _classificationResult != null &&
                        _classificationResult != 'Copra image could not be verified'
                  ? _saveResult
                  : null,
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

  // Load RPi camera image once (static, no refresh loop)
  Future<void> _loadRPICameraImage() async {
    setState(() => _isLoadingPreview = true);
    
    try {
      // Open the temporary MJPEG stream. It is not saved or recorded.
      final imageUrl = '${ApiConstants.baseUrl}/api/camera/stream';
      
      setState(() {
        _lastPreviewUrl = imageUrl;
      });
      
      // Wait a moment for image to load
      await Future.delayed(const Duration(milliseconds: 1000));
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading RPi camera: $e')),
        );
      }
    } finally {
      setState(() => _isLoadingPreview = false);
    }
  }

  // Capture from RPI - Direct capture
  Future<void> _captureFromRPI() async {
    setState(() {
      _isClassifying = true;
      _showingRPICameraPreview = false; // Close preview
    });
    
    try {
      final response = await _apiService.captureImageFromRPI();
      
      if (response != null && response['success'] == true) {
        setState(() {
          _selectedImage = response['filename'];
          _classificationResult = null;
          _confidence = null;
          _imageFile = null;
          _isClassifying = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Image captured from RPI!'),
              backgroundColor: AppTheme.successColor,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isClassifying = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('RPI Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Capture from phone camera
  Future<void> _captureFromPhone() async {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Phone Camera Error: $e')),
        );
      }
    }
  }

  void _classifyImage() async {
    if (_imageFile == null && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No image to classify')),
      );
      return;
    }

    setState(() => _isClassifying = true);

    try {
      final mlService = MLService();
      
      // Check if we have a local file (from phone) or RPI image
      if (_imageFile != null) {
        // Phone camera - classify local file
        final hasFace = await mlService.containsHumanFace(_imageFile!.path);
        final result = await mlService.classifyImage(imagePath: _imageFile!.path);
        setState(() {
          _classificationResult = hasFace
              ? 'Copra image could not be verified'
              : result.classification;
          _confidence = result.confidence;
          _isClassifying = false;
        });
      } else {
        // RPI camera - download image and classify
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Downloading image from RPI...')),
          );
          
          // Download image from RPi
          final response = await _apiService.downloadImageFromRPI(_selectedImage!);
          
          if (response != null) {
            // Save downloaded image temporarily to app cache
            final directory = await getApplicationCacheDirectory();
            File tempFile;
            
            try {
              tempFile = File('${directory.path}/rpi_image.jpg');
              await tempFile.writeAsBytes(response);
            } catch (e) {
              // If write fails, try using a unique filename
              tempFile = File('${directory.path}/rpi_image_${DateTime.now().millisecondsSinceEpoch}.jpg');
              await tempFile.writeAsBytes(response);
            }
            
            final hasFace = await mlService.containsHumanFace(tempFile.path);
            // Classify using ML
            final result = await mlService.classifyImage(imagePath: tempFile.path);
            
            setState(() {
              _classificationResult = hasFace
                  ? 'Copra image could not be verified'
                  : result.classification;
              _confidence = result.confidence;
              _isClassifying = false;
            });
            
            // Clean up temp file
            await tempFile.delete().catchError((_) => tempFile);
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    hasFace
                      ? 'Image is not recognized as copra'
                      : 'RPI image classified',
                  ),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            }
          } else {
            throw Exception('Failed to download image from RPi');
          }
        } catch (e) {
          setState(() => _isClassifying = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('RPI Error: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      setState(() => _isClassifying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Classification Error: $e')),
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

  void _saveResult() async {
    try {
      final batchService = BatchService();
      final activeBatches = await batchService.getActiveBatches();
      if (activeBatches.isEmpty) {
        throw Exception('Create or start a batch before saving a result');
      }
      final activeBatchId = activeBatches.first.id;
      final moistureStatus = MoistureMapper.classificationToMoistureStatus(_classificationResult!);

      final result = ScanResult(
        classification: _classificationResult!,
        confidence: _confidence!,
        imagePath: _imageFile?.path ?? 'rpi://$_selectedImage',
        moistureStatus: moistureStatus,
        timestamp: DateTime.now(),
        batchId: activeBatchId,
      );

      await _db.insertScanResult(result);
      await batchService.saveQualityResult(
        batchId: activeBatchId,
        classification: _classificationResult!,
        confidence: _confidence!,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Result saved to ${activeBatches.first.name}')),
      );
      setState(() {
        _selectedImage = null;
        _imageFile = null;
        _classificationResult = null;
        _confidence = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save result: $e')),
        );
      }
    }
  }
}

