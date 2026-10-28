import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CopraWatchLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;

  const CopraWatchLogo({
    Key? key,
    this.size = 56,
    this.showWordmark = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.22),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.28),
        child: Image.asset(
          'assets/images/72cd4c3f-67fd-453e-83df-234e23e9633f.jpg',
          fit: BoxFit.cover,
        ),
      ),
    );

    if (!showWordmark) return badge;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        badge,
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'CopraWatch',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.primaryGreenDark,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            Text(
              'Smart drying monitor',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}
