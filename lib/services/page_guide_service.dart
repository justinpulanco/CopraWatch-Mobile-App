import 'package:flutter/material.dart';
import '../models/guide_step.dart';

class PageGuideService {
  static Map<String, List<GuideStep>> _pageGuides = {
    'dashboard': _getDashboardGuide(),
    'monitor': _getMonitorGuide(),
    'scanner': _getScannerGuide(),
    'batches': _getBatchesGuide(),
    'analytics': _getAnalyticsGuide(),
    'settings': _getSettingsGuide(),
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
        description: "Quickly access Monitor, Scanner, or create new batches directly from the dashboard.",
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

  static List<GuideStep> _getScannerGuide() {
    return [
      GuideStep(
        title: "AI Quality Assessment",
        description: "Use the camera to capture copra images for intelligent quality classification.",
        iconPath: "assets/images/ai_scan.png",
      ),
      GuideStep(
        title: "Camera Setup",
        description: "Position copra clearly in frame with good lighting. Avoid shadows and reflections.",
        iconPath: "assets/images/camera_setup.png",
      ),
      GuideStep(
        title: "Capture & Analyze",
        description: "Tap CAPTURE to take a photo. The AI will classify as Under-dried, Optimal, or Over-dried.",
        iconPath: "assets/images/capture.png",
      ),
      GuideStep(
        title: "Save Results",
        description: "Review the AI classification and confidence score, then save to your active batch.",
        iconPath: "assets/images/save_results.png",
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
}