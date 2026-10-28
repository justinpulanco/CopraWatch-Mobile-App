import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/widgets/mjpeg_preview.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_bottom_navigation.dart';
import '../../../../core/widgets/sensor_card.dart';
import '../../../../core/widgets/page_guide_dialog.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routes/app_router.dart';
import '../../services/sensor_provider.dart';
import '../../../dashboard/services/dashboard_provider.dart';

class MonitorPage extends ConsumerWidget {
  const MonitorPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sensorData = ref.watch(sensorDataProvider);
    final latest = sensorData.latest;
    final dashboardState = ref.watch(dashboardStateProvider);
    final qualityResult = dashboardState.latestQualityResult;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Live Monitor',
        subtitle: 'Real-time Sensor Data',
        actions: [
          if (sensorData.isConnected)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.successColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Connected',
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppTheme.successColor,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.warningColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Offline',
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppTheme.warningColor,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: latest == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.defaultPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Live Camera Preview',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'View only — capture with the button on the device.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: ColoredBox(
                                color: Colors.black87,
                                child: MjpegPreview(
                                  url: ApiConstants.cameraStream,
                                  headers: {
                                    'X-API-Key': ApiConstants.apiKey,
                                  },
                                  errorBuilder: (context) => const Center(
                                    child: Text(
                                      'Camera preview unavailable. Check device connection.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Quality Result Display
                    if (qualityResult != null && qualityResult.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
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
                      margin: const EdgeInsets.only(bottom: 16),
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

                  // Current readings cards
                  Text(
                    'Current Readings',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),

                  // Temperature
                  SensorCard(
                    title: 'Temperature',
                    value: latest.temperature.toStringAsFixed(1),
                    unit: '°C',
                    icon: Icons.thermostat_rounded,
                    iconColor: AppTheme.accentOrange,
                    maxValue: AppConstants.maxTemperature,
                    minValue: AppConstants.minTemperature,
                    showProgress: true,
                  ),
                  const SizedBox(height: 12),

                  // Humidity
                  SensorCard(
                    title: 'Humidity',
                    value: latest.humidity.toStringAsFixed(1),
                    unit: '%',
                    icon: Icons.opacity_rounded,
                    iconColor: AppTheme.primaryGreen,
                    maxValue: AppConstants.maxHumidity,
                    minValue: AppConstants.minHumidity,
                    showProgress: true,
                  ),
                  const SizedBox(height: 24),

                  // Charts
                  Text(
                    'Historical Data (24h)',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),

                  // Temperature Chart
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.defaultPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Temperature Trend',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 200,
                            child: _TemperatureChart(
                              readings: sensorData.readings,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Humidity Chart
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.defaultPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Humidity Trend',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 200,
                            child: _HumidityChart(
                              readings: sensorData.readings,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const SizedBox(height: 24),
                ],
              ),
            ),

      bottomNavigationBar: CustomBottomNavigation(
        currentLocation: AppRoutes.monitor,
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

class _TemperatureChart extends StatelessWidget {
  final List<dynamic> readings;

  const _TemperatureChart({required this.readings});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 10,  // Increased for higher temperature range
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppTheme.dividerColor,
              strokeWidth: 1,
            );
          },
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
              reservedSize: 30,
              interval: (readings.length / 5).toDouble(),
              getTitlesWidget: (value, meta) {
                if (value.toInt() < readings.length) {
                  return const Text('');
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 10,  // Increased for higher range
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}°C',
                  style: const TextStyle(fontSize: 10),
                );
              },
              reservedSize: 42,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: AppTheme.dividerColor),
            left: BorderSide(color: AppTheme.dividerColor),
          ),
        ),
        minY: 30,
        maxY: 160,  // Increased for higher landahan temperatures
        lineBarsData: [
          LineChartBarData(
            spots: readings
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble(), e.value.temperature))
                .toList(),
            isCurved: true,
            color: AppTheme.accentOrange,
            barWidth: 2,
            dotData: FlDotData(
              show: false,
              getDotPainter: (spot, percent, bar, index) =>
                  FlDotCirclePainter(
                radius: 3,
                color: AppTheme.accentOrange,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.accentOrange.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
}

class _HumidityChart extends StatelessWidget {
  final List<dynamic> readings;

  const _HumidityChart({required this.readings});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppTheme.dividerColor,
              strokeWidth: 1,
            );
          },
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
              reservedSize: 30,
              interval: (readings.length / 5).toDouble(),
              getTitlesWidget: (value, meta) => const Text(''),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 5,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}%',
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
            bottom: BorderSide(color: AppTheme.dividerColor),
            left: BorderSide(color: AppTheme.dividerColor),
          ),
        ),
        minY: 0,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: readings
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble(), e.value.humidity))
                .toList(),
            isCurved: true,
            color: AppTheme.primaryGreen,
            barWidth: 2,
            dotData: FlDotData(
              show: false,
              getDotPainter: (spot, percent, bar, index) =>
                  FlDotCirclePainter(
                radius: 3,
                color: AppTheme.primaryGreen,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.primaryGreen.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
}


