import 'package:flutter_test/flutter_test.dart';
import 'package:gozolt_user_app/features/ride/data/models/create_ride_request.dart';

void main() {
  group('CreateRideRequest.toJson', () {
    test('includes all required fields', () {
      const request = CreateRideRequest(
        pickupAddress: '14 Republic Street',
        pickupLat: 35.8989,
        pickupLng: 14.5146,
        dropoffAddress: 'Malta Airport',
        dropoffLat: 35.8575,
        dropoffLng: 14.4775,
        vehicleType: 'STANDARD',
      );

      final json = request.toJson();

      expect(json['pickupAddress'], '14 Republic Street');
      expect(json['pickupLat'], 35.8989);
      expect(json['pickupLng'], 14.5146);
      expect(json['dropoffAddress'], 'Malta Airport');
      expect(json['dropoffLat'], 35.8575);
      expect(json['dropoffLng'], 14.4775);
      expect(json['vehicleType'], 'STANDARD');
    });

    test('includes paymentMethodId when set', () {
      const request = CreateRideRequest(
        pickupAddress: 'A',
        pickupLat: 0,
        pickupLng: 0,
        dropoffAddress: 'B',
        dropoffLat: 1,
        dropoffLng: 1,
        vehicleType: 'STANDARD',
        paymentMethod: 'CARD',
        paymentMethodId: 'pm_abc123',
      );

      final json = request.toJson();

      expect(json['paymentMethod'], 'CARD');
      expect(json['paymentMethodId'], 'pm_abc123');
    });

    test('omits paymentMethodId when null', () {
      const request = CreateRideRequest(
        pickupAddress: 'A',
        pickupLat: 0,
        pickupLng: 0,
        dropoffAddress: 'B',
        dropoffLat: 1,
        dropoffLng: 1,
        vehicleType: 'STANDARD',
        paymentMethod: 'CASH',
      );

      final json = request.toJson();

      expect(json.containsKey('paymentMethodId'), false);
    });

    test('includes isScheduled and scheduledAt when scheduled', () {
      const request = CreateRideRequest(
        pickupAddress: 'A',
        pickupLat: 0,
        pickupLng: 0,
        dropoffAddress: 'B',
        dropoffLat: 1,
        dropoffLng: 1,
        vehicleType: 'STANDARD',
        isScheduled: true,
        scheduledAt: '2026-03-22T10:00:00Z',
      );

      final json = request.toJson();

      expect(json['isScheduled'], true);
      expect(json['scheduledAt'], '2026-03-22T10:00:00Z');
    });

    test('omits isScheduled when false', () {
      const request = CreateRideRequest(
        pickupAddress: 'A',
        pickupLat: 0,
        pickupLng: 0,
        dropoffAddress: 'B',
        dropoffLat: 1,
        dropoffLng: 1,
        vehicleType: 'STANDARD',
      );

      final json = request.toJson();

      expect(json.containsKey('isScheduled'), false);
    });

    test('includes promoCode when set', () {
      const request = CreateRideRequest(
        pickupAddress: 'A',
        pickupLat: 0,
        pickupLng: 0,
        dropoffAddress: 'B',
        dropoffLat: 1,
        dropoffLng: 1,
        vehicleType: 'STANDARD',
        promoCode: 'WELCOME10',
      );

      final json = request.toJson();

      expect(json['promoCode'], 'WELCOME10');
    });
  });
}
