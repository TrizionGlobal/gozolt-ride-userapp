enum FoodGroceryCartType {
  food,
  grocery,
}

class FoodGroceryCartModifier {
  const FoodGroceryCartModifier({
    required this.id,
    required this.name,
    required this.price,
  });

  final String id;
  final String name;
  final double price;
}

class FoodGroceryCartItem {
  const FoodGroceryCartItem({
    required this.lineId,
    required this.productId,
    required this.supplierId,
    required this.supplierName,
    required this.name,
    required this.cartType,
    required this.unitPrice,
    required this.quantity,
    this.imageUrl,
    this.variantId,
    this.variantName,
    this.modifiers = const [],
    this.instructions,
    this.maximumQuantity,
    this.isEstimatedWeight = false,
  });

  /// Unique ID containing product, variant and modifier selections.
  final String lineId;

  final String productId;
  final String supplierId;
  final String supplierName;
  final String name;
  final FoodGroceryCartType cartType;

  /// Complete price for one unit, including selected modifiers.
  final double unitPrice;

  final int quantity;
  final String? imageUrl;

  /// Used for food sizes and grocery weights/variants.
  final String? variantId;
  final String? variantName;

  final List<FoodGroceryCartModifier> modifiers;
  final String? instructions;

  /// Grocery stock limit. Leave null for food items.
  final int? maximumQuantity;

  /// True for products whose final weight may vary.
  final bool isEstimatedWeight;

  double get lineTotal => unitPrice * quantity;

  FoodGroceryCartItem copyWith({
    String? lineId,
    String? productId,
    String? supplierId,
    String? supplierName,
    String? name,
    FoodGroceryCartType? cartType,
    double? unitPrice,
    int? quantity,
    String? imageUrl,
    String? variantId,
    String? variantName,
    List<FoodGroceryCartModifier>? modifiers,
    String? instructions,
    int? maximumQuantity,
    bool? isEstimatedWeight,
  }) {
    return FoodGroceryCartItem(
      lineId: lineId ?? this.lineId,
      productId: productId ?? this.productId,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      name: name ?? this.name,
      cartType: cartType ?? this.cartType,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      variantId: variantId ?? this.variantId,
      variantName: variantName ?? this.variantName,
      modifiers: modifiers ?? this.modifiers,
      instructions: instructions ?? this.instructions,
      maximumQuantity: maximumQuantity ?? this.maximumQuantity,
      isEstimatedWeight: isEstimatedWeight ?? this.isEstimatedWeight,
    );
  }
}

class FoodGroceryCartState {
  const FoodGroceryCartState({
    this.items = const [],
    this.deliveryFee = 0,
    this.serviceFee = 0,
    this.discount = 0,
  });

  final List<FoodGroceryCartItem> items;
  final double deliveryFee;
  final double serviceFee;
  final double discount;

  bool get isEmpty => items.isEmpty;

  bool get isNotEmpty => items.isNotEmpty;

  int get itemCount {
    return items.fold<int>(
      0,
      (total, item) => total + item.quantity,
    );
  }

  double get subtotal {
    return items.fold<double>(
      0,
      (total, item) => total + item.lineTotal,
    );
  }

  double get total {
    final calculatedTotal = subtotal + deliveryFee + serviceFee - discount;

    return calculatedTotal < 0 ? 0 : calculatedTotal;
  }

  String? get supplierId {
    return items.isEmpty ? null : items.first.supplierId;
  }

  String? get supplierName {
    return items.isEmpty ? null : items.first.supplierName;
  }

  FoodGroceryCartType? get cartType {
    return items.isEmpty ? null : items.first.cartType;
  }

  FoodGroceryCartState copyWith({
    List<FoodGroceryCartItem>? items,
    double? deliveryFee,
    double? serviceFee,
    double? discount,
  }) {
    return FoodGroceryCartState(
      items: items ?? this.items,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      serviceFee: serviceFee ?? this.serviceFee,
      discount: discount ?? this.discount,
    );
  }
}
