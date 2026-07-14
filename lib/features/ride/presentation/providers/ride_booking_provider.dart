import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
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
import '../../../../core/network/api_exception.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide PaymentMethodType;

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
    state = state.copyWith(vehicleType: type);
  }

  void setPaymentMethod(PaymentMethodType type, {String? cardId}) {
    state = state.copyWith(
      paymentMethodType: type,
      selectedCardId: cardId,
      clearCard: type == PaymentMethodType.cash,
    );
  }

  /// Auto-select the user's default saved card if no payment method has been
  /// chosen yet (i.e. still on the initial Cash default).
  Future<void> initDefaultPaymentMethod(
      List<SavedPaymentMethod> savedMethods) async {
    // DO NOT override. Cash should be the default payment method.
    return;
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
      final ds = _ref.read(rideRemoteDatasourceProvider);
      final stops = state.stops
          .map((s) => {'latitude': s.latitude, 'longitude': s.longitude})
          .toList();

      final estimates = await ds.estimateFare(
        pickupLat: state.pickup!.latitude,
        pickupLng: state.pickup!.longitude,
        dropoffLat: state.dropoff!.latitude,
        dropoffLng: state.dropoff!.longitude,
        stops: stops.isEmpty ? null : stops,
      );

      state = state.copyWith(
        allEstimates: estimates,
        status: BookingStatus.estimated,
      );
    } catch (e, stack) {
      print('Error in fetchFareEstimate: $e');
      print(stack);
      String msg = 'Failed to estimate fare. Please try again.';
      if (e is DioException) {
        if (e.error is ApiException) {
          msg = (e.error as ApiException).userMessage;
        } else {
          msg = ApiException.fromDioException(e).userMessage;
        }
      } else if (e is ApiException) {
        msg = e.userMessage;
      }
      state = state.copyWith(
        status: BookingStatus.error,
        errorMessage: msg,
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

      // Use raw dio.post to capture OTP from response
      final dio = _ref.read(dioProvider);
      final response = await dio.post(ApiConstants.rides, data: request.toJson());
      final responseData = response.data as Map<String, dynamic>;
      final rideId = responseData['id'] as String;
      final otp = responseData['otp'] as String?;
      final requiresAction = responseData['requiresAction'] == true;

      if (requiresAction) {
        final clientSecret = responseData['clientSecret'] as String?;
        if (clientSecret != null) {
          try {
            await Stripe.instance.handleNextAction(clientSecret);
            // 3DS successful, notify backend to start matching
            final ds = _ref.read(rideRemoteDatasourceProvider);
            await ds.confirmRidePayment(rideId);
          } on StripeException catch (e) {
            state = state.copyWith(
              status: BookingStatus.error,
              errorMessage: 'Payment authentication failed: ${e.error.localizedMessage}',
            );
            return;
          } catch (e) {
            state = state.copyWith(
              status: BookingStatus.error,
              errorMessage: 'Failed to complete payment authentication.',
            );
            return;
          }
        } else {
          state = state.copyWith(
            status: BookingStatus.error,
            errorMessage: 'Payment requires authentication but no token was provided.',
          );
          return;
        }
      }

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
      String msg = 'Failed to create ride. Please try again.';
      if (e is DioException) {
        if (e.error is ApiException) {
          msg = (e.error as ApiException).userMessage;
        } else {
          msg = ApiException.fromDioException(e).userMessage;
        }
      } else if (e is ApiException) {
        msg = e.userMessage;
      }
      state = state.copyWith(
        status: BookingStatus.error,
        errorMessage: msg,
      );
    }
  }

  void clearError() {
    if (state.status == BookingStatus.error) {
      state = state.copyWith(
        status: BookingStatus.estimated,
        clearError: true,
      );
    }
  }

  Future<void> cancelFindingDriver() async {
    if (state.createdRideId == null) return;

    try {
      final ds = _ref.read(rideRemoteDatasourceProvider);
      await ds.cancelRide(
        state.createdRideId!,
        'Cancelled before driver assigned',
      );
    } catch (_) {
      // Ignore cancel errors
    }

    state = state.copyWith(
      status: BookingStatus.estimated,
      clearRideId: true,
    );
  }

  Future<void> addExtraFare(double amount) async {
    if (state.createdRideId == null) return;
    try {
      final ds = _ref.read(rideRemoteDatasourceProvider);
      await ds.addExtraFare(state.createdRideId!, amount);
      if (state.allEstimates != null && state.fareEstimate != null) {
        final newEstimates = Map<VehicleType, FareEstimate>.from(state.allEstimates!);
        newEstimates[state.vehicleType] = state.fareEstimate!.copyWith(
          estimatedFare: state.fareEstimate!.estimatedFare + amount,
        );
        state = state.copyWith(allEstimates: newEstimates);
      }
    } catch (e) {
      print('Error adding extra fare: $e');
    }
  }

  void reset() {
    state = const RideBookingState().copyWith(clearRideId: true);
  }
}
