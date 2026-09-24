import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

Future<void> showUserGuide(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('How to Use CopraWatch'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _GuideStep('1', 'Connect to the Raspberry Pi in Settings.'),
            _GuideStep('2', 'Create a batch, such as Batch 001.'),
            _GuideStep('3', 'Open RPI Camera for the live preview.'),
            _GuideStep('4', 'Adjust the copra position, angle, and lighting.'),
            _GuideStep('5', 'Tap CAPTURE to save one photo.'),
            _GuideStep('6', 'Review the result: Basa-basa, Tuyo, or Sunog.'),
            _GuideStep('7', 'Tap Save Result to attach it to the active batch.'),
            _GuideStep('8', 'Export the report to the phone or Raspberry Pi.'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Got it'),
        ),
      ],
    ),
  );
}

class _GuideStep extends StatelessWidget {
  final String number;
  final String text;

  const _GuideStep(this.number, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: AppTheme.primaryGreen,
            child: Text(number, style: const TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
