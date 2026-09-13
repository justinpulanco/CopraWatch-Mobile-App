import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/notification_model.dart';
import '../theme/app_theme.dart';
import '../constants/app_constants.dart';

class NotificationCardWidget extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const NotificationCardWidget({
    Key? key,
    required this.notification,
    this.onTap,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final icon = _getNotificationIcon();
    final colors = _getNotificationColors();

    return Dismissible(
      key: Key(notification.id),
      onDismissed: (_) => onDismiss?.call(),
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          color: notification.isRead
              ? AppTheme.backgroundColor
              : colors['backgroundColor'],
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors['backgroundColor'],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: colors['iconColor'],
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppConstants.defaultPadding),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: notification.isRead
                                        ? FontWeight.w500
                                        : FontWeight.bold,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: colors['indicatorColor'],
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.description,
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatTime(notification.timestamp),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: AppTheme.textTertiary,
                                ),
                          ),
                          Text(
                            notification.typeString,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: colors['badgeColor'],
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon() {
    switch (notification.type) {
      case NotificationType.warning:
        return Icons.warning_rounded;
      case NotificationType.success:
        return Icons.check_circle_rounded;
      case NotificationType.critical:
        return Icons.error_rounded;
      case NotificationType.information:
        return Icons.info_rounded;
    }
  }

  Map<String, Color> _getNotificationColors() {
    switch (notification.type) {
      case NotificationType.warning:
        return {
          'backgroundColor': AppTheme.warningColor.withOpacity(0.15),
          'iconColor': AppTheme.warningColor,
          'indicatorColor': AppTheme.warningColor,
          'badgeColor': AppTheme.warningColor,
        };
      case NotificationType.success:
        return {
          'backgroundColor': AppTheme.successColor.withOpacity(0.15),
          'iconColor': AppTheme.successColor,
          'indicatorColor': AppTheme.successColor,
          'badgeColor': AppTheme.successColor,
        };
      case NotificationType.critical:
        return {
          'backgroundColor': AppTheme.errorColor.withOpacity(0.15),
          'iconColor': AppTheme.errorColor,
          'indicatorColor': AppTheme.errorColor,
          'badgeColor': AppTheme.errorColor,
        };
      case NotificationType.information:
        return {
          'backgroundColor': AppTheme.infoColor.withOpacity(0.15),
          'iconColor': AppTheme.infoColor,
          'indicatorColor': AppTheme.infoColor,
          'badgeColor': AppTheme.infoColor,
        };
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('MMM d, HH:mm').format(dateTime);
    }
  }
}
