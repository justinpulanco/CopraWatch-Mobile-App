import 'package:flutter/material.dart';
import 'coprawatch_logo.dart';
import '../theme/app_theme.dart';

class LaunchSplash extends StatefulWidget {
  final Widget child;

  const LaunchSplash({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<LaunchSplash> createState() => _LaunchSplashState();
}

class _LaunchSplashState extends State<LaunchSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.82, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    Future<void>.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showSplash)
          Positioned.fill(
            child: Material(
              color: AppTheme.backgroundColor,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Center(
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: const CopraWatchLogo(
                      size: 128,
                      showWordmark: true,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
