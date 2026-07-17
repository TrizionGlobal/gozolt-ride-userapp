import 'ride_stop.dart';

class Ride {
  final String id;
  final String status;
  final String pickupAddress;
  final double pickupLat;
  final double pickupLng;
  final String dropoffAddress;
  final double dropoffLat;
  final double dropoffLng;
  final String vehicleType;
  final String? paymentMethod;
  final String? paymentMethodId;
  final double? estimatedFare;
  final double? actualFare;
  final List<RideStop> stops;
  final bool isScheduled;
  final String? scheduledAt;
  final String? driverId;
  final String? promoCode;
  final String createdAt;
  final String? updatedAt;
  final double? baseFare;
  final double? distanceFare;
  final double? timeFare;
  final double? waitTimeFee;
  final double? bookingFee;
  final double surgeMultiplier;
  final double? distanceKm;
  final int? durationMinutes;
  final double? tipAmount;
  final double? extraFare;

  const Ride({
    required this.id,
    required this.status,
    required this.pickupAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffAddress,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.vehicleType,
    this.paymentMethod,
    this.paymentMethodId,
    this.estimatedFare,
    this.actualFare,
    this.stops = const [],
    this.isScheduled = false,
    this.scheduledAt,
    this.driverId,
    this.promoCode,
    required this.createdAt,
    this.updatedAt,
    this.baseFare,
    this.distanceFare,
    this.timeFare,
    this.waitTimeFee,
    this.bookingFee,
    this.surgeMultiplier = 1.0,
    this.distanceKm,
    this.durationMinutes,
    this.tipAmount,
    this.extraFare,
  });

  /// Safely parse a value that may be num or String to double.
  static double _toDouble(dynamic v, double fallback) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }

  static double? _toDoubleOrNull(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static int? _toIntOrNull(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  factory Ride.fromJson(Map<String, dynamic> json) {
    print('DEBUG JSON PARSING: ${json.keys.toList()}');
    print('DEBUG JSON pickupAddress: ${json['pickupAddress']}');
    print('DEBUG JSON actualFare: ${json['actualFare']}');
    return Ride(
      id: json['id'] as String,
      status: json['status'] as String,
      pickupAddress: json['pickupAddress'] as String? ?? '',
      pickupLat: _toDouble(json['pickupLat'], 0),
      pickupLng: _toDouble(json['pickupLng'], 0),
      dropoffAddress: json['dropoffAddress'] as String? ?? '',
      dropoffLat: _toDouble(json['dropoffLat'], 0),
      dropoffLng: _toDouble(json['dropoffLng'], 0),
      vehicleType: json['vehicleType'] as String? ?? 'STANDARD',
      paymentMethod: json['paymentMethod'] as String?,
      paymentMethodId: json['paymentMethodId'] as String?,
      estimatedFare: _toDoubleOrNull(json['estimatedFare']),
      actualFare: _toDoubleOrNull(json['actualFare']),
      stops: (json['stops'] as List<dynamic>?)
              ?.map((s) => RideStop.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      isScheduled: json['isScheduled'] as bool? ?? false,
      scheduledAt: json['scheduledAt'] as String?,
      driverId: json['driverId'] as String?,
      promoCode: json['promoCode'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String?,
      baseFare: _toDoubleOrNull(json['baseFare']),
      distanceFare: _toDoubleOrNull(json['distanceFare']),
      timeFare: _toDoubleOrNull(json['timeFare']),
      waitTimeFee: _toDoubleOrNull(json['waitTimeFee']),
      bookingFee: _toDoubleOrNull(json['bookingFee']),
      surgeMultiplier: _toDouble(json['surgeMultiplier'], 1.0),
      distanceKm: _toDoubleOrNull(json['distanceKm']),
      durationMinutes: _toIntOrNull(json['durationMinutes']),
      tipAmount: _toDoubleOrNull(json['tipAmount']),
      extraFare: _toDoubleOrNull(json['extraFare']),
    );
  }

  Ride copyWith({
    String? id,
    String? status,
    String? pickupAddress,
    double? pickupLat,
    double? pickupLng,
    String? dropoffAddress,
    double? dropoffLat,
    double? dropoffLng,
    String? vehicleType,
    String? paymentMethod,
    String? paymentMethodId,
    double? estimatedFare,
    double? actualFare,
    List<RideStop>? stops,
    bool? isScheduled,
    String? scheduledAt,
    String? driverId,
    String? promoCode,
    String? createdAt,
    double? baseFare,
    double? timeFare,
    double? waitTimeFee,
    double? bookingFee,
    double? surgeMultiplier,
    double? distanceKm,
    int? durationMinutes,
    double? tipAmount,
    double? extraFare,
  }) {
    return Ride(
      id: id ?? this.id,
      status: status ?? this.status,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      dropoffLat: dropoffLat ?? this.dropoffLat,
      dropoffLng: dropoffLng ?? this.dropoffLng,
      vehicleType: vehicleType ?? this.vehicleType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      estimatedFare: estimatedFare ?? this.estimatedFare,
      actualFare: actualFare ?? this.actualFare,
      stops: stops ?? this.stops,
      isScheduled: isScheduled ?? this.isScheduled,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      driverId: driverId ?? this.driverId,
      promoCode: promoCode ?? this.promoCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      baseFare: baseFare ?? this.baseFare,
      distanceFare: distanceFare ?? this.distanceFare,
      timeFare: timeFare ?? this.timeFare,
      waitTimeFee: waitTimeFee ?? this.waitTimeFee,
      bookingFee: bookingFee ?? this.bookingFee,
      surgeMultiplier: surgeMultiplier ?? this.surgeMultiplier,
      distanceKm: distanceKm ?? this.distanceKm,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      tipAmount: tipAmount ?? this.tipAmount,
      extraFare: extraFare ?? this.extraFare,
    );
  }
}
