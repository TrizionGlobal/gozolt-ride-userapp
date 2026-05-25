import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/dio_provider.dart';
import '../../../../core/constants/api_constants.dart';
import '../../data/datasources/ride_remote_datasource.dart';
import '../../data/models/create_ride_request.dart';
import '../../data/models/fare_estimate.dart';
import '../../data/models/location_data.dart';
import '../../data/models/ride_stop.dart';
import '../../data/models/saved_payment_method.dart';
import '../../data/models/vehicle_type.dart';
import 'ride_booking_state.dart';
import '../../../../core/network/socket_service.dart';

// Datasource provider defined here to avoid circular imports.
final rideRemoteDatasourceProvider = Provider<RideRemoteDatasource>((ref) {
  return RideRemoteDatasource(ref.read(dioProvider));
});

class RideBookingNotifier extends StateNotifier<RideBookingState> {
  final Ref _ref;
  StreamSubscription? _progressSub;
  StreamSubscription? _noDriverSub;
  bool _isListening = false;

  RideBookingNotifier(this._ref) : super(const RideBookingState()) {
    _ref.onDispose(() {
      _progressSub?.cancel();
      _noDriverSub?.cancel();
    });
  }

  void _startListening() {
    if (_isListening) return;
    _isListening = true;

    final socket = _ref.read(socketServiceProvider);
    if (state.createdRideId != null) {
      socket.joinRide(state.createdRideId!);
    }

    _progressSub = socket.onRideMatchingProgress.listen((data) {
      if (data['message'] != null) {
        state = state.copyWith(searchingMessage: data['message'] as String);
      }
    });

    _noDriverSub = socket.onRideStatusUpdate.listen((data) {
       if (data['status'] == 'NO_DRIVER') {
         state = state.copyWith(status: BookingStatus.error, errorMessage: 'No nearby riders available');
       }
    });
  }

  void setPickup(LocationData location) {
    state = state.copyWith(pickup: location, clearError: true);
  }

  void setDropoff(LocationData location) {
    state = state.copyWith(dropoff: location, clearError: true);
  }

  void addStop(LocationData location) {
    if (state.stops.length >= 3) return;
    state = state.copyWith(stops: [...state.stops, location]);
  }

  void removeStop(int index) {
    final newStops = List<LocationData>.from(state.stops)..removeAt(index);
    state = state.copyWith(stops: newStops);
  }

  void reorderStops(int oldIndex, int newIndex) {
    final newStops = List<LocationData>.from(state.stops);
    final item = newStops.removeAt(oldIndex);
    newStops.insert(newIndex.clamp(0, newStops.length), item);
    state = state.copyWith(stops: newStops);
  }

  void setVehicleType(VehicleType type) {
    state = state.copyWith(vehicleType: type, fareEstimate: null);
    fetchFareEstimate();
  }

  void setPaymentMethod(PaymentMethodType type, {String? cardId}) {
    state = state.copyWith(
      paymentMethodType: type,
      selectedCardId: cardId,
      clearCard: type == PaymentMethodType.cash,
    );
  }

  void setPromo(String code, double discount, String description) {
    state = state.copyWith(
      promoCode: code,
      promoDiscount: discount,
      promoDescription: description,
    );
  }

  void clearPromo() {
    state = state.copyWith(clearPromo: true);
  }

  void toggleUseCoins(bool value, {double? discount}) {
    state = state.copyWith(useCoins: value, coinsDiscount: discount);
  }

  void setScheduled(bool isScheduled, {DateTime? scheduledAt}) {
    if (isScheduled) {
      state = state.copyWith(isScheduled: true, scheduledAt: scheduledAt);
    } else {
      state = state.copyWith(clearSchedule: true);
    }
  }

  Future<void> fetchFareEstimate() async {
    if (state.pickup == null || state.dropoff == null) return;

    state = state.copyWith(status: BookingStatus.estimating, clearError: true);

    try {
      if (AppConstants.kDevBypass) {
        await Future.delayed(const Duration(milliseconds: 800));
        final mockEstimate = _mockFareEstimate(state.vehicleType);
        state = state.copyWith(
          fareEstimate: mockEstimate,
          status: BookingStatus.estimated,
        );
        return;
      }

      final ds = _ref.read(rideRemoteDatasourceProvider);
      final stops = state.stops
          .map((s) => {'latitude': s.latitude, 'longitude': s.longitude})
          .toList();

      final estimate = await ds.estimateFare(
        pickupLat: state.pickup!.latitude,
        pickupLng: state.pickup!.longitude,
        dropoffLat: state.dropoff!.latitude,
        dropoffLng: state.dropoff!.longitude,
        vehicleType: state.vehicleType.apiValue,
        stops: stops.isEmpty ? null : stops,
      );

      state = state.copyWith(
        fareEstimate: estimate,
        status: BookingStatus.estimated,
      );
    } catch (e, stack) {
      print('Error in fetchFareEstimate: $e');
      print(stack);
      state = state.copyWith(
        status: BookingStatus.error,
        errorMessage: 'Failed to estimate fare: $e',
      );
    }
  }

