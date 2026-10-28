import 'package:flutter/material.dart';
import '../models/guide_step.dart';

class PageGuideService {
  static Map<String, List<GuideStep>> _pageGuides = {
    'dashboard': _getDashboardGuide(),
    'monitor': _getMonitorGuide(),
    'batches': _getBatchesGuide(),
    'analytics': _getAnalyticsGuide(),
    'settings': _getSettingsGuide(),
    'notifications': _getNotificationsGuide(),
    'history': _getHistoryGuide(),
    'scanHistory': _getScanHistoryGuide(),
  };

  static List<GuideStep> getGuideForPage(String pageName) {
    return _pageGuides[pageName] ?? [];
  }

  static List<GuideStep> getAllGuides() {
    List<GuideStep> allGuides = [];
    _pageGuides.forEach((pageName, guides) {
      allGuides.addAll(guides);
    });
    return allGuides;
  }

  static List<GuideStep> _getDashboardGuide() {
    return [
      GuideStep(
        title: "Dashboard Overview",
        description: "Your main control center showing active batches, current sensor readings, and recent alerts.",
        iconPath: "assets/images/dashboard.png",
      ),
      GuideStep(
        title: "Active Batch Status",
        description: "View your currently running drying batch with real-time progress and environmental conditions.",
        iconPath: "assets/images/batch_active.png",
      ),
      GuideStep(
        title: "Quick Actions",
        description: "Open Monitor to view sensor readings and the live IoT camera preview, or manage batches.",
        iconPath: "assets/images/quick_actions.png",
      ),
      GuideStep(
        title: "Recent Alerts",
        description: "Stay informed about temperature warnings, humidity alerts, and system notifications.",
        iconPath: "assets/images/alerts.png",
      ),
    ];
  }

  static List<GuideStep> _getMonitorGuide() {
    return [
      GuideStep(
        title: "Live Sensor Data",
        description: "View real-time temperature and humidity readings from your Raspberry Pi sensors.",
        iconPath: "assets/images/sensors.png",
      ),
      GuideStep(
        title: "Connection Status",
        description: "Green 'Connected' means data is flowing. Orange 'Offline' means check your RPi connection.",
        iconPath: "assets/images/connection.png",
      ),
      GuideStep(
        title: "Live Camera Preview",
        description: "The app only displays the camera feed. Press the physical button on the IoT device to save and classify a capture.",
        iconPath: "assets/images/camera_setup.png",
      ),
      GuideStep(
        title: "Temperature Chart",
        description: "Track temperature trends over time. Optimal range is 90-110°C for effective copra drying.",
        iconPath: "assets/images/temp_chart.png",
      ),
      GuideStep(
        title: "Humidity Chart",
        description: "Monitor humidity levels. Lower humidity (5-12%) indicates better drying progress.",
        iconPath: "assets/images/humidity_chart.png",
      ),
    ];
  }

  static List<GuideStep> _getBatchesGuide() {
    return [
      GuideStep(
        title: "Batch Management",
        description: "Create, monitor, and complete copra drying batches with detailed tracking.",
        iconPath: "assets/images/batch_mgmt.png",
      ),
      GuideStep(
        title: "Create New Batch",
        description: "Tap the + button to start a new batch. Give it a descriptive name and set initial condition.",
        iconPath: "assets/images/new_batch.png",
      ),
      GuideStep(
        title: "Track Progress",
        description: "Monitor active batches with duration tracking, pause/resume functionality, and status updates.",
        iconPath: "assets/images/batch_progress.png",
      ),
      GuideStep(
        title: "Complete Batch",
        description: "Mark batches as complete with final moisture condition and AI classification results.",
        iconPath: "assets/images/complete_batch.png",
      ),
      GuideStep(
        title: "Export Reports",
        description: "Generate PDF reports and save them to phone or export to Raspberry Pi storage.",
        iconPath: "assets/images/export.png",
      ),
    ];
  }

  static List<GuideStep> _getAnalyticsGuide() {
    return [
      GuideStep(
        title: "Performance Analytics",
        description: "Analyze your drying performance with detailed statistics and insights.",
        iconPath: "assets/images/performance.png",
      ),
      GuideStep(
        title: "Quality Distribution",
        description: "View pie chart showing percentage of Under-dried, Optimal, and Over-dried batches.",
        iconPath: "assets/images/quality_pie.png",
      ),
      GuideStep(
        title: "Optimal Conditions",
        description: "Learn the ideal temperature (90-110°C) and humidity (5-12%) ranges for best results.",
        iconPath: "assets/images/optimal.png",
      ),
      GuideStep(
        title: "AI Recommendations",
        description: "Get personalized suggestions based on your batch history to improve drying quality.",
        iconPath: "assets/images/recommendations.png",
      ),
      GuideStep(
        title: "Trends & Patterns",
        description: "Identify patterns in drying duration, environmental conditions, and success rates.",
        iconPath: "assets/images/trends.png",
      ),
    ];
  }

  static List<GuideStep> _getSettingsGuide() {
    return [
      GuideStep(
        title: "System Settings",
        description: "Configure your CopraWatch system for optimal performance and connectivity.",
        iconPath: "assets/images/system_settings.png",
      ),
      GuideStep(
        title: "Raspberry Pi Connection",
        description: "Set the IP address and port of your Raspberry Pi. Default is usually 192.168.1.100:5000.",
        iconPath: "assets/images/rpi_settings.png",
      ),
      GuideStep(
        title: "Alert Thresholds",
        description: "Customize temperature and humidity warning levels for your specific drying requirements.",
        iconPath: "assets/images/thresholds.png",
      ),
      GuideStep(
        title: "App Preferences",
        description: "Adjust notification settings, temperature units, and other app preferences.",
        iconPath: "assets/images/preferences.png",
      ),
      GuideStep(
        title: "User Guides Access",
        description: "View all page-specific guides and tutorials from this central location.",
        iconPath: "assets/images/all_guides.png",
      ),
    ];
  }

  static List<GuideStep> _getNotificationsGuide() {
    return [
      GuideStep(
        title: 'Notifications',
        description: 'Review alerts from temperature, humidity, and system events.',
        iconPath: 'assets/images/alerts.png',
      ),
      GuideStep(
        title: 'Read Alerts',
        description: 'Tap an alert to review its details and mark it as read.',
        iconPath: 'assets/images/notifications.png',
      ),
      GuideStep(
        title: 'Filter Events',
        description: 'Use the filter options to focus on the alerts you need.',
        iconPath: 'assets/images/filters.png',
      ),
    ];
  }

  static List<GuideStep> _getHistoryGuide() {
    return [
      GuideStep(
        title: 'Batch History',
        description: 'Review completed and previous copra drying batches.',
        iconPath: 'assets/images/batch_progress.png',
      ),
      GuideStep(
        title: 'Batch Details',
        description: 'Open a batch to view its drying duration, quality, and sensor summary.',
        iconPath: 'assets/images/complete_batch.png',
      ),
      GuideStep(
        title: 'Export Reports',
        description: 'Generate a report and save it to the phone or Raspberry Pi.',
        iconPath: 'assets/images/export.png',
      ),
    ];
  }

  static List<GuideStep> _getScanHistoryGuide() {
    return [
      GuideStep(
        title: 'Scan History',
        description: 'Review previous copra image classifications and confidence scores.',
        iconPath: 'assets/images/ai_scan.png',
      ),
      GuideStep(
        title: 'Classification Details',
        description: 'Check whether each scan is under-dried, optimally-dried, or over-dried.',
        iconPath: 'assets/images/save_results.png',
      ),
    ];
  }
}