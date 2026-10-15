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
    this.imageUrl,
    this.offerText,
    this.promotionalTag,
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
  final String? imageUrl;
  final String? offerText;
  final String? promotionalTag;

  bool get isOrderable {
    return status == GroceryStoreOperationalStatus.open ||
        status == GroceryStoreOperationalStatus.busy ||
        status == GroceryStoreOperationalStatus.closingSoon;
  }

  bool get hasFreeDelivery => deliveryFee == 0;

  String get categoryText {
    return mainCategories.join(' • ');
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
    switch (status) {
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
    String? imageUrl,
    String? offerText,
    String? promotionalTag,
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
      imageUrl: imageUrl ?? this.imageUrl,
      offerText: offerText ?? this.offerText,
      promotionalTag: promotionalTag ?? this.promotionalTag,
    );
  }
}
