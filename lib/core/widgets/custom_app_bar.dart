import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import 'user_guide_carousel.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final PreferredSizeWidget? bottom;
  final bool showHelpButton; // Add help button option

  const CustomAppBar({
    Key? key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
    this.backgroundColor,
    this.bottom,
    this.showHelpButton = true, // Default show help
  }) : super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(
        subtitle != null ? 80 : 56 + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor ?? AppTheme.primaryGreen,
      elevation: 2,
      leading: showBackButton && (context.canPop() || onBackPressed != null)
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: onBackPressed ?? () => context.pop(),
            )
          : null,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white70,
              ),
            ),
          ]
        ],
      ),
      actions: [
        // Help button (if enabled)
        if (showHelpButton)
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () => _showHelpDialog(context),
            tooltip: 'Help & Guide',
          ),
        // Additional actions
        if (actions != null) ...actions!,
      ],
      bottom: bottom,
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.help_outline, color: AppTheme.primaryGreen),
            const SizedBox(width: 8),
            const Text('Need Help?'),
          ],
        ),
        content: const Text('Would you like to see the step-by-step guide on how to use CopraWatch?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Not Now', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => UserGuideCarousel(
                    onComplete: () => Navigator.of(context).pop(),
                    onSkip: () => Navigator.of(context).pop(),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
            child: const Text('Show Guide', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
