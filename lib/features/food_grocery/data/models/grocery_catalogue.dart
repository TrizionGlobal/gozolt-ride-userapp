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
  });

  final String id;
  final String name;
  final int displayOrder;
  final bool isActive;
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
    switch (unitType) {
      case GroceryProductUnitType.fixedUnit:
        return unitText;

      case GroceryProductUnitType.pack:
        return unitText;

      case GroceryProductUnitType.weight:
        return '$unitText • Priced by weight';

      case GroceryProductUnitType.piece:
        return '$unitText • Per piece';
    }
  }
}
