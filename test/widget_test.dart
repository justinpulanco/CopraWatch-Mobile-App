import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:copra_watch/main.dart';

void main() {
  testWidgets('App initializes', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(child: CopraWatchApp()),
    );
    
    await tester.pumpAndSettle();
    
    // Basic smoke test - just verify the app starts
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
