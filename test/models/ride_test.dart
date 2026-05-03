import 'package:flutter_test/flutter_test.dart';
import 'package:gozolt_user_app/features/ride/data/models/ride.dart';

void main() {
  group('Ride.fromJson', () {
    test('parses complete JSON correctly', () {
      final json = {
        'id': 'ride_001',
        'status': 'COMPLETED',
        'pickupAddress': '14 Republic Street, Valletta',
        'pickupLat': 35.8989,
        'pickupLng': 14.5146,
        'dropoffAddress': 'Malta International Airport',
        'dropoffLat': 35.8575,
        'dropoffLng': 14.4775,
        'vehicleType': 'STANDARD',
        'paymentMethod': 'CARD',
        'estimatedFare': 19.80,
        'actualFare': 18.50,
        'isScheduled': false,
        'driverId': 'driver_001',
        'createdAt': '2026-03-21T10:00:00Z',
        'baseFare': 3.50,
        'distanceFare': 8.00,
        'timeFare': 4.00,
        'bookingFee': 1.50,
        'surgeMultiplier': 1.2,
        'distanceKm': 12.5,
        'durationMinutes': 25,
        'stops': [],
      };

      final ride = Ride.fromJson(json);

      expect(ride.id, 'ride_001');
      expect(ride.status, 'COMPLETED');
      expect(ride.pickupAddress, '14 Republic Street, Valletta');
      expect(ride.pickupLat, 35.8989);
      expect(ride.dropoffAddress, 'Malta International Airport');
      expect(ride.vehicleType, 'STANDARD');
      expect(ride.paymentMethod, 'CARD');
      expect(ride.estimatedFare, 19.80);
      expect(ride.actualFare, 18.50);
      expect(ride.surgeMultiplier, 1.2);
      expect(ride.distanceKm, 12.5);
      expect(ride.durationMinutes, 25);
      expect(ride.stops, isEmpty);
    });

    test('parses minimal JSON with defaults', () {
      final json = {
        'id': 'ride_002',
        'status': 'REQUESTED',
      };

      final ride = Ride.fromJson(json);

      expect(ride.id, 'ride_002');
      expect(ride.status, 'REQUESTED');
      expect(ride.pickupAddress, '');
      expect(ride.pickupLat, 0);
      expect(ride.vehicleType, 'STANDARD');
      expect(ride.surgeMultiplier, 1.0);
      expect(ride.isScheduled, false);
      expect(ride.stops, isEmpty);
      expect(ride.estimatedFare, isNull);
      expect(ride.actualFare, isNull);
    });

    test('handles string numeric values', () {
      final json = {
        'id': 'ride_003',
        'status': 'COMPLETED',
        'pickupLat': '35.8989',
        'pickupLng': '14.5146',
        'dropoffLat': '35.8575',
        'dropoffLng': '14.4775',
        'estimatedFare': '19.80',
        'surgeMultiplier': '1.5',
        'createdAt': '2026-03-21T10:00:00Z',
      };

      final ride = Ride.fromJson(json);

      expect(ride.pickupLat, 35.8989);
      expect(ride.pickupLng, 14.5146);
      expect(ride.estimatedFare, 19.80);
      expect(ride.surgeMultiplier, 1.5);
    });

    test('parses stops array', () {
      final json = {
        'id': 'ride_004',
        'status': 'REQUESTED',
        'createdAt': '2026-03-21T10:00:00Z',
        'stops': [
          {
            'address': 'Stop 1',
            'latitude': 35.9,
            'longitude': 14.5,
            'stopOrder': 1,
          },
          {
            'address': 'Stop 2',
            'latitude': 35.85,
            'longitude': 14.45,
            'stopOrder': 2,
          },
        ],
      };

      final ride = Ride.fromJson(json);

      expect(ride.stops.length, 2);
      expect(ride.stops[0].address, 'Stop 1');
      expect(ride.stops[0].stopOrder, 1);
      expect(ride.stops[1].address, 'Stop 2');
    });
  });

  group('Ride.copyWith', () {
    test('updates specified fields and preserves others', () {
      const ride = Ride(
        id: 'ride_001',
        status: 'REQUESTED',
        pickupAddress: 'A',
        pickupLat: 35.0,
        pickupLng: 14.0,
        dropoffAddress: 'B',
        dropoffLat: 36.0,
        dropoffLng: 15.0,
        vehicleType: 'STANDARD',
        createdAt: '2026-03-21T10:00:00Z',
        estimatedFare: 20.0,
      );

      final updated = ride.copyWith(
        status: 'COMPLETED',
        actualFare: 18.50,
      );

      expect(updated.id, 'ride_001');
      expect(updated.status, 'COMPLETED');
      expect(updated.estimatedFare, 20.0);
      expect(updated.actualFare, 18.50);
      expect(updated.pickupAddress, 'A');
    });
  });
}
