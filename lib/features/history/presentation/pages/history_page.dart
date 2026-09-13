import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_bottom_navigation.dart';
import '../../../../core/widgets/history_card.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../models/batch_model.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late List<Batch> _batches;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _batches = _generateMockBatches();
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
        ],
      ),
      body: SingleChildScrollView(
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
            _detailRow('Initial Moisture', '${batch.initialMoisture}%'),
            _detailRow('Final Moisture', '${batch.finalMoisture}%'),
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
            onPressed: () {
              setState(() => _batches.remove(batch));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Batch deleted')),
              );
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
        title: const Text('Export Data'),
        content: const Text('Export batch history as CSV?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data exported successfully')),
              );
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  List<Batch> _generateMockBatches() {
    return [
      Batch(
        id: '1',
        name: 'Batch #2024-01-001',
        startDate: DateTime.now().subtract(const Duration(days: 5)),
        endDate: DateTime.now().subtract(const Duration(days: 3)),
        initialMoisture: 45.0,
        finalMoisture: 12.5,
        status: 'completed',
        readings: [],
        qualityResult: 'Optimally-Dried',
        confidence: 0.92,
      ),
      Batch(
        id: '2',
        name: 'Batch #2024-01-002',
        startDate: DateTime.now().subtract(const Duration(days: 2)),
        endDate: DateTime.now().subtract(const Duration(days: 1)),
        initialMoisture: 48.0,
        finalMoisture: 13.0,
        status: 'completed',
        readings: [],
        qualityResult: 'Optimally-Dried',
        confidence: 0.88,
      ),
      Batch(
        id: '3',
        name: 'Batch #2024-01-003',
        startDate: DateTime.now().subtract(const Duration(hours: 18)),
        initialMoisture: 46.0,
        finalMoisture: 28.0,
        status: 'active',
        readings: [],
      ),
      Batch(
        id: '4',
        name: 'Batch #2024-01-004',
        startDate: DateTime.now().subtract(const Duration(days: 10)),
        endDate: DateTime.now().subtract(const Duration(days: 8)),
        initialMoisture: 42.0,
        finalMoisture: 11.8,
        status: 'completed',
        readings: [],
        qualityResult: 'Optimally-Dried',
        confidence: 0.95,
      ),
      Batch(
        id: '5',
        name: 'Batch #2024-01-005',
        startDate: DateTime.now().subtract(const Duration(days: 15)),
        endDate: DateTime.now().subtract(const Duration(days: 13)),
        initialMoisture: 50.0,
        finalMoisture: 9.5,
        status: 'completed',
        readings: [],
        qualityResult: 'Over-Dried',
        confidence: 0.83,
      ),
    ];
  }
}
