import '../../../../core/constants/asset_paths.dart';

enum VehicleType {
  go,
  standard,
  comfort,
  green,
  prime,
  premiumXl,
  van,
  chauffeur;

  String get displayName {
    switch (this) {
      case VehicleType.go:
        return 'Go';
      case VehicleType.standard:
        return 'Standard';
      case VehicleType.comfort:
        return 'Comfort';
      case VehicleType.green:
        return 'Green';
      case VehicleType.prime:
        return 'Prime';
      case VehicleType.premiumXl:
        return 'Premium/XL';
      case VehicleType.van:
        return 'Van';
      case VehicleType.chauffeur:
        return 'Chauffeur';
    }
  }

  String get apiValue {
    switch (this) {
      case VehicleType.go:
        return 'GO';
      case VehicleType.standard:
        return 'STANDARD';
      case VehicleType.comfort:
        return 'COMFORT';
      case VehicleType.green:
        return 'GREEN';
      case VehicleType.prime:
        return 'PRIME';
      case VehicleType.premiumXl:
        return 'PREMIUM_XL';
      case VehicleType.van:
        return 'VAN';
      case VehicleType.chauffeur:
        return 'CHAUFFEUR';
    }
  }

  String get iconPath {
    switch (this) {
      case VehicleType.go:
        return AssetPaths.vehicleStandard;
      case VehicleType.standard:
        return AssetPaths.vehicleStandard;
      case VehicleType.comfort:
        return AssetPaths.vehicleComfort;
      case VehicleType.green:
        return AssetPaths.vehicleAccessible;
      case VehicleType.prime:
        return AssetPaths.vehicleLuxury;
      case VehicleType.premiumXl:
        return AssetPaths.vehicleXl;
      case VehicleType.van:
        return AssetPaths.vehicleXl;
      case VehicleType.chauffeur:
        return AssetPaths.vehicleLuxury;
    }
  }

  int get maxPassengers {
    switch (this) {
      case VehicleType.go:
        return 4;
      case VehicleType.standard:
        return 4;
      case VehicleType.comfort:
        return 4;
      case VehicleType.green:
        return 4;
      case VehicleType.prime:
        return 4;
      case VehicleType.premiumXl:
        return 6;
      case VehicleType.van:
        return 8;
      case VehicleType.chauffeur:
        return 6;
    }
  }

  /// Total seats including the driver seat.
  int get totalSeats => maxPassengers + 1;

  static VehicleType fromApi(String value) {
    switch (value.toUpperCase()) {
      case 'GO':
        return VehicleType.go;
      case 'STANDARD':
        return VehicleType.standard;
      case 'COMFORT':
        return VehicleType.comfort;
      case 'GREEN':
        return VehicleType.green;
      case 'PRIME':
        return VehicleType.prime;
      case 'PREMIUM_XL':
      case 'PREMIUM/XL':
      case 'XL':
        return VehicleType.premiumXl;
      case 'VAN':
        return VehicleType.van;
      case 'CHAUFFEUR':
        return VehicleType.chauffeur;
      default:
        return VehicleType.go;
    }
  }
}
