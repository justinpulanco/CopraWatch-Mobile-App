import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/batch_model.dart';
import '../theme/app_theme.dart';
import '../constants/app_constants.dart';
import 'status_chip.dart';

class HistoryCard extends StatelessWidget {
  final Batch batch;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const HistoryCard({
    Key? key,
    required this.batch,
    this.onTap,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with batch name and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          batch.name,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM d, yyyy • HH:mm').format(
                            batch.startDate,
                          ),
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      StatusChip(
                        label: batch.status.toUpperCase(),
                        status: _getStatusType(batch.status),
                        outlined: false,
                      ),
                      if (onDelete != null)
                        IconButton(
                          icon: const Icon(Icons.more_vert_rounded),
                          iconSize: 18,
                          constraints: const BoxConstraints.tightFor(
                            width: 24,
                            height: 24,
                          ),
                          onPressed: () => _showOptions(context),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Stats grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                children: [
                  _buildStatItem(
                    context,
                    'Temperature',
                    '${batch.readings.isNotEmpty ? batch.readings.last.temperature : 0}°C',
                  ),
                  _buildStatItem(
                    context,
                    'Humidity',
                    '${batch.readings.isNotEmpty ? batch.readings.last.humidity : 0}%',
                  ),
                  _buildStatItem(
                    context,
                    'Duration',
                    '${batch.dryingDuration.inHours}h ${batch.dryingDuration.inMinutes % 60}m',
                  ),
                  _buildStatItem(
                    context,
                    'Moisture',
                    batch.finalMoistureStatus,
                  ),
                ],
              ),

              if (batch.qualityResult != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _getQualityColor(batch.qualityResult!)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      AppConstants.buttonBorderRadius,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        batch.qualityResult!,
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                              color: _getQualityColor(batch.qualityResult!),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      if (batch.confidence != null)
                        Text(
                          '${(batch.confidence! * 100).toStringAsFixed(0)}%',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: _getQualityColor(batch.qualityResult!)
                                    .withOpacity(0.7),
                              ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  StatusType _getStatusType(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return StatusType.active;
      case 'completed':
        return StatusType.completed;
      case 'paused':
        return StatusType.paused;
      default:
        return StatusType.active;
    }
  }

  Color _getQualityColor(String quality) {
    if (quality.contains('Optimally')) {
      return AppTheme.successColor;
    } else if (quality.contains('Under')) {
      return AppTheme.infoColor;
    } else {
      return AppTheme.warningColor;
    }
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded),
              title: const Text('Delete'),
              textColor: AppTheme.errorColor,
              iconColor: AppTheme.errorColor,
              onTap: () {
                Navigator.pop(context);
                onDelete?.call();
              },
            ),
          ],
        ),
      ),
    );
  }
}
