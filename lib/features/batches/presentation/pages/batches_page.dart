import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_bottom_navigation.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../models/batch_model.dart';
import '../../../../services/batch_service.dart';
import '../../../../services/alert_service.dart';
import '../../../../services/pdf_service.dart';

class BatchesPage extends StatefulWidget {
  const BatchesPage({Key? key}) : super(key: key);

  @override
  State<BatchesPage> createState() => _BatchesPageState();
}

class _BatchesPageState extends State<BatchesPage> {
  final _batchService = BatchService();
  final _alertService = AlertService();
  final _pdfService = PdfService();
  
  List<Batch> _batches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBatches();
  }

  Future<void> _loadBatches() async {
    setState(() => _isLoading = true);
    try {
      final batches = await _batchService.getAllBatches();
      setState(() => _batches = batches);
    } catch (e) {
      print('Error loading batches: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showCreateBatchDialog() {
    final nameController = TextEditingController();
    final moistureController = TextEditingController(text: '40.0');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create New Batch'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Batch Name',
                hintText: 'e.g., Batch #001',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: moistureController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Initial Moisture %',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter batch name')),
                  );
                }
                return;
              }
              
              final moisture = double.tryParse(moistureController.text) ?? 40.0;
              await _batchService.createBatch(
                name: nameController.text,
                initialMoisture: moisture,
              );
              
              if (mounted) {
                Navigator.pop(dialogContext);
                _loadBatches();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Batch created successfully')),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showBatchDetails(Batch batch) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              batch.name,
              style: Theme.of(sheetContext).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _buildDetailRow(sheetContext, 'Status', batch.status.toUpperCase()),
            _buildDetailRow(sheetContext, 'Started', _formatDate(batch.startDate)),
            if (batch.endDate != null)
              _buildDetailRow(sheetContext, 'Ended', _formatDate(batch.endDate!)),
            _buildDetailRow(
              sheetContext,
              'Duration',
              '${batch.dryingDuration.inHours}h ${batch.dryingDuration.inMinutes % 60}m',
            ),
            const Divider(height: 24),
            _buildDetailRow(
              sheetContext,
              'Initial Moisture',
              '${batch.initialMoisture.toStringAsFixed(2)}%',
            ),
            _buildDetailRow(
              sheetContext,
              'Final Moisture',
              '${batch.finalMoisture.toStringAsFixed(2)}%',
            ),
            _buildDetailRow(
              sheetContext,
              'Reduction',
              '${batch.moistureReduction.toStringAsFixed(2)}%',
            ),
            if (batch.qualityResult != null) ...[
              const Divider(height: 24),
              _buildDetailRow(sheetContext, 'Quality', batch.qualityResult!),
              if (batch.confidence != null)
                _buildDetailRow(
                  sheetContext,
                  'Confidence',
                  '${(batch.confidence! * 100).toStringAsFixed(1)}%',
                ),
            ],
            const SizedBox(height: 16),
            if (batch.isActive) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (mounted) Navigator.pop(sheetContext);
                    await _completeBatch(batch);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                  ),
                  child: const Text('Mark as Completed'),
                ),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (mounted) Navigator.pop(sheetContext);
                  await _exportBatchPDF(batch);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                ),
                child: const Text('Export as PDF'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeBatch(Batch batch) async {
    final moistureController = TextEditingController(
      text: batch.finalMoisture.toString(),
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Complete Batch'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: moistureController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Final Moisture %',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final moisture = double.tryParse(moistureController.text) ?? 0;
              await _batchService.completeBatch(batch.id, moisture);
              if (mounted) {
                Navigator.pop(dialogContext);
                _loadBatches();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Batch marked as completed')),
                );
              }
            },
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportBatchPDF(Batch batch) async {
    try {
      final alerts = await _alertService.getAlertsByBatch(batch.id);
      
      await _pdfService.generateBatchReport(
        batchName: batch.name,
        startDate: batch.startDate,
        endDate: batch.endDate,
        initialMoisture: batch.initialMoisture,
        finalMoisture: batch.finalMoisture,
        qualityResult: batch.qualityResult ?? 'N/A',
        confidence: batch.confidence ?? 0.0,
        alerts: alerts,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF exported successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting PDF: $e')),
      );
    }
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildBatchCard(Batch batch) {
    final status = batch.status;
    final statusColor = status == 'completed'
        ? AppTheme.successColor
        : status == 'active'
            ? AppTheme.primaryGreen
            : AppTheme.warningColor;

    return Card(
      child: InkWell(
        onTap: () => _showBatchDetails(batch),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      batch.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Moisture: ${batch.finalMoisture.toStringAsFixed(2)}%',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    'Reduction: ${batch.moistureReduction.toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _formatDate(batch.startDate),
                style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Batch Management',
        subtitle: 'Track drying batches',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _batches.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_rounded,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No batches yet',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your first batch to get started',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    childAspectRatio: 2.5,
                  ),
                  itemCount: _batches.length,
                  itemBuilder: (context, index) => _buildBatchCard(_batches[index]),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateBatchDialog,
        tooltip: 'Create Batch',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: CustomBottomNavigation(
        currentLocation: AppRoutes.batches,
      ),
    );
  }
}
