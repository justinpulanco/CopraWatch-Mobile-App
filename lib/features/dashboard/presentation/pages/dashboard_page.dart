import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_bottom_navigation.dart';
import '../../../../core/widgets/sensor_card.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routes/app_router.dart';
import '../widgets/batch_card.dart';
import '../models/dashboard_state.dart';
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
                      Text(
                        'Raspberry Pi disconnected',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppTheme.warningColor,
                            ),
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

              // Current batch
              if (dashboardState.currentBatch != null)
                BatchCard(batch: dashboardState.currentBatch!)
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
                const SizedBox(height: 12),

                // Solar irradiance card
                SensorCard(
                  title: 'Solar Irradiance',
                  value:
                      dashboardState.latestReading?.solarIrradiance
                          .toStringAsFixed(0) ??
                      '0',
                  unit: 'W/m²',
                  icon: Icons.light_mode_rounded,
                  iconColor: AppTheme.accentOrange,
                  maxValue: AppConstants.maxSolarIrradiance,
                  minValue: AppConstants.minSolarIrradiance,
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
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go(AppRoutes.scanner),
                    child: const Text('Scan Copra Quality'),
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

  dynamic _generateMockReading() {
    return null;
  }
}
