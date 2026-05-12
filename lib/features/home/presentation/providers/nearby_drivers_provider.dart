import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/dio_provider.dart';
import '../../../ride/data/models/driver_location.dart';

final nearbyDriversProvider = StateNotifierProvider<NearbyDriversNotifier, List<DriverLocation>>((ref) {
  return NearbyDriversNotifier(ref);
});

class NearbyDriversNotifier extends StateNotifier<List<DriverLocation>> {
  final Ref _ref;
  Timer? _timer;

  NearbyDriversNotifier(this._ref) : super([]) {
    // Start polling when created
    startPolling(35.8922, 14.5121); // Default Malta coordinates
  }

  void startPolling(double lat, double lng) {
    _timer?.cancel();
    _fetchNearby(lat, lng);
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchNearby(lat, lng);
    });
  }

  void stopPolling() {
    _timer?.cancel();
  }

  Future<void> _fetchNearby(double lat, double lng) async {
    try {
      final dio = _ref.read(dioProvider);
      final response = await dio.get('/rides/nearby-drivers', queryParameters: {
        'lat': lat,
        'lng': lng,
        'radius': 5,
      });

      final List data = response.data;
      state = data.map((json) => DriverLocation(
        latitude: (json['lat'] as num).toDouble(),
        longitude: (json['lng'] as num).toDouble(),
        heading: (json['heading'] as num?)?.toDouble() ?? 0,
      )).toList();
    } catch (_) {
      // Ignore errors for background polling
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
