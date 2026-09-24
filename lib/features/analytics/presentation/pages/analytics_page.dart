import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_bottom_navigation.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../models/batch_model.dart';
import '../../../../services/batch_service.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({Key? key}) : super(key: key);

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final BatchService _batchService = BatchService();
  List<Batch> _completedBatches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    final batches = await _batchService.getAllBatches();
    if (!mounted) return;
    setState(() {
      _completedBatches =
          batches.where((batch) => batch.status == 'completed').toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_completedBatches.isEmpty) {
      return _buildEmptyAnalytics(context);
    }

    final totalBatches = _completedBatches.length;
    final optimalCount = _countQuality('optimally');
    final underCount = _countQuality('under');
    final overCount = _countQuality('over');
    final averageDuration = _completedBatches
            .map((batch) => batch.dryingDuration.inMinutes)
            .reduce((a, b) => a + b) /
        totalBatches /
        60;
    final successRate = optimalCount / totalBatches * 100;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Analytics & Insights',
        subtitle: 'Data-Driven Performance',
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary cards
            Text(
              'Overall Statistics',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildSummaryCard(
                  context,
                  'Total Batches',
                  '$totalBatches',
                  Icons.category_rounded,
                  AppTheme.primaryGreen,
                ),
                _buildSummaryCard(
                  context,
                  'Avg Duration',
                  '${averageDuration.toStringAsFixed(1)}h',
                  Icons.schedule_rounded,
                  AppTheme.accentOrange,
                ),
                _buildSummaryCard(
                  context,
                  'Success Rate',
                  '${successRate.toStringAsFixed(1)}%',
                  Icons.trending_up_rounded,
                  AppTheme.successColor,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Quality distribution
            Text(
              'Quality Distribution',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sections: [
                            PieChartSectionData(
                              value: optimalCount.toDouble(),
                              color: AppTheme.successColor,
                              title: '${_percentage(optimalCount, totalBatches)}%',
                              radius: 60,
                              titleStyle: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            PieChartSectionData(
                              value: underCount.toDouble(),
                              color: AppTheme.infoColor,
                              title: '${_percentage(underCount, totalBatches)}%',
                              radius: 60,
                              titleStyle: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            PieChartSectionData(
                              value: overCount.toDouble(),
                              color: AppTheme.warningColor,
                              title: '${_percentage(overCount, totalBatches)}%',
                              radius: 60,
                              titleStyle: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildLegendItem(
                          'Optimally-Dried',
                          AppTheme.successColor,
                        ),
                        _buildLegendItem('Under-Dried', AppTheme.infoColor),
                        _buildLegendItem('Over-Dried', AppTheme.warningColor),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Drying duration trends
            Text(
              'Drying Duration Trends',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: 60,
                          barTouchData: BarTouchData(
                            enabled: false,
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    _durationTitle(value.toInt()),
                                    style: const TextStyle(fontSize: 10),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    '${value.toInt()}h',
                                    style: const TextStyle(fontSize: 10),
                                  );
                                },
                                reservedSize: 40,
                              ),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border(
                              bottom:
                                  BorderSide(color: AppTheme.dividerColor),
                              left: BorderSide(color: AppTheme.dividerColor),
                            ),
                          ),
                          barGroups: [
                            BarChartGroupData(
                              x: 0,
                              barRods: [
                                BarChartRodData(
                                  toY: _durationAt(0),
                                  color: AppTheme.primaryGreen,
                                  width: 20,
                                ),
                              ],
                            ),
                            BarChartGroupData(
                              x: 1,
                              barRods: [
                                BarChartRodData(
                                  toY: _durationAt(1),
                                  color: AppTheme.primaryGreen,
                                  width: 20,
                                ),
                              ],
                            ),
                            BarChartGroupData(
                              x: 2,
                              barRods: [
                                BarChartRodData(
                                  toY: _durationAt(2),
                                  color: AppTheme.primaryGreen,
                                  width: 20,
                                ),
                              ],
                            ),
                            BarChartGroupData(
                              x: 3,
                              barRods: [
                                BarChartRodData(
                                  toY: _durationAt(3),
                                  color: AppTheme.primaryGreen,
                                  width: 20,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Recommendations
            Text(
              'AI Recommendations',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),

            Card(
              color: AppTheme.primaryGreen.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.lightbulb_rounded,
                            color: AppTheme.primaryGreen,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Based on your recent batches',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildRecommendation(
                      context,
                      'Batch history',
                      '$totalBatches completed batch records are included in these results.',
                    ),
                    const SizedBox(height: 12),
                    _buildRecommendation(
                      context,
                      'Quality coverage',
                      'Quality distribution is based only on saved batch results.',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Performance metrics
            Text(
              'Performance Metrics',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMetricRow(
                      context,
                      'Consistency',
                      totalBatches > 1 ? 'Measured' : 'Needs more data',
                      AppTheme.successColor,
                    ),
                    const SizedBox(height: 12),
                    _buildMetricRow(
                      context,
                      'Quality Score',
                      '${successRate.toStringAsFixed(1)}% optimal',
                      AppTheme.primaryGreen,
                    ),
                    const SizedBox(height: 12),
                    _buildMetricRow(
                      context,
                      'Energy Efficiency',
                      'No data',
                      AppTheme.accentOrange,
                    ),
                    const SizedBox(height: 12),
                    _buildMetricRow(
                      context,
                      'Solar Utilization',
                      'No data',
                      AppTheme.infoColor,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigation(
        currentLocation: AppRoutes.analytics,
      ),
    );
  }

  Widget _buildEmptyAnalytics(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Analytics & Insights',
        subtitle: 'Data-Driven Performance',
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.analytics_outlined,
                size: 64,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                'No analytics data yet',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Complete a drying batch to see real performance data here.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavigation(
        currentLocation: AppRoutes.analytics,
      ),
    );
  }

  int _countQuality(String value) {
    return _completedBatches.where((batch) {
      final quality = batch.qualityResult?.toLowerCase() ?? '';
      return quality.contains(value);
    }).length;
  }

  int _percentage(int value, int total) {
    return (value / total * 100).round();
  }

  double _durationAt(int index) {
    final sorted = [..._completedBatches]
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    if (index >= sorted.length) return 0;
    return sorted[index].dryingDuration.inMinutes / 60;
  }

  String _durationTitle(int index) {
    final sorted = [..._completedBatches]
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    if (index >= sorted.length) return '';
    return 'B${index + 1}';
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
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
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildRecommendation(
      BuildContext context, String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
      ],
    );
  }

  Widget _buildMetricRow(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            value,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}
