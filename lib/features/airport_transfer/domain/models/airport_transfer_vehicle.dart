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
    this.images = const [],
    required this.estimatedDurationMinutes,
    this.features = const [],
    this.isRecommended = false,
    this.isBestValue = false,
    this.isActive = true,
    this.make = '',
    this.model = '',
    this.registrationNo = '',
    this.year,
    this.isMeetAndGreetIncluded = true,
    this.freeWaitingMinutes = 60,
    this.status = 'AVAILABLE',
    this.pricePerKm = 2.50,
    this.minPrice = 20.00,
    this.oneWayFare,
    this.calculatedFare,
    this.distanceKm,
    this.durationMinutes,
    this.isRoundTrip = false,
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
  final List<String> images;
  final int estimatedDurationMinutes;

  final List<String> features;

  final bool isRecommended;
  final bool isBestValue;
  final bool isActive;

  final String make;
  final String model;
  final String registrationNo;
  final int? year;
  final bool isMeetAndGreetIncluded;
  final int freeWaitingMinutes;
  final String status;

  final double pricePerKm;
  final double minPrice;
  final double? oneWayFare;
  final double? calculatedFare;
  final double? distanceKm;
  final int? durationMinutes;
  final bool isRoundTrip;

  double get displayPrice => calculatedFare ?? fixedPrice;

  String get formattedPrice {
    final symbol = (currency == 'EUR' || currency.isEmpty) ? '€' : currency;
    return '$symbol${displayPrice.toStringAsFixed(2)}';
  }

  String get formattedOneWayPrice {
    final symbol = (currency == 'EUR' || currency.isEmpty) ? '€' : currency;
    final fare = oneWayFare ?? (isRoundTrip ? (displayPrice / (2 * 0.95)) : displayPrice);
    return '$symbol${fare.toStringAsFixed(2)}';
  }

  String get ratePerKmText => '€${pricePerKm.toStringAsFixed(2)}/km';

  String get minFareText => '€${minPrice.toStringAsFixed(2)} min';

  String get passengerText {
    return '$passengerCapacity '
        '${passengerCapacity == 1 ? 'passenger' : 'passengers'}';
  }

  String get luggageText {
    return '$luggageCapacity '
        '${luggageCapacity == 1 ? 'bag' : 'bags'}';
  }

  String get estimatedDurationText {
    final mins = durationMinutes ?? estimatedDurationMinutes;
    return 'Approx. $mins min';
  }

  String get routeInfoText {
    if (distanceKm != null) {
      final mins = durationMinutes ?? estimatedDurationMinutes;
      return '${distanceKm!.toStringAsFixed(1)} km · $mins mins';
    }
    return estimatedDurationText;
  }

  factory AirportTransferVehicle.fromJson(
    Map<String, dynamic> json,
  ) {
    final List<String> images = [];
    if (json['images'] is List) {
      for (final item in json['images']) {
        if (item != null && item.toString().trim().isNotEmpty) {
          images.add(ApiConstants.fullUrl(item.toString().trim()));
        }
      }
    }
    final rawSingle = (json['imageUrl'] ?? json['image'] ?? '').toString().trim();
    if (images.isEmpty && rawSingle.isNotEmpty) {
      images.add(ApiConstants.fullUrl(rawSingle));
    }
    final primaryImageUrl = images.isNotEmpty ? images.first : '';

    final make = (json['make'] ?? '').toString();
    final model = (json['model'] ?? '').toString();
    final constructedName = '$make $model'.trim();
    final name = (json['name'] ?? json['vehicleName'] ?? (constructedName.isNotEmpty ? constructedName : 'Transfer Vehicle')).toString();

    // Supplier details
    String supplierName = 'GOZOLT Chauffeur';
    if (json['supplierName'] != null && json['supplierName'].toString().isNotEmpty) {
      supplierName = json['supplierName'].toString();
    } else if (json['supplier'] is Map && json['supplier']['companyName'] != null) {
      supplierName = json['supplier']['companyName'].toString();
    } else if (json['supplier'] is String && json['supplier'].toString().isNotEmpty) {
      supplierName = json['supplier'].toString();
    }

    final double pricePerKm = _readDouble(json['pricePerKm'], 2.50);
    final double minPrice = _readDouble(json['minPrice'], 20.00);
    final double? oneWayFare = json['oneWayFare'] != null ? _readDouble(json['oneWayFare'], minPrice) : null;
    final double? calculatedFare = json['calculatedFare'] != null ? _readDouble(json['calculatedFare'], minPrice) : null;
    final double? distanceKm = json['distanceKm'] != null ? _readDouble(json['distanceKm'], 0.0) : null;
    final int? durationMinutes = json['durationMinutes'] != null ? _readInt(json['durationMinutes'], 25) : null;
    final bool isRoundTrip = json['isRoundTrip'] == true;

    return AirportTransferVehicle(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: name,
      make: make,
      model: model,
      registrationNo: (json['registrationNo'] ?? '').toString(),
      year: json['year'] != null ? _readInt(json['year'], 2024) : null,
      type: _normalizeVehicleType((json['type'] ?? json['vehicleType'] ?? '').toString()),
      supplierName: supplierName,
      supplierRating: _readDouble(json['supplierRating'] ?? json['rating'], 4.8),
      passengerCapacity: _readInt(
        json['passengerCapacity'] ?? json['seats'],
        4,
      ),
      luggageCapacity: _readInt(
        json['luggageCapacity'] ?? json['bags'],
        2,
      ),
      fixedPrice: calculatedFare ?? _readDouble(
        json['fixedPrice'] ?? json['price'],
        minPrice,
      ),
      currency: (json['currency'] ?? 'EUR').toString(),
      imageUrl: primaryImageUrl,
      images: images,
      estimatedDurationMinutes: durationMinutes ?? _readInt(
        json['estimatedDurationMinutes'] ?? json['estimatedDuration'],
        25,
      ),
      features: List<String>.from(
        json['features'] ?? const <String>[],
      ),
      isMeetAndGreetIncluded: _readBool(json['isMeetAndGreetIncluded'], true),
      freeWaitingMinutes: _readInt(json['freeWaitingMinutes'], 60),
      status: (json['status'] ?? 'AVAILABLE').toString(),
      isRecommended: json['isRecommended'] == true || json['vehicleType'] == 'PREMIUM_5P',
      isBestValue: json['isBestValue'] == true || json['vehicleType'] == 'GO_5P',
      isActive: json['isActive'] != false,
      pricePerKm: pricePerKm,
      minPrice: minPrice,
      oneWayFare: oneWayFare,
      calculatedFare: calculatedFare,
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      isRoundTrip: isRoundTrip,
    );
  }

  static String _normalizeVehicleType(String raw) {
    switch (raw.toUpperCase()) {
      case 'GO_5P':
        return 'Go - 5P';
      case 'PREMIUM_5P':
        return 'Premium - 5P';
      case 'SUV_7P':
        return 'SUV - 7P';
      case 'MINI_VAN_8P':
        return 'Mini Van - 8P & Above';
      case 'VAN_8P':
        return 'Van - 8P & Above';
      case 'ELECTRIC_5P':
        return 'Electric - 5P';
      default:
        return raw;
    }
  }

  static bool _readBool(dynamic value, bool fallback) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final lower = value.toString().toLowerCase().trim();
    if (lower == 'true' || lower == '1') return true;
    if (lower == 'false' || lower == '0') return false;
    return fallback;
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
