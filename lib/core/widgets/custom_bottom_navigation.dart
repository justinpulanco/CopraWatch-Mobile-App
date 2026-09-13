import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../routes/app_router.dart';

class CustomBottomNavigation extends StatelessWidget {
  final String currentLocation;

  const CustomBottomNavigation({
    Key? key,
    required this.currentLocation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _getSelectedIndex(currentLocation),
      onTap: (index) => _navigateTo(context, index),
      backgroundColor: AppTheme.surfaceColor,
      selectedItemColor: AppTheme.primaryGreen,
      unselectedItemColor: AppTheme.textTertiary,
      elevation: 16,
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.dashboard_rounded),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.sensors_rounded),
          label: 'Monitor',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.camera_alt_rounded),
          label: 'Scanner',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.inventory_2_rounded),
          label: 'Batches',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.analytics_rounded),
          label: 'Analytics',
        ),
      ],
    );
  }

  int _getSelectedIndex(String location) {
    switch (location) {
      case AppRoutes.dashboard:
        return 0;
      case AppRoutes.monitor:
        return 1;
      case AppRoutes.scanner:
        return 2;
      case AppRoutes.batches:
        return 3;
      case AppRoutes.analytics:
        return 4;
      default:
        return 0;
    }
  }

  void _navigateTo(BuildContext context, int index) {
    final routes = [
      AppRoutes.dashboard,
      AppRoutes.monitor,
      AppRoutes.scanner,
      AppRoutes.batches,
      AppRoutes.analytics,
    ];
    context.go(routes[index]);
  }
}