  Future<void> confirmBooking() async {
    if (state.pickup == null || state.dropoff == null) return;

    // Distance validation — max 100km between pickup and dropoff
    final distanceMeters = Geolocator.distanceBetween(
      state.pickup!.latitude,
      state.pickup!.longitude,
      state.dropoff!.latitude,
      state.dropoff!.longitude,
    );
    if (distanceMeters > 100000) {
      state = state.copyWith(
        status: BookingStatus.error,
        errorMessage:
            'Distance exceeds 100 km (${(distanceMeters / 1000).toStringAsFixed(1)} km). Please choose a closer destination.',
      );
      return;
    }

    state = state.copyWith(status: BookingStatus.booking, clearError: true);

    try {
      final request = CreateRideRequest(
        pickupAddress: state.pickup!.address,
        pickupLat: state.pickup!.latitude,
        pickupLng: state.pickup!.longitude,
        dropoffAddress: state.dropoff!.address,
        dropoffLat: state.dropoff!.latitude,
        dropoffLng: state.dropoff!.longitude,
        vehicleType: state.vehicleType.apiValue,
        paymentMethod: state.paymentMethodType.name.toUpperCase(),
        paymentMethodId: state.paymentMethodType == PaymentMethodType.card ? state.selectedCardId : null,
        stops: state.stops.isNotEmpty
            ? state.stops
                .asMap()
                .entries
                .map((e) => RideStop(
                      address: e.value.address,
                      latitude: e.value.latitude,
                      longitude: e.value.longitude,
                      stopOrder: e.key + 1,
                    ))
                .toList()
            : null,
        isScheduled: state.isScheduled,
        scheduledAt: state.scheduledAt?.toUtc().toIso8601String(),
        promoCode: state.promoCode,
      );

      if (AppConstants.kDevBypass) {
        await Future.delayed(const Duration(seconds: 1));
        if (state.isScheduled) {
          state = state.copyWith(
            status: BookingStatus.scheduled,
            createdRideId: 'dev-ride-${DateTime.now().millisecondsSinceEpoch}',
          );
        } else {
          state = state.copyWith(
            status: BookingStatus.findingDriver,
            createdRideId: 'dev-ride-${DateTime.now().millisecondsSinceEpoch}',
          );
        }
        return;
      }

      // Use raw dio.post to capture OTP from response
      final dio = _ref.read(dioProvider);
      final response = await dio.post(ApiConstants.rides, data: request.toJson());
      final responseData = response.data as Map<String, dynamic>;
      final rideId = responseData['id'] as String;
      final otp = responseData['otp'] as String?;

      _startListening();

      if (state.isScheduled) {
        state = state.copyWith(
          status: BookingStatus.scheduled,
          createdRideId: rideId,
          createdRideOtp: otp,
        );
      } else {
        state = state.copyWith(
          status: BookingStatus.findingDriver,
          createdRideId: rideId,
          createdRideOtp: otp,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: BookingStatus.error,
        errorMessage: 'Failed to create ride. Please try again.',
      );
    }
  }

  Future<void> cancelFindingDriver() async {
    if (state.createdRideId == null) return;

    try {
      if (!AppConstants.kDevBypass) {
        final ds = _ref.read(rideRemoteDatasourceProvider);
        await ds.cancelRide(
          state.createdRideId!,
          'Cancelled before driver assigned',
        );
      }
    } catch (_) {
      // Ignore cancel errors
    }

    state = state.copyWith(
      status: BookingStatus.estimated,
      clearRideId: true,
    );
  }

  void reset() {
    state = const RideBookingState().copyWith(clearRideId: true);
  }

  FareEstimate _mockFareEstimate(VehicleType type) {
    final basePrices = {
      VehicleType.economy: 6.50,
      VehicleType.standard: 8.50,
      VehicleType.premium: 14.00,
      VehicleType.xl: 15.00,
      VehicleType.electric: 10.00,
    };
    final base = basePrices[type] ?? 8.50;
    return FareEstimate(
      baseFare: base,
      distanceFare: 4.50,
      timeFare: 2.00,
      bookingFee: 1.50,
      surgeMultiplier: 1.2,
      estimatedFare: (base + 4.50 + 2.00 + 1.50) * 1.2,
      distanceKm: 8.4,
      durationMinutes: 18,
      etaMinutes: 3,
    );
  }
}
