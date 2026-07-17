import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/providers/dio_provider.dart';
import '../../data/models/ride.dart';
import '../../data/models/driver_info.dart';

class UnratedRideState {
  final Ride ride;
  final DriverInfo? driverInfo;
  UnratedRideState(this.ride, this.driverInfo);
}

final unratedRideProvider = StateNotifierProvider<UnratedRideNotifier, UnratedRideState?>((ref) {
  return UnratedRideNotifier(ref);
});

class UnratedRideNotifier extends StateNotifier<UnratedRideState?> {
  final Ref _ref;
  bool _isChecking = false;

  UnratedRideNotifier(this._ref) : super(null);

  Future<void> checkForUnratedRide() async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      final dio = _ref.read(dioProvider);
      final response = await dio.get('/rides/unrated');
      
      // If response is null or empty string, there's no unrated ride
      if (response.data == null || response.data == '') {
        state = null;
        return;
      }

      final json = response.data as Map<String, dynamic>;
      final ride = Ride.fromJson(json);

      DriverInfo? driverInfo;
      final d = json['driver'] as Map<String, dynamic>?;
      if (d != null) {
        final name = '${d['firstName'] ?? ''} ${d['lastName'] ?? ''}'.trim();
        driverInfo = DriverInfo(
          id: d['driverId'] as String? ?? d['id'] as String? ?? '',
          name: name.isNotEmpty ? name : 'Driver',
          phone: d['phone'] as String? ?? '',
          rating: (d['avgRating'] as num?)?.toDouble() ?? 5.0,
          totalRides: (d['totalRides'] as num?)?.toInt() ?? 0,
          avatarUrl: d['profilePicture'] as String?,
          vehicleMake: '', vehicleModel: '', vehicleColor: '', plateNumber: '', vehicleType: 'Car Go',
        );
      }

      // Check if user has already dismissed this specific ride
      final prefs = await SharedPreferences.getInstance();
      final dismissedList = prefs.getStringList('dismissed_unrated_rides') ?? [];
      
      if (!dismissedList.contains(ride.id)) {
        state = UnratedRideState(ride, driverInfo);
      } else {
        state = null;
      }
    } catch (e) {
      if (kDebugMode) print('[UnratedRide] Error fetching unrated ride: $e');
      state = null;
    } finally {
      _isChecking = false;
    }
  }

  Future<void> dismissUnratedRide(String rideId) async {
    final prefs = await SharedPreferences.getInstance();
    final dismissedList = prefs.getStringList('dismissed_unrated_rides') ?? [];
    if (!dismissedList.contains(rideId)) {
      dismissedList.add(rideId);
      if (dismissedList.length > 20) {
        dismissedList.removeAt(0);
      }
      await prefs.setStringList('dismissed_unrated_rides', dismissedList);
    }
    
    if (state?.ride.id == rideId) {
      state = null;
    }
  }
}
