import 'dart:math' as math;

enum RestaurantOperationalStatus {
  open,
  closingSoon,
  busy,
  closed,
  temporarilyUnavailable,
}

class FoodRestaurant {
  const FoodRestaurant({
    required this.id,
    required this.supplierId,
    required this.name,
    required this.cuisines,
    required this.rating,
    required this.ratingCount,
    required this.estimatedDeliveryTime,
    required this.deliveryFee,
    required this.distanceKm,
    required this.priceLevel,
    required this.status,
    required this.isFavourite,
    required this.hasVegetarianOptions,
    this.minimumOrder = 15.0,
    this.preparationTime = '15–20 min',
    this.deliveryInstructions,
    this.address,
    this.latitude,
    this.longitude,
    this.imageUrl,
    this.offerText,
    this.promotionalTag,
    this.operatingHours,
  });

  final String id;
  final String supplierId;
  final String name;
  final List<String> cuisines;
  final double rating;
  final int ratingCount;
  final String estimatedDeliveryTime;
  final double deliveryFee;
  final double distanceKm;
  final String priceLevel;
  final RestaurantOperationalStatus status;
  final bool isFavourite;
  final bool hasVegetarianOptions;
  final double minimumOrder;
  final String preparationTime;
  final String? deliveryInstructions;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? imageUrl;
  final String? offerText;
  final String? promotionalTag;
  final List<dynamic>? operatingHours;

  static String _formatTimeStr(String time) {
    if (time.isEmpty) return '';
    final parts = time.split(':');
    if (parts.length < 2) return time;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts[1].padLeft(2, '0');
    final isPm = hour >= 12;
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final period = isPm ? 'PM' : 'AM';
    return '$displayHour:$minute $period';
  }

  String get operatingHoursTodayText {
    if (operatingHours == null || operatingHours!.isEmpty) {
      return '10:00 AM – 11:00 PM';
    }
    final now = DateTime.now();
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final currentDay = days[now.weekday - 1];

    for (final raw in operatingHours!) {
      if (raw is Map) {
        final day = raw['day']?.toString();
        if (day?.toLowerCase() == currentDay.toLowerCase()) {
          final isOpen = raw['isOpen'] == true;
          if (!isOpen) return 'Closed today';
          final shifts = raw['shifts'] as List<dynamic>?;
          if (shifts == null || shifts.isEmpty) return 'Open today';
          final shiftList = shifts
              .map((s) {
                if (s is Map) {
                  final open = _formatTimeStr(s['openTime']?.toString() ?? '');
                  final close = _formatTimeStr(s['closeTime']?.toString() ?? '');
                  if (open.isNotEmpty && close.isNotEmpty) {
                    return '$open – $close';
                  }
                }
                return '';
              })
              .where((s) => s.isNotEmpty)
              .toList();
          return shiftList.isNotEmpty ? shiftList.join(', ') : 'Open today';
        }
      }
    }
    return '10:00 AM – 11:00 PM';
  }

  String get minimumOrderText => 'Minimum €${minimumOrder.toStringAsFixed(2)}';

  bool get isCurrentlyOpen {
    if (status != RestaurantOperationalStatus.open) {
      return false;
    }
    if (operatingHours == null || operatingHours!.isEmpty) {
      return true;
    }
    final now = DateTime.now();
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final currentDay = days[now.weekday - 1];

    for (final raw in operatingHours!) {
      if (raw is Map) {
        final day = raw['day']?.toString();
        if (day?.toLowerCase() == currentDay.toLowerCase()) {
          final isOpen = raw['isOpen'] == true;
          if (!isOpen) return false;
          final shifts = raw['shifts'] as List<dynamic>?;
          if (shifts == null || shifts.isEmpty) return true;
          final currentMinutes = now.hour * 60 + now.minute;
          var inShift = false;
          for (final s in shifts) {
            if (s is Map) {
              final open = s['openTime']?.toString() ?? '';
              final close = s['closeTime']?.toString() ?? '';
              final openParts = open.split(':');
              final closeParts = close.split(':');
              if (openParts.length == 2 && closeParts.length == 2) {
                final openMin = (int.tryParse(openParts[0]) ?? 0) * 60 +
                    (int.tryParse(openParts[1]) ?? 0);
                var closeMin = (int.tryParse(closeParts[0]) ?? 0) * 60 +
                    (int.tryParse(closeParts[1]) ?? 0);
                if (closeMin == 0) closeMin = 24 * 60;
                if (currentMinutes >= openMin && currentMinutes <= closeMin) {
                  inShift = true;
                  break;
                }
              }
            }
          }
          return inShift;
        }
      }
    }
    return true;
  }

