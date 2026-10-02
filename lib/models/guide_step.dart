import 'package:flutter/material.dart';

class GuideStep {
  final String title;
  final String description;
  final String iconPath;
  final String? actionText;
  final VoidCallback? action;

  GuideStep({
    required this.title,
    required this.description,
    required this.iconPath,
    this.actionText,
    this.action,
  });
}

class UserGuideData {
  static List<GuideStep> getGuideSteps() {
    return [
      GuideStep(
        title: "Welcome to CopraWatch!",
        description: "Your smart copra drying monitoring system. Let's get you started with the basics.",
        iconPath: "assets/images/welcome.png",
      ),
      GuideStep(
        title: "Setup Your RPi Connection",
        description: "Connect your phone to the RPi WiFi network 'CopraWatch_XXXX' or ensure both devices are on the same network.",
        iconPath: "assets/images/wifi.png",
        actionText: "Open Settings",
      ),
      GuideStep(
        title: "Configure RPi IP Address",
        description: "Enter your Raspberry Pi IP address in Settings. Default is usually 192.168.1.100",
        iconPath: "assets/images/settings.png",
        actionText: "Go to Settings",
      ),
      GuideStep(
        title: "Start a New Batch",
        description: "Tap 'New Batch' to begin monitoring your copra drying process. Give it a descriptive name.",
        iconPath: "assets/images/batch.png",
        actionText: "Create Batch",
      ),
      GuideStep(
        title: "Monitor in Real-Time",
        description: "Watch temperature and humidity readings update every few seconds. Green indicates good conditions.",
        iconPath: "assets/images/monitor.png",
        actionText: "View Monitor",
      ),
      GuideStep(
        title: "Capture Copra Image",
        description: "When drying is complete, use the Scanner to capture your copra image for quality assessment.",
        iconPath: "assets/images/camera.png",
        actionText: "Open Scanner",
      ),
      GuideStep(
        title: "Get Quality Results",
        description: "The AI will analyze your copra and classify it as Under-dried, Optimally-dried, or Over-dried.",
        iconPath: "assets/images/results.png",
      ),
      GuideStep(
        title: "View Analytics & History",
        description: "Check your drying history and get insights on optimal conditions for the best copra quality.",
        iconPath: "assets/images/analytics.png",
        actionText: "View Analytics",
      ),
    ];
  }
}