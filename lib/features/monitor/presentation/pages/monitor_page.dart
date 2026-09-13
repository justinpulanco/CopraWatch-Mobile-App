import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_bottom_navigation.dart';
import '../../../../core/widgets/sensor_card.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routes/app_router.dart';
import '../../services/sensor_provider.dart';

class MonitorPage extends ConsumerWidget {
  const MonitorPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sensorData = ref.watch(sensorDataProvider);
    final latest = sensorData.latest;

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
                  const SizedBox(height: 12),

                  // Moisture Level
                  SensorCard(
                    title: 'Moisture Level',
                    value: latest.moisture.toStringAsFixed(1),
                    unit: '%',
                    icon: Icons.water_drop_rounded,
                    iconColor: AppTheme.infoColor,
                    maxValue: AppConstants.maxMoisture,
                    minValue: AppConstants.minMoisture,
                    showProgress: true,
                  ),
                  const SizedBox(height: 12),

                  // Solar Irradiance
                  SensorCard(
                    title: 'Solar Irradiance',
                    value: latest.solarIrradiance.toStringAsFixed(0),
                    unit: 'W/m²',
                    icon: Icons.light_mode_rounded,
                    iconColor: AppTheme.accentOrange,
                    maxValue: AppConstants.maxSolarIrradiance,
                    minValue: AppConstants.minSolarIrradiance,
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

                  // Moisture Chart
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.defaultPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Moisture Level Trend',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 200,
                            child: _MoistureChart(
                              readings: sensorData.readings,
                            ),
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
        currentLocation: AppRoutes.monitor,
      ),
    );
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
              interval: 5,
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
        maxY: 80,
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

class _MoistureChart extends StatelessWidget {
  final List<dynamic> readings;

  const _MoistureChart({required this.readings});

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
        minY: 5,
        maxY: 50,
        lineBarsData: [
          LineChartBarData(
            spots: readings
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble(), e.value.moisture))
                .toList(),
            isCurved: true,
            color: AppTheme.infoColor,
            barWidth: 2,
            dotData: FlDotData(
              show: false,
              getDotPainter: (spot, percent, bar, index) =>
                  FlDotCirclePainter(
                radius: 3,
                color: AppTheme.infoColor,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.infoColor.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
}