  RestaurantOperationalStatus get effectiveStatus {
    if (status == RestaurantOperationalStatus.open && !isCurrentlyOpen) {
      return RestaurantOperationalStatus.closed;
    }
    return status;
  }

  bool get isOrderable {
    return effectiveStatus == RestaurantOperationalStatus.open ||
        effectiveStatus == RestaurantOperationalStatus.closingSoon ||
        effectiveStatus == RestaurantOperationalStatus.busy;
  }

  bool get hasFreeDelivery => deliveryFee == 0;

  String get cuisineText => cuisines.join(' • ');

  String get formattedRatingText {
    if (ratingCount > 0) {
      return '${rating.toStringAsFixed(1)} ($ratingCount)';
    }
    if (rating > 0) {
      return rating.toStringAsFixed(1);
    }
    return 'New';
  }

  double? calculateDistanceTo(double? userLat, double? userLng) {
    if (userLat == null || userLng == null || latitude == null || longitude == null) {
      return distanceKm > 0 ? distanceKm : null;
    }
    const earthRadius = 6371.0;
    final dLat = (userLat - latitude!) * (math.pi / 180.0);
    final dLng = (userLng - longitude!) * (math.pi / 180.0);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(latitude! * (math.pi / 180.0)) *
            math.cos(userLat * (math.pi / 180.0)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final calc = earthRadius * c;
    return calc < 0.1 ? 0.1 : double.parse(calc.toStringAsFixed(1));
  }

  String? dynamicDistanceText(double? userLat, double? userLng) {
    final d = calculateDistanceTo(userLat, userLng);
    if (d == null) return null;
    return '${d.toStringAsFixed(1)} km';
  }

  String get deliveryFeeText {
    if (hasFreeDelivery) {
      return 'Free delivery';
    }

    return '€${deliveryFee.toStringAsFixed(2)} delivery';
  }

  String? get distanceText {
    if (distanceKm <= 0) return null;
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  String get statusText {
    switch (effectiveStatus) {
      case RestaurantOperationalStatus.open:
        return 'Open';

      case RestaurantOperationalStatus.closingSoon:
        return 'Closing soon';

      case RestaurantOperationalStatus.busy:
        return 'Busy';

      case RestaurantOperationalStatus.closed:
        return 'Closed';

      case RestaurantOperationalStatus.temporarilyUnavailable:
        return 'Temporarily unavailable';
    }
  }

  FoodRestaurant copyWith({
    String? id,
    String? supplierId,
    String? name,
    List<String>? cuisines,
    double? rating,
    int? ratingCount,
    String? estimatedDeliveryTime,
    double? deliveryFee,
    double? distanceKm,
    String? priceLevel,
    RestaurantOperationalStatus? status,
    bool? isFavourite,
    bool? hasVegetarianOptions,
    double? minimumOrder,
    String? preparationTime,
    String? deliveryInstructions,
    String? address,
    double? latitude,
    double? longitude,
    String? imageUrl,
    String? offerText,
    String? promotionalTag,
    List<dynamic>? operatingHours,
  }) {
    return FoodRestaurant(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
      name: name ?? this.name,
      cuisines: cuisines ?? this.cuisines,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      estimatedDeliveryTime:
          estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      distanceKm: distanceKm ?? this.distanceKm,
      priceLevel: priceLevel ?? this.priceLevel,
      status: status ?? this.status,
      isFavourite: isFavourite ?? this.isFavourite,
      hasVegetarianOptions: hasVegetarianOptions ?? this.hasVegetarianOptions,
      minimumOrder: minimumOrder ?? this.minimumOrder,
      preparationTime: preparationTime ?? this.preparationTime,
      deliveryInstructions:
          deliveryInstructions ?? this.deliveryInstructions,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrl: imageUrl ?? this.imageUrl,
      offerText: offerText ?? this.offerText,
      promotionalTag: promotionalTag ?? this.promotionalTag,
      operatingHours: operatingHours ?? this.operatingHours,
    );
  }
}
