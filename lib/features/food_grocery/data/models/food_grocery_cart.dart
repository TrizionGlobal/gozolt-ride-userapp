enum FoodGroceryCartType {
  food,
  grocery,
}

class FoodGroceryCartModifier {
  const FoodGroceryCartModifier({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
  });

  final String id;
  final String name;
  final double price;
  final int quantity;

  double get totalPrice => price * quantity;
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

  /// Base price for one unit of the item (including size variant).
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

  double get modifiersTotal => modifiers.fold(
        0.0,
        (sum, modifier) => sum + modifier.totalPrice,
      );

  double get lineTotal => (unitPrice * quantity) + modifiersTotal;

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
    this.distanceKm,
  });

  final List<FoodGroceryCartItem> items;
  final double deliveryFee;
  final double serviceFee;
  final double discount;
  final double? distanceKm;

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

  /// 10% Platform VAT matching Car Rental and other Gozolt services
  double get vat => subtotal * 0.10;

  double get total {
    final calculatedTotal = subtotal + deliveryFee + serviceFee + vat - discount;

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
    double? distanceKm,
  }) {
    return FoodGroceryCartState(
      items: items ?? this.items,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      serviceFee: serviceFee ?? this.serviceFee,
      discount: discount ?? this.discount,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }
}
