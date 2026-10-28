import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../models/batch_model.dart';

class BatchCard extends StatelessWidget {
  final Batch batch;
  final SensorReading? latestReading;
  final Map<String, dynamic>? qualityResult;

  const BatchCard({
    Key? key,
    required this.batch,
    this.latestReading,
    this.qualityResult,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final duration = batch.dryingDuration;
    final durationText = '${duration.inHours}h ${duration.inMinutes % 60}m';
    final result = qualityResult;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        batch.name,
                        style: Theme.of(context).textTheme.titleLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                        Text(
                        DateFormat('Started MMM d, h:mm a').format(batch.startDate),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                StatusChip(
                  label: batch.status.toUpperCase(),
                  status: batch.isActive ? StatusType.active : StatusType.completed,
                  outlined: false,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Quality Result (if available)
            if (result != null && result.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getQualityColor(result['classification'] as String?)
                            .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        result['classification'] ?? 'Unknown',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: _getQualityColor(result['classification'] as String?),
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Confidence: ${(result['confidence'] as double? ?? 0.0).toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),

            Row(
              children: [
                const Icon(
                  Icons.timer_outlined,
                  color: AppTheme.primaryGreen,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Monitoring Duration',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const Spacer(),
                Text(
                  durationText,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (latestReading != null)
              Row(
                children: [
                  Expanded(
                    child: _buildMetric(
                      context,
                      'Temperature',
                      '${latestReading!.temperature.toStringAsFixed(1)}°C',
                      Icons.thermostat_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetric(
                      context,
                      'Humidity',
                      '${latestReading!.humidity.toStringAsFixed(1)}%',
                      Icons.water_drop_outlined,
                    ),
                  ),
                ],
              ),

          ],
        ),
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

  Widget _buildMetric(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Semantics(
      label: '$label $value',
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryGreen, size: 18),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '$label: $value',
              style: Theme.of(context).textTheme.labelMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
