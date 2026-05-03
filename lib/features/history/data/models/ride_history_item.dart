class RideHistoryItem {
  final String id;
  final String status;
  final String pickupAddress;
  final String dropoffAddress;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropoffLat;
  final double? dropoffLng;
  final String vehicleType;
  final double? estimatedFare;
  final double? actualFare;
  final String? paymentMethod;
  final String createdAt;
  final bool isScheduled;
  final String? scheduledAt;
  final String? driverName;
  final double? driverRating;
  final String? driverVehicle;
  final String? driverPlate;
  final String? driverAvatarUrl;
  final double? distanceKm;
  final int? durationMinutes;
  final int? rating;
  final String? cancelReason;
  final int? goCoinsEarned;
  final String? otpPin;
  final double? baseFare;
  final double? distanceFare;
  final double? timeFare;
  final double? waitTimeFee;
  final double? bookingFee;
  final double? surgeMultiplier;
  final double? tipAmount;

  const RideHistoryItem({
    required this.id,
    required this.status,
    required this.pickupAddress,
    required this.dropoffAddress,
    this.pickupLat,
    this.pickupLng,
    this.dropoffLat,
    this.dropoffLng,
    required this.vehicleType,
    this.estimatedFare,
    this.actualFare,
    this.paymentMethod,
    required this.createdAt,
    this.isScheduled = false,
    this.scheduledAt,
    this.driverName,
    this.driverRating,
    this.driverVehicle,
    this.driverPlate,
    this.driverAvatarUrl,
    this.distanceKm,
    this.durationMinutes,
    this.rating,
    this.cancelReason,
    this.goCoinsEarned,
    this.otpPin,
    this.baseFare,
    this.distanceFare,
    this.timeFare,
    this.waitTimeFee,
    this.bookingFee,
    this.surgeMultiplier,
    this.tipAmount,
  });

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  factory RideHistoryItem.fromJson(Map<String, dynamic> json) {
    // Parse nested driver object
    final driverJson = json['driver'] as Map<String, dynamic>?;
    String? driverName;
    double? driverRating;
    String? driverVehicle;
    String? driverPlate;
    String? driverAvatarUrl;

    if (driverJson != null) {
      final first = driverJson['firstName'] as String? ?? '';
      final last = driverJson['lastName'] as String? ?? '';
      driverName = '$first $last'.trim();
      if (driverName.isEmpty) driverName = null;
      driverRating = _toDouble(driverJson['avgRating']);
      driverAvatarUrl = driverJson['avatarUrl'] as String?;

      final va = driverJson['vehicleAssignment'] as Map<String, dynamic>?;
      final v = va?['vehicle'] as Map<String, dynamic>?;
      if (v != null) {
        driverVehicle = '${v['make'] ?? ''} ${v['model'] ?? ''}'.trim();
        driverPlate = v['plateNumber'] as String?;
      }
    }

    // Parse nested cancellation
    final cancel = json['cancellation'] as Map<String, dynamic>?;
    final cancelReason = cancel?['reason'] as String? ?? json['cancelReason'] as String?;

    // Parse nested payment
    final pay = json['payment'] as Map<String, dynamic>?;
    final payMethod = pay?['method'] as String? ?? json['paymentMethod'] as String?;

    // Parse user rating
    final ratings = json['ratings'] as List<dynamic>?;
    int? userRating;
    if (ratings != null && ratings.isNotEmpty) {
      userRating = _toInt((ratings.first as Map<String, dynamic>?)?['rating']);
    }

    return RideHistoryItem(
      id: json['id'] as String,
      status: json['status'] as String,
      pickupAddress: json['pickupAddress'] as String? ?? '',
      dropoffAddress: json['dropoffAddress'] as String? ?? '',
      pickupLat: _toDouble(json['pickupLat']),
      pickupLng: _toDouble(json['pickupLng']),
      dropoffLat: _toDouble(json['dropoffLat']),
      dropoffLng: _toDouble(json['dropoffLng']),
      vehicleType: json['vehicleType'] as String? ?? 'STANDARD',
      estimatedFare: _toDouble(json['estimatedFare']),
      actualFare: _toDouble(json['actualFare']),
      paymentMethod: payMethod,
      createdAt: json['createdAt'] as String? ?? '',
      isScheduled: json['isScheduled'] as bool? ?? false,
      scheduledAt: json['scheduledAt'] as String?,
      driverName: driverName ?? json['driverName'] as String?,
      driverRating: driverRating ?? _toDouble(json['driverRating']),
      driverVehicle: driverVehicle ?? json['driverVehicle'] as String?,
      driverPlate: driverPlate ?? json['driverPlate'] as String?,
      driverAvatarUrl: driverAvatarUrl ?? json['driverAvatarUrl'] as String?,
      distanceKm: _toDouble(json['distanceKm']),
      durationMinutes: _toInt(json['durationMinutes']),
      rating: userRating ?? _toInt(json['rating']),
      cancelReason: cancelReason,
      goCoinsEarned: _toInt(json['goCoinsEarned']),
      otpPin: json['otpPin'] as String? ?? json['otp'] as String?,
      baseFare: _toDouble(json['baseFare']),
      distanceFare: _toDouble(json['distanceFare']),
      timeFare: _toDouble(json['timeFare']),
      waitTimeFee: _toDouble(json['waitTimeFee']),
      bookingFee: _toDouble(json['bookingFee']),
      surgeMultiplier: _toDouble(json['surgeMultiplier']),
      tipAmount: _toDouble(json['tipAmount']),
    );
  }

  double get displayFare => actualFare ?? estimatedFare ?? 0;

  bool get isCompleted => status == 'COMPLETED';
  bool get isCancelled => status == 'CANCELLED';
  bool get isActive =>
      status == 'DRIVER_EN_ROUTE' ||
      status == 'DRIVER_ARRIVED' ||
      status == 'IN_PROGRESS';

  String get displayStatus {
    switch (status) {
      case 'COMPLETED':
        return 'Completed';
      case 'CANCELLED':
        return 'Cancelled';
      case 'SCHEDULED':
        return 'Scheduled';
      case 'DRIVER_EN_ROUTE':
        return 'Driver En Route';
      case 'DRIVER_ARRIVED':
        return 'Driver Arrived';
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'PENDING':
        return 'Pending';
      default:
        return status;
    }
  }

  String get displayVehicle {
    switch (vehicleType) {
      case 'ECONOMY':
        return 'Economy';
      case 'STANDARD':
        return 'Standard';
      case 'PREMIUM':
        return 'Premium';
      case 'XL':
        return 'XL';
      case 'ELECTRIC':
        return 'Electric';
      default:
        return vehicleType;
    }
  }
}
