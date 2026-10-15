import 'grocery_catalogue.dart';

class GroceryProductSelectionOption {
  const GroceryProductSelectionOption({
    required this.id,
    required this.name,
    required this.unitText,
    required this.price,
    required this.stockStatus,
    required this.availableQuantity,
    required this.maximumQuantity,
    required this.isActive,
    this.originalPrice,
    this.isEstimatedWeight = false,
  });

  final String id;
  final String name;
  final String unitText;
  final double price;
  final double? originalPrice;
  final GroceryProductStockStatus stockStatus;
  final int availableQuantity;
  final int maximumQuantity;
  final bool isActive;
  final bool isEstimatedWeight;

  bool get isAvailable {
    return isActive &&
        stockStatus != GroceryProductStockStatus.outOfStock &&
        availableQuantity > 0;
  }

  bool get hasOffer {
    return originalPrice != null && originalPrice! > price;
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
}
