import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_router.dart';
import 'core/constants/app_constants.dart';
import 'core/constants/api_constants.dart';
import 'services/sync_service.dart';
import 'services/notification_service.dart';

// Global navigator key for showing overlays
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification service
  await NotificationService().initialize();

  // Load saved settings before app starts
  final prefs = await SharedPreferences.getInstance();
  final ip = prefs.getString(PreferenceKeys.raspberryPiIP) ?? AppConstants.raspberryPiDefaultIP;
  final port = prefs.getInt(PreferenceKeys.raspberryPiPort) ?? AppConstants.raspberryPiDefaultPort;

  // Update API URL
  ApiConstants.updateBaseUrl(ip, port);
  
  // Setup auto-sync
  _setupAutoSync();

  runApp(const ProviderScope(child: CopraWatchApp()));
}

void _setupAutoSync() {
  final syncService = SyncService();
  
  // Listen for connectivity changes
  Connectivity().onConnectivityChanged.listen((result) {
    if (result.first != ConnectivityResult.none) {
      syncService.syncAllPendingData();
    }
  });
  
  // Initial sync attempt
  syncService.syncAllPendingData();
}

class CopraWatchApp extends StatelessWidget {
  const CopraWatchApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return Navigator(
          key: navigatorKey,
          onGenerateRoute: (settings) => MaterialPageRoute(
            builder: (context) => child ?? const SizedBox(),
          ),
        );
      },
    );
  }
}
