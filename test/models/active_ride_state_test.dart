import 'package:flutter_test/flutter_test.dart';
import 'package:gozolt_user_app/features/ride/data/models/driver_info.dart';
import 'package:gozolt_user_app/features/ride/presentation/providers/active_ride_state.dart';

void main() {
  group('ActiveRideState defaults', () {
    test('default constructor has correct initial values', () {
      const state = ActiveRideState();

      expect(state.ride, isNull);
      expect(state.driverInfo, isNull);
      expect(state.driverLocation, isNull);
      expect(state.status, ActiveRideStatus.driverEnRoute);
      expect(state.isLoading, false);
      expect(state.isDestinationChangePending, false);
    });
  });

  group('ActiveRideState computed properties', () {
    test('hasDriver returns false when driverInfo is null', () {
      const state = ActiveRideState();
      expect(state.hasDriver, false);
    });

    test('hasDriver returns true when driverInfo is set', () {
      const state = ActiveRideState(
        driverInfo: DriverInfo(
          id: 'd1',
          name: 'Test',
          phone: '+356',
          rating: 4.5,
          vehicleMake: 'Toyota',
          vehicleModel: 'Camry',
          vehicleColor: 'White',
          plateNumber: 'ABC 123',
          vehicleType: 'Standard',
        ),
      );
      expect(state.hasDriver, true);
    });

    test('isCompleted returns true only for completed status', () {
      const completed = ActiveRideState(status: ActiveRideStatus.completed);
      const inProgress = ActiveRideState(status: ActiveRideStatus.inProgress);

      expect(completed.isCompleted, true);
      expect(inProgress.isCompleted, false);
    });

    test('isCancelled returns true only for cancelled status', () {
      const cancelled = ActiveRideState(status: ActiveRideStatus.cancelled);
      const enRoute = ActiveRideState(status: ActiveRideStatus.driverEnRoute);

      expect(cancelled.isCancelled, true);
      expect(enRoute.isCancelled, false);
    });
  });

  group('ActiveRideState copyWith', () {
    test('preserves unset fields', () {
      const state = ActiveRideState(
        status: ActiveRideStatus.inProgress,
        etaMinutes: 5,
        otpPin: '1234',
      );

      final updated = state.copyWith(etaMinutes: 3);

      expect(updated.status, ActiveRideStatus.inProgress);
      expect(updated.etaMinutes, 3);
      expect(updated.otpPin, '1234');
    });

    test('clearError sets errorMessage to null', () {
      const state = ActiveRideState(errorMessage: 'Something failed');

      final updated = state.copyWith(clearError: true);

      expect(updated.errorMessage, isNull);
    });

    test('clearError does not affect errorMessage when false', () {
      const state = ActiveRideState(errorMessage: 'Something failed');

      final updated = state.copyWith(clearError: false);

      expect(updated.errorMessage, 'Something failed');
    });

    test('clearPendingDestination clears all destination fields', () {
      const state = ActiveRideState(
        isDestinationChangePending: true,
        pendingNewDropoffAddress: 'New Place',
        pendingNewDropoffLat: 35.9,
        pendingNewDropoffLng: 14.5,
        pendingNewFare: 25.0,
      );

      final updated = state.copyWith(clearPendingDestination: true);

      expect(updated.isDestinationChangePending, false);
      expect(updated.pendingNewDropoffAddress, isNull);
      expect(updated.pendingNewDropoffLat, isNull);
      expect(updated.pendingNewDropoffLng, isNull);
      expect(updated.pendingNewFare, isNull);
    });

    test('clearOtp sets otpPin to null', () {
      const state = ActiveRideState(otpPin: '5678');

      final updated = state.copyWith(clearOtp: true);

      expect(updated.otpPin, isNull);
    });
  });
}
