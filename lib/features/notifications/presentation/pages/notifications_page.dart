import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/notification_card.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/notification_model.dart';
import '../../../../services/database_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late List<AppNotification> _notifications = [];
  String _selectedFilter = 'all';
  bool _isLoading = true;
  final _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final notificationMaps = await _databaseService.getAllNotifications();
      final notifications = notificationMaps
          .map((map) => AppNotification.fromMap(map))
          .toList();
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading notifications: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredNotifications = _filterNotifications();
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Notifications',
        subtitle: 'Recent Events & Alerts',
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard_rounded),
            tooltip: 'Main Dashboard',
            onPressed: () => context.go('/'),
          ),
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
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadNotifications,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
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

  void _markAsRead(AppNotification notification) async {
    try {
      final updatedNotification = notification.copyWith(isRead: true);
      await _databaseService.updateNotification(updatedNotification.toMap());
      setState(() {
        final index = _notifications.indexOf(notification);
        if (index != -1) {
          _notifications[index] = updatedNotification;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating notification: $e')),
        );
      }
    }
  }

  void _markAllAsRead() async {
    try {
      final updatedNotifications = _notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      for (var notification in updatedNotifications) {
        await _databaseService.updateNotification(notification.toMap());
      }
      setState(() => _notifications = updatedNotifications);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating notifications: $e')),
        );
      }
    }
  }

  void _removeNotification(AppNotification notification) async {
    try {
      await _databaseService.deleteNotification(notification.id);
      setState(() => _notifications.remove(notification));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting notification: $e')),
        );
      }
    }
  }
}
