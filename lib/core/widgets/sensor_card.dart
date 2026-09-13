import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../constants/app_constants.dart';

class SensorCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color? backgroundColor;
  final Color? iconColor;
  final double? maxValue;
  final double? minValue;
  final bool showProgress;
  final VoidCallback? onTap;

  const SensorCard({
    Key? key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    this.backgroundColor,
    this.iconColor,
    this.maxValue,
    this.minValue,
    this.showProgress = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double? numValue = double.tryParse(value);
    final progressValue = _calculateProgress(numValue);

    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: backgroundColor ?? AppTheme.surfaceColor,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (iconColor ?? AppTheme.primaryGreen)
                          .withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(AppConstants.chipBorderRadius),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor ?? AppTheme.primaryGreen,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Value and unit
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: value,
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    TextSpan(
                      text: ' $unit',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ),

              if (showProgress && progressValue != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    minHeight: 6,
                    backgroundColor: AppTheme.dividerColor,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getProgressColor(),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  double? _calculateProgress(double? value) {
    if (value == null || maxValue == null || minValue == null) return null;
    final range = maxValue! - minValue!;
    if (range == 0) return 0;
    return ((value - minValue!) / range).clamp(0.0, 1.0);
  }

  Color _getProgressColor() {
    if (value.isEmpty) return AppTheme.primaryGreen;

    final numValue = double.tryParse(value);
    if (numValue == null) return AppTheme.primaryGreen;

    // Check for critical threshold
    if (title.contains('Temperature')) {
      if (numValue > AppConstants.temperatureCriticalThreshold) {
        return AppTheme.errorColor;
      } else if (numValue > AppConstants.temperatureWarningThreshold) {
        return AppTheme.warningColor;
      }
    } else if (title.contains('Humidity')) {
      if (numValue > AppConstants.humidityCriticalThreshold) {
        return AppTheme.errorColor;
      } else if (numValue > AppConstants.humidityWarningThreshold) {
        return AppTheme.warningColor;
      }
    } else if (title.contains('Moisture')) {
      if (numValue > AppConstants.moistureCriticalThreshold) {
        return AppTheme.errorColor;
      } else if (numValue > AppConstants.moistureWarningThreshold) {
        return AppTheme.warningColor;
      }
    }

    return AppTheme.successColor;
  }
}
