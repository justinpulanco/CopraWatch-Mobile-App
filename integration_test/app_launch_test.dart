import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:copra_watch/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('launches the CopraWatch app', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: CopraWatchApp()));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(CopraWatchApp), findsOneWidget);
    expect(find.byType(ProviderScope), findsOneWidget);
  });
}