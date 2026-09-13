import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomProgressBar extends StatelessWidget {
  final double progress;
  final String label;
  final double? height;
  final Color? backgroundColor;
  final Color? progressColor;
  final bool showPercentage;

  const CustomProgressBar({
    Key? key,
    required this.progress,
    required this.label,
    this.height = 8,
    this.backgroundColor,
    this.progressColor,
    this.showPercentage = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0);
    final percentage = (clampedProgress * 100).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium,
            ),
            if (showPercentage)
              Text(
                '$percentage%',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: clampedProgress,
            minHeight: height,
            backgroundColor: backgroundColor ?? AppTheme.dividerColor,
            valueColor: AlwaysStoppedAnimation<Color>(
              progressColor ?? AppTheme.primaryGreen,
            ),
          ),
        ),
      ],
    );
  }
}
