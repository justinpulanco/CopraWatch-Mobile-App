import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/notification_card.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/notification_model.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late List<AppNotification> _notifications;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _notifications = _generateMockNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final filteredNotifications = _filterNotifications();
    final unreadCount =
        _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Notifications',
        subtitle: 'Recent Events & Alerts',
        actions: [
          if (unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: TextButton(
                  onPressed: _markAllAsRead,
                  child: Text(
                    'Mark all read',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Row(
                children: [
                  _buildFilterTab('All', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterTab('Warning', 'warning'),
                  const SizedBox(width: 8),
                  _buildFilterTab('Success', 'success'),
                  const SizedBox(width: 8),
                  _buildFilterTab('Critical', 'critical'),
                  const SizedBox(width: 8),
                  _buildFilterTab('Info', 'info'),
                ],
              ),
            ),
          ),

          // Notifications list
          Expanded(
            child: filteredNotifications.isEmpty
                ? EmptyStateWidget(
                    icon: Icons.notifications_off_rounded,
                    title: 'No Notifications',
                    description: 'You\'re all caught up!',
                  )
                : ListView.builder(
                    itemCount: filteredNotifications.length,
                    itemBuilder: (context, index) {
                      final notification = filteredNotifications[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          left: AppConstants.defaultPadding,
                          right: AppConstants.defaultPadding,
                          bottom: 8,
                          top: index == 0 ? 0 : 4,
                        ),
                        child: NotificationCardWidget(
                          notification: notification,
                          onTap: () => _markAsRead(notification),
                          onDismiss: () => _removeNotification(notification),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedFilter = value);
      },
      backgroundColor: isSelected ? AppTheme.primaryGreen : Colors.transparent,
      side: BorderSide(
        color: isSelected ? Colors.transparent : AppTheme.dividerColor,
      ),
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: isSelected ? Colors.white : AppTheme.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
    );
  }

  List<AppNotification> _filterNotifications() {
    final notifications = _notifications;

    switch (_selectedFilter) {
      case 'warning':
        return notifications
            .where((n) => n.type == NotificationType.warning)
            .toList();
      case 'success':
        return notifications
            .where((n) => n.type == NotificationType.success)
            .toList();
      case 'critical':
        return notifications
            .where((n) => n.type == NotificationType.critical)
            .toList();
      case 'info':
        return notifications
            .where((n) => n.type == NotificationType.information)
            .toList();
      default:
        return notifications;
    }
  }

  void _markAsRead(AppNotification notification) {
    setState(() {
      final index = _notifications.indexOf(notification);
      if (index != -1) {
        _notifications[index] = notification.copyWith(isRead: true);
      }
    });
  }

  void _markAllAsRead() {
    setState(() {
      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications marked as read')),
    );
  }

  void _removeNotification(AppNotification notification) {
    setState(() => _notifications.remove(notification));
  }

  List<AppNotification> _generateMockNotifications() {
    return [
      AppNotification(
        title: 'Batch Complete',
        description: 'Batch #2024-01-001 has completed drying',
        type: NotificationType.success,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: false,
        batchId: 'batch_1',
      ),
      AppNotification(
        title: 'High Temperature Alert',
        description: 'Temperature exceeded 75°C. Check ventilation.',
        type: NotificationType.warning,
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        isRead: false,
        batchId: 'batch_1',
      ),
      AppNotification(
        title: 'Critical: Sensor Offline',
        description: 'Humidity sensor is not responding. Immediate action required.',
        type: NotificationType.critical,
        timestamp: DateTime.now().subtract(const Duration(hours: 8)),
        isRead: true,
        batchId: 'batch_1',
      ),
      AppNotification(
        title: 'Quality Check Available',
        description: 'Sample is ready for quality classification',
        type: NotificationType.information,
        timestamp: DateTime.now().subtract(const Duration(hours: 12)),
        isRead: true,
        batchId: 'batch_1',
      ),
      AppNotification(
        title: 'Optimal Drying Conditions',
        description: 'All sensors are in optimal range for continued drying',
        type: NotificationType.success,
        timestamp: DateTime.now().subtract(const Duration(hours: 15)),
        isRead: true,
        batchId: 'batch_1',
      ),
      AppNotification(
        title: 'Maintenance Reminder',
        description: 'Solar panel cleaning recommended for optimal efficiency',
        type: NotificationType.information,
        timestamp: DateTime.now().subtract(const Duration(hours: 24)),
        isRead: true,
        batchId: 'batch_1',
      ),
      AppNotification(
        title: 'Moisture Target Reached',
        description: 'Target moisture level of 12% has been reached',
        type: NotificationType.success,
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
        isRead: true,
        batchId: 'batch_1',
      ),
      AppNotification(
        title: 'Humidity Alert',
        description: 'Humidity level above 25%. Reduce moisture input.',
        type: NotificationType.warning,
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 5)),
        isRead: true,
        batchId: 'batch_1',
      ),
    ];
  }
}
