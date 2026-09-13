import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_router.dart';
import 'core/constants/app_constants.dart';
import 'core/constants/api_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load saved settings before app starts
  final prefs = await SharedPreferences.getInstance();
  final ip = prefs.getString(PreferenceKeys.raspberryPiIP) ?? AppConstants.raspberryPiDefaultIP;
  final port = prefs.getInt(PreferenceKeys.raspberryPiPort) ?? AppConstants.raspberryPiDefaultPort;

  // Update API URL
  ApiConstants.updateBaseUrl(ip, port);

  runApp(const ProviderScope(child: CopraWatchApp()));
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
    );
  }
}
