import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/custom_progress_bar.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../models/batch_model.dart';

class BatchCard extends StatelessWidget {
  final Batch batch;

  const BatchCard({
    Key? key,
    required this.batch,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final duration = batch.dryingDuration;
    final progress = (duration.inMinutes / (48 * 60)).clamp(0, 1) as double;

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
                        DateFormat('Started MMM d, HH:mm').format(batch.startDate),
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

            // Progress bar
            CustomProgressBar(
              progress: progress,
              label: 'Drying Progress',
              showPercentage: true,
            ),
            const SizedBox(height: 12),

            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
