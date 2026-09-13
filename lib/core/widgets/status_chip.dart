import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../constants/app_constants.dart';

enum StatusType {
  active,
  completed,
  paused,
  warning,
  error,
  success,
}

class StatusChip extends StatelessWidget {
  final String label;
  final StatusType status;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool outlined;

  const StatusChip({
    Key? key,
    required this.label,
    required this.status,
    this.icon,
    this.onTap,
    this.outlined = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = _getStatusColors();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : colors['background'],
          border: outlined
              ? Border.all(color: colors['border'] as Color, width: 1.5)
              : null,
          borderRadius: BorderRadius.circular(AppConstants.chipBorderRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: colors['text'],
                size: 16,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors['text'],
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusColors() {
    switch (status) {
      case StatusType.active:
        return {
          'background': AppTheme.primaryGreenLight.withOpacity(0.15),
          'text': AppTheme.primaryGreen,
          'border': AppTheme.primaryGreen,
        };
      case StatusType.completed:
        return {
          'background': AppTheme.successColor.withOpacity(0.15),
          'text': AppTheme.successColor,
          'border': AppTheme.successColor,
        };
      case StatusType.paused:
        return {
          'background': AppTheme.warningColor.withOpacity(0.15),
          'text': AppTheme.warningColor,
          'border': AppTheme.warningColor,
        };
      case StatusType.warning:
        return {
          'background': AppTheme.warningColor.withOpacity(0.15),
          'text': AppTheme.warningColor,
          'border': AppTheme.warningColor,
        };
      case StatusType.error:
        return {
          'background': AppTheme.errorColor.withOpacity(0.15),
          'text': AppTheme.errorColor,
          'border': AppTheme.errorColor,
        };
      case StatusType.success:
        return {
          'background': AppTheme.successColor.withOpacity(0.15),
          'text': AppTheme.successColor,
          'border': AppTheme.successColor,
        };
    }
  }
}
