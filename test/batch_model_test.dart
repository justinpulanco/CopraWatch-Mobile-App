import 'package:flutter_test/flutter_test.dart';
import 'package:copra_watch/models/batch_model.dart';

void main() {
  test('creates an active batch with expected defaults', () {
    final batch = Batch(
      name: 'Test batch',
      startDate: DateTime(2026, 1, 1),
      initialMoisture: 40,
      finalMoisture: 40,
      status: 'active',
      readings: [],
    );

    expect(batch.name, 'Test batch');
    expect(batch.isActive, isTrue);
    expect(batch.moistureReduction, 0);
    expect(batch.dryingDuration.inMinutes, greaterThanOrEqualTo(0));
  });
}
