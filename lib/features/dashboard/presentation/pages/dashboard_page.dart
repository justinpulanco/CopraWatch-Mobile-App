import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_bottom_navigation.dart';
import '../../../../core/widgets/sensor_card.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/coprawatch_logo.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routes/app_router.dart';
import '../widgets/batch_card.dart';
import '../../services/dashboard_provider.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  void initState() {
    super.initState();
    // Refresh dashboard data periodically
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    // Note: Manual refresh removed as DashboardNotifier now
    // automatically watches sensorDataProvider for updates.
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardStateProvider);
    final qualityResult = dashboardState.latestQualityResult;

    if (dashboardState.isLoading && dashboardState.currentBatch == null) {
      return Scaffold(
        appBar: CustomAppBar(
          title: AppConstants.appName,
          showBackButton: false,
        ),
        body: const LoadingWidget(message: 'Loading dashboard...'),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: AppConstants.appName,
        subtitle: 'Real-time Monitoring',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_rounded),
            onPressed: () => context.go(AppRoutes.notifications),
            tooltip: 'Notifications',
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => context.go(AppRoutes.settings),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh dashboard
          await Future.delayed(const Duration(seconds: 1));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CopraWatchLogo(),
              const SizedBox(height: 20),

              // Connection status
              if (!dashboardState.isConnected)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.defaultPadding,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.wifi_off_rounded,
                        color: AppTheme.warningColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Offline',
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: AppTheme.warningColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            Text(
                              'Raspberry Pi is still recording data. Reconnect to view updates.',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppTheme.warningColor,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.settings),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.defaultPadding,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.cloud_done_rounded,
                        color: AppTheme.successColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Connected to Raspberry Pi',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppTheme.successColor,
                            ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Quality Result Display
                if (qualityResult != null && qualityResult.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  decoration: BoxDecoration(
                    color: _getQualityColor(
                            qualityResult['classification'] as String?)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getQualityColor(
                              qualityResult['classification'] as String?)
                          .withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Latest Quality Assessment',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _getQualityColor(
                                      qualityResult['classification'] as String?)
                                  .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              qualityResult['classification'] ?? 'Unknown',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Confidence: ${(qualityResult['confidence'] as double? ?? 0.0).toStringAsFixed(1)}%',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                      if (qualityResult['timestamp'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Updated: ${_formatTimestamp(qualityResult['timestamp'] as String?)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                          ),
                        ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  decoration: BoxDecoration(
                    color: AppTheme.textSecondary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'No quality assessment available yet',
                    style: TextStyle(color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 24),

              // Current batch
              if (dashboardState.currentBatch != null)
                BatchCard(
                  batch: dashboardState.currentBatch!,
                  latestReading: dashboardState.latestReading,
                  qualityResult: dashboardState.latestQualityResult,
                )
              else
                EmptyStateWidget(
                  icon: Icons.hourglass_empty_rounded,
                  title: 'No Active Batch',
                  description: 'Start a new drying batch to monitor progress.',
                  buttonText: 'Start New Batch',
                  onButtonPressed: () => context.go(AppRoutes.monitor),
                ),

              if (dashboardState.currentBatch != null) ...[
                const SizedBox(height: 24),

                // Sensor cards
                Text(
                  'Real-time Sensors',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),

                // Temperature card
                SensorCard(
                  title: 'Temperature',
                  value: dashboardState.latestReading?.temperature
                          .toStringAsFixed(1) ??
                      '0',
                  unit: '°C',
                  icon: Icons.thermostat_rounded,
                  iconColor: AppTheme.accentOrange,
                  maxValue: AppConstants.maxTemperature,
                  minValue: AppConstants.minTemperature,
                  showProgress: true,
                  onTap: () => context.go(AppRoutes.monitor),
                ),
                const SizedBox(height: 12),

                // Humidity card
                SensorCard(
                  title: 'Humidity',
                  value: dashboardState.latestReading?.humidity
                          .toStringAsFixed(1) ??
                      '0',
                  unit: '%',
                  icon: Icons.opacity_rounded,
                  iconColor: AppTheme.primaryGreen,
                  maxValue: AppConstants.maxHumidity,
                  minValue: AppConstants.minHumidity,
                  showProgress: true,
                  onTap: () => context.go(AppRoutes.monitor),
                ),
                const SizedBox(height: 24),

                // Action buttons
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go(AppRoutes.analytics),
                    child: const Text('View Analytics'),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavigation(
        currentLocation: AppRoutes.dashboard,
      ),
    );
  }

  Color _getQualityColor(String? classification) {
    if (classification == null) return AppTheme.textSecondary;
    switch (classification.toLowerCase()) {
      case 'optimally-dried':
      case 'optimally dried':
        return AppTheme.successColor;
      case 'under-dried':
      case 'under dried':
        return AppTheme.infoColor;
      case 'over-dried':
      case 'over dried':
        return AppTheme.warningColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      final dateTime = DateTime.parse(timestamp);
      return DateFormat('MMM d, h:mm a').format(dateTime);
    } catch (e) {
      return timestamp;
    }
  }
}
