import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/csv_exporter.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_bottom_navigation.dart';
import '../../../../core/widgets/history_card.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/api_service.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../models/batch_model.dart';
import '../../../../services/batch_service.dart';
import '../../../../services/database_service.dart';
import '../../../../database/models/scan_result.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late List<Batch> _batches = [];
  String _selectedFilter = 'all';
  bool _isLoading = true;
  final _batchService = BatchService();
  final _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _loadBatches();
  }

  Future<void> _loadBatches() async {
    try {
      final batches = await _batchService.getAllBatches();
      setState(() {
        _batches = batches;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading batches: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredBatches = _filterBatches();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Batch History',
        subtitle: 'Previous Drying Sessions',
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: () => _showExportDialog(),
            tooltip: 'Export Data',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadBatches,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter chips
                  Padding(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('All', 'all'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Completed', 'completed'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Active', 'active'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Paused', 'paused'),
                        ],
                      ),
                    ),
                  ),

                  // Stats row
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.defaultPadding,
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildStatCard('Total Batches', '${_batches.length}'),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            'Completed',
                            '${_batches.where((b) => b.status == 'completed').length}',
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            'Active',
                            '${_batches.where((b) => b.status == 'active').length}',
                          ),
                        ],
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    child: filteredBatches.isEmpty
                        ? EmptyStateWidget(
                            icon: Icons.history_rounded,
                            title: 'No Batches Found',
                            description: 'No batches match the selected filter.',
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredBatches.length,
                            itemBuilder: (context, index) {
                              final batch = filteredBatches[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: HistoryCard(
                                  batch: batch,
                                  onTap: () => _showBatchDetails(batch),
                                  onDelete: () => _deleteBatch(batch),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: CustomBottomNavigation(
        currentLocation: AppRoutes.history,
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedFilter = value);
      },
      backgroundColor: isSelected ? AppTheme.primaryGreen : AppTheme.backgroundColor,
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: isSelected ? Colors.white : AppTheme.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Batch> _filterBatches() {
    switch (_selectedFilter) {
      case 'completed':
        return _batches.where((b) => b.status == 'completed').toList();
      case 'active':
        return _batches.where((b) => b.status == 'active').toList();
      case 'paused':
        return _batches.where((b) => b.status == 'paused').toList();
      default:
        return _batches;
    }
  }

  void _showBatchDetails(Batch batch) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              batch.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _detailRow('Status', batch.status.toUpperCase()),
            _detailRow('Duration', '${batch.dryingDuration.inHours}h'),
            if (batch.qualityResult != null)
              _detailRow('Quality', batch.qualityResult!),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          Text(value, style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }

  void _deleteBatch(Batch batch) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Batch'),
        content: Text('Delete batch ${batch.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                // Delete batch from database
                await _databaseService.deleteBatch(batch.id);
                // Also delete related sensor readings
                await _databaseService.deleteSensorReadingsByBatch(batch.id);
                
                setState(() => _batches.remove(batch));
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Batch deleted successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting batch: $e')),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Batch Data'),
        content: const Text('Choose what to export:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _exportAllBatches();
            },
            child: const Text('CSV to RPi'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _exportAllBatchesToPhone();
            },
            child: const Text('CSV to Phone'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportAllBatches() async {
    try {
      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Generating CSV...')),
        );
      }

      // Generate CSV content
      final csvContent = CSVExporter.generateAllBatchesCSV(_batches);
      
      final filename = CSVExporter.getExportFilename(allBatches: true);
      final filepath = await ApiService().uploadExport(
        filename: filename,
        bytes: utf8.encode(csvContent),
        contentType: 'text/csv',
      );
      if (filepath == null) throw Exception('Could not save export on Raspberry Pi');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported to RPi: $filepath'),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportAllBatchesToPhone() async {
    try {
      final directory = await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
      final filename = CSVExporter.getExportFilename(allBatches: true);
      final file = File('${directory.path}/$filename');
      await file.writeAsString(
        CSVExporter.generateAllBatchesCSV(_batches),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV saved on phone: ${file.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Phone CSV export failed: $e')),
        );
      }
    }
  }
}
