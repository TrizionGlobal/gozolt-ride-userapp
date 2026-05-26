import '../../../../core/constants/asset_paths.dart';

enum VehicleType {
  economy,
  standard,
  premium,
  xl,
  electric;

  String get displayName {
    switch (this) {
      case VehicleType.economy:
        return 'Economy';
      case VehicleType.standard:
        return 'Standard';
      case VehicleType.premium:
        return 'Premium';
      case VehicleType.xl:
        return 'XL (6+ seats)';
      case VehicleType.electric:
        return 'Electric';
    }
  }

  String get apiValue {
    switch (this) {
      case VehicleType.economy:
        return 'ECONOMY';
      case VehicleType.standard:
        return 'STANDARD';
      case VehicleType.premium:
        return 'PREMIUM';
      case VehicleType.xl:
        return 'XL';
      case VehicleType.electric:
        return 'ELECTRIC';
    }
  }

  String get iconPath {
    switch (this) {
      case VehicleType.economy:
        return AssetPaths.vehicleStandard;
      case VehicleType.standard:
        return AssetPaths.vehicleComfort;
      case VehicleType.premium:
        return AssetPaths.vehicleLuxury;
      case VehicleType.xl:
        return AssetPaths.vehicleXl;
      case VehicleType.electric:
        return AssetPaths.vehicleAccessible;
    }
  }

  int get maxPassengers {
    switch (this) {
      case VehicleType.economy:
        return 4;
      case VehicleType.standard:
        return 4;
      case VehicleType.premium:
        return 4;
      case VehicleType.xl:
        return 6;
      case VehicleType.electric:
        return 4;
    }
  }

  /// Total seats including the driver seat.
  int get totalSeats => maxPassengers + 1;

  static VehicleType fromApi(String value) {
    switch (value.toUpperCase()) {
      case 'ECONOMY':
        return VehicleType.economy;
      case 'STANDARD':
        return VehicleType.standard;
      case 'PREMIUM':
        return VehicleType.premium;
      case 'XL':
        return VehicleType.xl;
      case 'ELECTRIC':
        return VehicleType.electric;
      default:
        return VehicleType.standard;
    }
  }
}
