import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../constants/app_constants.dart';
import '../../services/page_guide_service.dart';
import '../../models/guide_step.dart';

class PageGuideDialog extends StatefulWidget {
  final String pageName;
  final String pageTitle;

  const PageGuideDialog({
    Key? key,
    required this.pageName,
    required this.pageTitle,
  }) : super(key: key);

  static Future<void> show(BuildContext context, String pageName, String pageTitle) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PageGuideDialog(
          pageName: pageName,
          pageTitle: pageTitle,
        ),
      ),
    );
  }

  @override
  State<PageGuideDialog> createState() => _PageGuideDialogState();
}

class _PageGuideDialogState extends State<PageGuideDialog> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  late List<GuideStep> _steps;

  @override
  void initState() {
    super.initState();
    _steps = PageGuideService.getGuideForPage(widget.pageName);
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
      Navigator.of(context).pop();
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
    if (_steps.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('${widget.pageTitle} Guide'),
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                size: 64,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                'No guide available yet',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Guide for ${widget.pageTitle} is coming soon!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('${widget.pageTitle} Guide'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Close',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Step ${_currentIndex + 1} of ${_steps.length}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.pageTitle,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (_currentIndex + 1) / _steps.length,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                ),
              ],
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
                        side: const BorderSide(color: AppTheme.primaryGreen),
                      ),
                      child: const Text(
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
                      _currentIndex == _steps.length - 1 ? 'Got it!' : 'Next',
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
    );
  }

  Widget _buildGuideStep(GuideStep step) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              _getIconForStep(_currentIndex),
              size: 50,
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
        ],
      ),
    );
  }

  IconData _getIconForStep(int index) {
    switch (widget.pageName) {
      case 'dashboard':
        return [Icons.dashboard, Icons.batch_prediction, Icons.touch_app, Icons.notifications][index] ?? Icons.help_outline;
      case 'monitor':
        return [Icons.sensors, Icons.wifi, Icons.thermostat, Icons.opacity][index] ?? Icons.help_outline;
      case 'scanner':
        return [Icons.smart_toy, Icons.camera_alt, Icons.camera, Icons.save][index] ?? Icons.help_outline;
      case 'batches':
        return [Icons.inventory, Icons.add, Icons.timeline, Icons.check_circle, Icons.download][index] ?? Icons.help_outline;
      case 'analytics':
        return [Icons.analytics, Icons.pie_chart, Icons.thermostat, Icons.lightbulb, Icons.trending_up][index] ?? Icons.help_outline;
      case 'settings':
        return [Icons.settings, Icons.router, Icons.warning, Icons.tune, Icons.help][index] ?? Icons.help_outline;
      default:
        return Icons.help_outline;
    }
  }
}

// Quick help button widget
class PageHelpButton extends StatelessWidget {
  final String pageName;
  final String pageTitle;

  const PageHelpButton({
    Key? key,
    required this.pageName,
    required this.pageTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: IconButton(
        onPressed: () => PageGuideDialog.show(context, pageName, pageTitle),
        icon: const Icon(Icons.help_outline_rounded),
        tooltip: '$pageTitle Help',
      ),
    );
  }
}