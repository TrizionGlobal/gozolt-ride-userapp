import 'dart:math' as math;

enum GroceryStoreOperationalStatus {
  open,
  busy,
  closingSoon,
  closed,
  temporarilyUnavailable,
}

class GroceryStore {
  const GroceryStore({
    required this.id,
    required this.supplierId,
    required this.name,
    required this.storeType,
    required this.mainCategories,
    required this.rating,
    required this.ratingCount,
    required this.estimatedDeliveryTime,
    required this.deliveryFee,
    required this.distanceKm,
    required this.minimumOrder,
    required this.status,
    required this.isFavourite,
    required this.matchingProductNames,
    this.preparationTime = '15–20 min',
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
  final String storeType;
  final List<String> mainCategories;
  final double rating;
  final int ratingCount;
  final String estimatedDeliveryTime;
  final double deliveryFee;
  final double distanceKm;
  final double minimumOrder;
  final GroceryStoreOperationalStatus status;
  final bool isFavourite;
  final List<String> matchingProductNames;
  final String preparationTime;
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
      return '08:00 AM – 10:00 PM';
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
    return '08:00 AM – 10:00 PM';
  }

  bool get isCurrentlyOpen {
    if (status != GroceryStoreOperationalStatus.open) {
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

  GroceryStoreOperationalStatus get effectiveStatus {
    if (status == GroceryStoreOperationalStatus.open && !isCurrentlyOpen) {
      return GroceryStoreOperationalStatus.closed;
    }
    return status;
  }

  bool get isOrderable {
    return effectiveStatus == GroceryStoreOperationalStatus.open ||
        effectiveStatus == GroceryStoreOperationalStatus.busy ||
        effectiveStatus == GroceryStoreOperationalStatus.closingSoon;
  }

  bool get hasFreeDelivery => deliveryFee == 0;

  String get categoryText {
    return mainCategories.join(' • ');
  }

  String get formattedRatingText {
    if (ratingCount <= 0) {
      return 'New';
    }
    return '${rating.toStringAsFixed(1)} ($ratingCount)';
  }

  double calculateDistanceTo(double? userLat, double? userLng) {
    if (userLat == null || userLng == null || latitude == null || longitude == null) {
      return distanceKm;
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

  String get deliveryFeeText {
    if (hasFreeDelivery) {
      return 'Free delivery';
    }

    return '€${deliveryFee.toStringAsFixed(2)} delivery';
  }

  String get distanceText {
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  String get minimumOrderText {
    return 'Minimum €${minimumOrder.toStringAsFixed(2)}';
  }

  String get statusText {
    switch (effectiveStatus) {
      case GroceryStoreOperationalStatus.open:
        return 'Open';

      case GroceryStoreOperationalStatus.busy:
        return 'Busy';

      case GroceryStoreOperationalStatus.closingSoon:
        return 'Closing soon';

      case GroceryStoreOperationalStatus.closed:
        return 'Closed';

      case GroceryStoreOperationalStatus.temporarilyUnavailable:
        return 'Temporarily unavailable';
    }
  }

  bool matchesSearch(String searchValue) {
    final query = searchValue.trim().toLowerCase();

    if (query.isEmpty) {
      return true;
    }

    final matchesName = name.toLowerCase().contains(query);

    final matchesType = storeType.toLowerCase().contains(query);

    final matchesCategory = mainCategories.any(
      (category) => category.toLowerCase().contains(query),
    );

    final matchesProduct = matchingProductNames.any(
      (product) => product.toLowerCase().contains(query),
    );

    return matchesName || matchesType || matchesCategory || matchesProduct;
  }

  GroceryStore copyWith({
    String? id,
    String? supplierId,
    String? name,
    String? storeType,
    List<String>? mainCategories,
    double? rating,
    int? ratingCount,
    String? estimatedDeliveryTime,
    double? deliveryFee,
    double? distanceKm,
    double? minimumOrder,
    GroceryStoreOperationalStatus? status,
    bool? isFavourite,
    List<String>? matchingProductNames,
    String? preparationTime,
    double? latitude,
    double? longitude,
    String? imageUrl,
    String? offerText,
    String? promotionalTag,
    List<dynamic>? operatingHours,
  }) {
    return GroceryStore(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
      name: name ?? this.name,
      storeType: storeType ?? this.storeType,
      mainCategories: mainCategories ?? this.mainCategories,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      estimatedDeliveryTime:
          estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      distanceKm: distanceKm ?? this.distanceKm,
      minimumOrder: minimumOrder ?? this.minimumOrder,
      status: status ?? this.status,
      isFavourite: isFavourite ?? this.isFavourite,
      matchingProductNames: matchingProductNames ?? this.matchingProductNames,
      preparationTime: preparationTime ?? this.preparationTime,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrl: imageUrl ?? this.imageUrl,
      offerText: offerText ?? this.offerText,
      promotionalTag: promotionalTag ?? this.promotionalTag,
      operatingHours: operatingHours ?? this.operatingHours,
    );
  }
}
