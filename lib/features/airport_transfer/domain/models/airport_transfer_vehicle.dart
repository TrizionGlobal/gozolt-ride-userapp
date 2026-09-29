import '../../../../core/constants/api_constants.dart';

class AirportTransferVehicle {
  const AirportTransferVehicle({
    required this.id,
    required this.name,
    required this.type,
    required this.supplierName,
    required this.supplierRating,
    required this.passengerCapacity,
    required this.luggageCapacity,
    required this.fixedPrice,
    required this.currency,
    required this.imageUrl,
    required this.estimatedDurationMinutes,
    this.features = const [],
    this.isRecommended = false,
    this.isBestValue = false,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String type;

  final String supplierName;
  final double supplierRating;

  final int passengerCapacity;
  final int luggageCapacity;

  final double fixedPrice;
  final String currency;

  final String imageUrl;
  final int estimatedDurationMinutes;

  final List<String> features;

  final bool isRecommended;
  final bool isBestValue;
  final bool isActive;

  String get formattedPrice {
    return '$currency${fixedPrice.toStringAsFixed(2)}';
  }

  String get passengerText {
    return '$passengerCapacity '
        '${passengerCapacity == 1 ? 'passenger' : 'passengers'}';
  }

  String get luggageText {
    return '$luggageCapacity '
        '${luggageCapacity == 1 ? 'bag' : 'bags'}';
  }

  String get estimatedDurationText {
    return 'Approx. $estimatedDurationMinutes min';
  }

  factory AirportTransferVehicle.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawImageUrl = json['imageUrl'] ?? json['image'] ?? '';

    return AirportTransferVehicle(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? json['vehicleName'] ?? '').toString(),
      type: (json['type'] ?? json['vehicleType'] ?? '').toString(),
      supplierName: (json['supplierName'] ?? json['supplier'] ?? '').toString(),
      supplierRating: _readDouble(json['supplierRating'] ?? json['rating'], 0),
      passengerCapacity: _readInt(
        json['passengerCapacity'] ?? json['seats'],
        0,
      ),
      luggageCapacity: _readInt(
        json['luggageCapacity'] ?? json['bags'],
        0,
      ),
      fixedPrice: _readDouble(
        json['fixedPrice'] ?? json['price'],
        0,
      ),
      currency: (json['currency'] ?? '€').toString(),
      imageUrl: rawImageUrl.toString().isEmpty
          ? ''
          : ApiConstants.fullUrl(rawImageUrl.toString()),
      estimatedDurationMinutes: _readInt(
        json['estimatedDurationMinutes'] ?? json['estimatedDuration'],
        0,
      ),
      features: List<String>.from(
        json['features'] ?? const <String>[],
      ),
      isRecommended: json['isRecommended'] == true,
      isBestValue: json['isBestValue'] == true,
      isActive: json['isActive'] != false,
    );
  }

  static int _readInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static double _readDouble(
    dynamic value,
    double fallback,
  ) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
