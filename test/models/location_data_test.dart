import 'package:flutter_test/flutter_test.dart';
import 'package:gozolt_user_app/features/ride/data/models/location_data.dart';

void main() {
  group('LocationData', () {
    test('constructor sets all fields', () {
      const loc = LocationData(
        address: 'Valletta',
        latitude: 35.8989,
        longitude: 14.5146,
        subtitle: 'Capital City, Malta',
      );

      expect(loc.address, 'Valletta');
      expect(loc.latitude, 35.8989);
      expect(loc.longitude, 14.5146);
      expect(loc.subtitle, 'Capital City, Malta');
    });

    test('subtitle is optional', () {
      const loc = LocationData(
        address: 'Test',
        latitude: 0,
        longitude: 0,
      );

      expect(loc.subtitle, isNull);
    });
  });

  group('LocationData.toJson', () {
    test('serializes required fields', () {
      const loc = LocationData(
        address: 'Mdina Gate',
        latitude: 35.8858,
        longitude: 14.4024,
        subtitle: 'Mdina, Malta',
      );

      final json = loc.toJson();

      expect(json['address'], 'Mdina Gate');
      expect(json['latitude'], 35.8858);
      expect(json['longitude'], 14.4024);
    });
  });

  group('LocationData.fromJson', () {
    test('deserializes correctly', () {
      final json = {
        'address': 'Airport',
        'latitude': 35.8575,
        'longitude': 14.4775,
        'subtitle': 'Luqa',
      };

      final loc = LocationData.fromJson(json);

      expect(loc.address, 'Airport');
      expect(loc.latitude, 35.8575);
      expect(loc.longitude, 14.4775);
      expect(loc.subtitle, 'Luqa');
    });

    test('handles missing address with empty string default', () {
      final json = {
        'latitude': 35.0,
        'longitude': 14.0,
      };

      final loc = LocationData.fromJson(json);

      expect(loc.address, '');
    });
  });

  group('LocationData.copyWith', () {
    test('updates specified fields', () {
      const loc = LocationData(
        address: 'A',
        latitude: 1.0,
        longitude: 2.0,
        subtitle: 'Sub',
      );

      final updated = loc.copyWith(address: 'B', latitude: 3.0);

      expect(updated.address, 'B');
      expect(updated.latitude, 3.0);
      expect(updated.longitude, 2.0);
      expect(updated.subtitle, 'Sub');
    });
  });
}
