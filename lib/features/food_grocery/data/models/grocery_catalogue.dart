enum GroceryProductUnitType {
  fixedUnit,
  pack,
  weight,
  piece,
}

enum GroceryProductStockStatus {
  inStock,
  lowStock,
  outOfStock,
}

class GroceryProductCategory {
  const GroceryProductCategory({
    required this.id,
    required this.name,
    required this.displayOrder,
    required this.isActive,
    this.imageUrl,
  });

  final String id;
  final String name;
  final int displayOrder;
  final bool isActive;
  final String? imageUrl;
}

class GroceryProduct {
  const GroceryProduct({
    required this.id,
    required this.storeId,
    required this.categoryId,
    required this.name,
    required this.brand,
    required this.description,
    required this.unitType,
    required this.unitText,
    required this.basePrice,
    required this.stockStatus,
    required this.availableQuantity,
    required this.maximumQuantity,
    required this.hasVariants,
    required this.isActive,
    this.offerPrice,
    this.offerText,
    this.imageUrl,
    this.isPopular = false,
    this.dietaryTags = const [],
  });

  final String id;
  final String storeId;
  final String categoryId;
  final String name;
  final String brand;
  final String description;
  final GroceryProductUnitType unitType;
  final String unitText;
  final double basePrice;
  final double? offerPrice;
  final String? offerText;
  final GroceryProductStockStatus stockStatus;
  final int availableQuantity;
  final int maximumQuantity;
  final bool hasVariants;
  final bool isActive;
  final String? imageUrl;
  final bool isPopular;
  final List<String> dietaryTags;

  /// Returns a customer-friendly brand name, hiding internal generated SKU codes.
  String? get displayBrand {
    final trimmed = brand.trim();
    if (trimmed.isEmpty) return null;
    final upper = trimmed.toUpperCase();
    if (upper.startsWith('SKU-') ||
        upper.startsWith('GZ-SKU-') ||
        upper.startsWith('GZ-PRD-')) {
      return null;
    }
    return trimmed;
  }

  bool get isOrganic => dietaryTags.contains('organic');
  bool get isVegan => dietaryTags.contains('vegan');
  bool get isGlutenFree => dietaryTags.contains('glutenFree');
  bool get isVegetarian => dietaryTags.contains('vegetarian');

  double get currentPrice => offerPrice ?? basePrice;

  bool get hasOffer {
    return offerPrice != null && offerPrice! < basePrice;
  }

  bool get canAddDirectly {
    return isActive &&
        stockStatus != GroceryProductStockStatus.outOfStock &&
        !hasVariants;
  }

  int get allowedQuantity {
    if (availableQuantity < maximumQuantity) {
      return availableQuantity;
    }

    return maximumQuantity;
  }

  String get stockText {
    switch (stockStatus) {
      case GroceryProductStockStatus.inStock:
        return 'In Stock';

      case GroceryProductStockStatus.lowStock:
        return 'Only $availableQuantity left';

      case GroceryProductStockStatus.outOfStock:
        return 'Out of Stock';
    }
  }

  String get unitTypeText {
    final raw = unitText.trim();
    if (raw.isEmpty || raw.contains('min')) {
      return '1 Unit';
    }
    if (RegExp(r'^\d+$').hasMatch(raw)) {
      final count = int.tryParse(raw) ?? 1;
      return count == 1 ? '1 Unit' : '$count Units';
    }
    switch (unitType) {
      case GroceryProductUnitType.fixedUnit:
      case GroceryProductUnitType.pack:
      case GroceryProductUnitType.piece:
        return raw;

      case GroceryProductUnitType.weight:
        return '$raw • By weight';
    }
  }
}
