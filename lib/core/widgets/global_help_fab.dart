import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'user_guide_carousel.dart';

class GlobalHelpFab extends StatelessWidget {
  final bool show;
  
  const GlobalHelpFab({
    Key? key,
    this.show = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();
    
    return Positioned(
      bottom: 80, // Above bottom navigation
      right: 16,
      child: FloatingActionButton(
        mini: true,
        backgroundColor: AppTheme.primaryGreen,
        onPressed: () => _showQuickHelp(context),
        child: const Icon(
          Icons.help_outline,
          color: Colors.white,
          size: 20,
        ),
        tooltip: 'Quick Help',
      ),
    );
  }

  void _showQuickHelp(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(height: 20),
            
            Row(
              children: [
                Icon(Icons.help_outline, color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                Text(
                  'Need Help?',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Choose what you need help with:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Quick help options
            _buildHelpOption(
              context,
              'Complete Tutorial',
              'Step-by-step guide from setup to results',
              Icons.school,
              () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => UserGuideCarousel(
                      onComplete: () => Navigator.of(context).pop(),
                      onSkip: () => Navigator.of(context).pop(),
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 12),
            
            _buildHelpOption(
              context,
              'Quick Tips',
              'Common questions and solutions',
              Icons.tips_and_updates,
              () {
                Navigator.pop(context);
                _showQuickTips(context);
              },
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpOption(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppTheme.primaryGreen, size: 20),
            ),
            
            const SizedBox(width: 12),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
          ],
        ),
      ),
    );
  }

  void _showQuickTips(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick Tips'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTip('Connection Issues', 'Check if RPi IP is correct in Settings'),
              _buildTip('Poor Image Quality', 'Ensure good lighting and clean lens'),
              _buildTip('Wrong Classification', 'Make sure copra fills the image frame'),
              _buildTip('No Sensor Data', 'Verify RPi is powered on and connected'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildTip(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(
            description,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}