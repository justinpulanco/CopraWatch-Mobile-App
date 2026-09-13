import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../../models/batch_model.dart';
import '../../../services/raspberry_pi_service.dart';

final sensorDataProvider =
    StateNotifierProvider<SensorNotifier, SensorReadingList>((ref) {
  return SensorNotifier();
});

class SensorReadingList {
  final List<SensorReading> readings;
  final SensorReading? latest;
  final bool isConnected;

  SensorReadingList({
    required this.readings,
    this.latest,
    this.isConnected = false,
  });

  SensorReadingList copyWith({
    List<SensorReading>? readings,
    SensorReading? latest,
    bool? isConnected,
  }) {
    return SensorReadingList(
      readings: readings ?? this.readings,
      latest: latest ?? this.latest,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}

class SensorNotifier extends StateNotifier<SensorReadingList> {
  Timer? _timer;
  final RaspberryPiService _rpiService = RaspberryPiService();

  SensorNotifier()
      : super(SensorReadingList(
          readings: [],
          latest: null,
          isConnected: false,
        )) {
    _startAutoUpdate();
  }

  void _startAutoUpdate() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      _fetchRealData();
    });
  }

  Future<void> _fetchRealData() async {
    try {
      final envData = await _rpiService.getSensorData();

      if (envData != null) {
        final newReading = SensorReading(
          timestamp: envData.timestamp,
          temperature: envData.temperature,
          humidity: envData.humidity,
          moisture: envData.moisture,
          solarIrradiance: envData.solarIrradiance,
        );

        final readings = [...state.readings, newReading];
        if (readings.length > 50) {
          readings.removeAt(0);
        }

        state = state.copyWith(
          readings: readings,
          latest: newReading,
          isConnected: true,
        );
      } else {
        // If data is null, the connection is lost
        state = state.copyWith(isConnected: false);
      }
    } catch (e) {
      state = state.copyWith(isConnected: false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
