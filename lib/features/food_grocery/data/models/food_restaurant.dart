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
    this.imageUrl,
    this.offerText,
    this.promotionalTag,
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
  final String? imageUrl;
  final String? offerText;
  final String? promotionalTag;

  bool get isOrderable {
    return status == RestaurantOperationalStatus.open ||
        status == RestaurantOperationalStatus.closingSoon ||
        status == RestaurantOperationalStatus.busy;
  }

  bool get hasFreeDelivery => deliveryFee == 0;

  String get cuisineText => cuisines.join(' • ');

  String get deliveryFeeText {
    if (hasFreeDelivery) {
      return 'Free delivery';
    }

    return '€${deliveryFee.toStringAsFixed(2)} delivery';
  }

  String get distanceText {
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  String get statusText {
    switch (status) {
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
    String? imageUrl,
    String? offerText,
    String? promotionalTag,
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
      imageUrl: imageUrl ?? this.imageUrl,
      offerText: offerText ?? this.offerText,
      promotionalTag: promotionalTag ?? this.promotionalTag,
    );
  }
}
