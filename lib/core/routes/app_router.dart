import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/monitor/presentation/pages/monitor_page.dart';
import '../../features/scanner/presentation/pages/scanner_page.dart';
import '../../features/scanner/presentation/pages/history_page.dart';
import '../../features/analytics/presentation/pages/analytics_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/batches/presentation/pages/batches_page.dart';

class AppRoutes {
  static const String dashboard = '/';
  static const String monitor = '/monitor';
  static const String scanner = '/scanner';
  static const String history = '/history';
  static const String analytics = '/analytics';
  static const String notifications = '/notifications';
  static const String settings = '/settings';
  static const String batches = '/batches';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.dashboard,
  routes: [
    GoRoute(
      path: AppRoutes.dashboard,
      name: 'dashboard',
      builder: (context, state) => const DashboardPage(),
    ),
    GoRoute(
      path: AppRoutes.monitor,
      name: 'monitor',
      builder: (context, state) => const MonitorPage(),
    ),
    GoRoute(
      path: AppRoutes.scanner,
      name: 'scanner',
      builder: (context, state) => const ScannerPage(),
    ),
    GoRoute(
      path: AppRoutes.history,
      name: 'history',
      builder: (context, state) => const HistoryPage(),
    ),
    GoRoute(
      path: AppRoutes.analytics,
      name: 'analytics',
      builder: (context, state) => const AnalyticsPage(),
    ),
    GoRoute(
      path: AppRoutes.notifications,
      name: 'notifications',
      builder: (context, state) => const NotificationsPage(),
    ),
    GoRoute(
      path: AppRoutes.settings,
      name: 'settings',
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: AppRoutes.batches,
      name: 'batches',
      builder: (context, state) => const BatchesPage(),
    ),
  ],
);
