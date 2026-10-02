import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/widgets/user_guide_dialog.dart';

class FirstTimeService {
  static const String _keyFirstTime = 'is_first_time';
  static const String _keyPageVisited = 'page_visited_';

  /// Check if this is the user's first time opening the app
  static Future<bool> isFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyFirstTime) ?? true;
  }

  /// Mark that the user has completed first-time setup
  static Future<void> markFirstTimeComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFirstTime, false);
  }

  /// Check if user has visited a specific page before
  static Future<bool> hasVisitedPage(String pageName) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_keyPageVisited$pageName') ?? false;
  }

  /// Mark that user has visited a specific page
  static Future<void> markPageVisited(String pageName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_keyPageVisited$pageName', true);
  }

  /// Show welcome guide on first app launch
  static Future<void> showWelcomeGuideIfNeeded(BuildContext context) async {
    if (await isFirstTime()) {
      // Small delay to ensure UI is ready
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (context.mounted) {
        await showUserGuide(context);
        await markFirstTimeComplete();
      }
    }
  }

  /// Show page guide if user hasn't seen it yet (optional for specific pages)
  static Future<void> showPageGuideIfFirstVisit(
    BuildContext context, 
    String pageName, 
    String pageTitle, 
    Widget Function() guideBuilder,
  ) async {
    if (!await hasVisitedPage(pageName)) {
      // Small delay for better UX
      await Future.delayed(const Duration(milliseconds: 1000));
      
      if (context.mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text('Welcome to $pageTitle!'),
            content: Text('This is your first time here. Would you like a quick tour?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  markPageVisited(pageName);
                },
                child: const Text('Skip'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  guideBuilder();
                  markPageVisited(pageName);
                },
                child: const Text('Show Guide'),
              ),
            ],
          ),
        );
      }
    }
  }

  /// Reset all first-time flags (useful for testing or reset functionality)
  static Future<void> resetFirstTimeFlags() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => 
      key == _keyFirstTime || key.startsWith(_keyPageVisited)
    ).toList();
    
    for (String key in keys) {
      await prefs.remove(key);
    }
  }
}