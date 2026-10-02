import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/guide_step.dart';
import '../theme/app_theme.dart';
import '../constants/app_constants.dart';
import '../routes/app_router.dart';

class UserGuideCarousel extends StatefulWidget {
  final VoidCallback? onComplete;
  final VoidCallback? onSkip;

  const UserGuideCarousel({
    Key? key,
    this.onComplete,
    this.onSkip,
  }) : super(key: key);

  @override
  State<UserGuideCarousel> createState() => _UserGuideCarouselState();
}

class _UserGuideCarouselState extends State<UserGuideCarousel> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  late List<GuideStep> _steps;

  @override
  void initState() {
    super.initState();
    _steps = _getGuideStepsWithActions();
  }

  List<GuideStep> _getGuideStepsWithActions() {
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
        action: () => _navigateToSettings(),
      ),
      GuideStep(
        title: "Configure RPi IP Address",
        description: "Enter your Raspberry Pi IP address in Settings. Default is usually 192.168.1.100",
        iconPath: "assets/images/settings.png",
        actionText: "Go to Settings",
        action: () => _navigateToSettings(),
      ),
      GuideStep(
        title: "Start a New Batch",
        description: "Tap 'New Batch' to begin monitoring your copra drying process. Give it a descriptive name.",
        iconPath: "assets/images/batch.png",
        actionText: "Create Batch",
        action: () => _navigateToBatches(),
      ),
      GuideStep(
        title: "Monitor in Real-Time",
        description: "Watch temperature and humidity readings update every few seconds. Green indicates good conditions.",
        iconPath: "assets/images/monitor.png",
        actionText: "View Monitor",
        action: () => _navigateToMonitor(),
      ),
      GuideStep(
        title: "Capture Copra Image",
        description: "When drying is complete, use the Scanner to capture your copra image for quality assessment.",
        iconPath: "assets/images/camera.png",
        actionText: "Open Scanner",
        action: () => _navigateToScanner(),
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
        action: () => _navigateToAnalytics(),
      ),
    ];
  }

  // Navigation methods
  void _navigateToSettings() {
    Navigator.of(context).pop(); // Close guide
    context.go('/settings');
  }

  void _navigateToBatches() {
    Navigator.of(context).pop(); // Close guide  
    context.go('/batches');
  }

  void _navigateToMonitor() {
    Navigator.of(context).pop(); // Close guide
    context.go('/monitor');
  }

  void _navigateToScanner() {
    Navigator.of(context).pop(); // Close guide
    context.go('/scanner');
  }

  void _navigateToAnalytics() {
    Navigator.of(context).pop(); // Close guide
    context.go('/analytics');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentIndex < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Completed all steps
      widget.onComplete?.call();
    }
  }

  void _previousStep() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header with progress and skip
            Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Guide ${_currentIndex + 1}/${_steps.length}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onSkip,
                    child: Text(
                      'Skip',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
              child: LinearProgressIndicator(
                value: (_currentIndex + 1) / _steps.length,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
              ),
            ),

            // Guide content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemCount: _steps.length,
                itemBuilder: (context, index) {
                  return _buildGuideStep(_steps[index]);
                },
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Row(
                children: [
                  // Previous button
                  if (_currentIndex > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousStep,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: AppTheme.primaryGreen),
                        ),
                        child: Text(
                          'Previous',
                          style: TextStyle(color: AppTheme.primaryGreen),
                        ),
                      ),
                    ),

                  if (_currentIndex > 0) const SizedBox(width: 16),

                  // Next/Complete button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        _currentIndex == _steps.length - 1 ? 'Get Started!' : 'Next',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideStep(GuideStep step) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon/Image
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              _getIconForStep(_currentIndex),
              size: 60,
              color: AppTheme.primaryGreen,
            ),
          ),

          const SizedBox(height: 32),

          // Title
          Text(
            step.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            step.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Action button (if available)
          if (step.actionText != null)
            Container(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Show confirmation dialog before navigating
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Go to ${step.actionText}?'),
                      content: Text('This will close the guide and take you to the ${step.actionText?.toLowerCase()} page.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context); // Close dialog
                            step.action?.call(); // Navigate
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                          ),
                          child: Text(
                            'Go Now',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                icon: Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 20,
                ),
                label: Text(
                  step.actionText!,
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getIconForStep(int index) {
    switch (index) {
      case 0:
        return Icons.waving_hand;
      case 1:
        return Icons.wifi;
      case 2:
        return Icons.settings;
      case 3:
        return Icons.add_box;
      case 4:
        return Icons.monitor_heart;
      case 5:
        return Icons.camera_alt;
      case 6:
        return Icons.analytics;
      case 7:
        return Icons.insights;
      default:
        return Icons.help_outline;
    }
  }
}

// Guide Launcher Dialog
class GuideDialog extends StatelessWidget {
  const GuideDialog({Key? key}) : super(key: key);

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const GuideDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.help_outline,
              size: 48,
              color: AppTheme.primaryGreen,
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Need Help?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Take a quick tour to learn how to use CopraWatch effectively.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            
            const SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Not Now',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => UserGuideCarousel(
                            onComplete: () => Navigator.of(context).pop(),
                            onSkip: () => Navigator.of(context).pop(),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                    ),
                    child: const Text(
                      'Start Tour',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}