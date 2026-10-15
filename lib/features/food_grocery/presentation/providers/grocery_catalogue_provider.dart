import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/grocery_catalogue.dart';

final groceryCatalogueProvider = StateNotifierProvider.family<
    GroceryCatalogueNotifier, GroceryCatalogueState, String>(
  (ref, storeId) {
    return GroceryCatalogueNotifier(storeId);
  },
);

class GroceryCatalogueState {
  const GroceryCatalogueState({
    required this.storeId,
    required this.categories,
    required this.products,
    required this.quantities,
  });

  final String storeId;
  final List<GroceryProductCategory> categories;
  final List<GroceryProduct> products;
  final Map<String, int> quantities;

  int quantityFor(String productId) {
    return quantities[productId] ?? 0;
  }

  int get cartItemCount {
    return quantities.values.fold(
      0,
      (total, quantity) => total + quantity,
    );
  }

  double get cartSubtotal {
    var total = 0.0;

    for (final product in products) {
      final quantity = quantityFor(product.id);

      if (quantity > 0) {
        total += product.currentPrice * quantity;
      }
    }

    return total;
  }

  GroceryCatalogueState copyWith({
    String? storeId,
    List<GroceryProductCategory>? categories,
    List<GroceryProduct>? products,
    Map<String, int>? quantities,
  }) {
    return GroceryCatalogueState(
      storeId: storeId ?? this.storeId,
      categories: categories ?? this.categories,
      products: products ?? this.products,
      quantities: quantities ?? this.quantities,
    );
  }
}

class GroceryCatalogueNotifier extends StateNotifier<GroceryCatalogueState> {
  GroceryCatalogueNotifier(String storeId)
      : super(
          GroceryCatalogueState(
            storeId: storeId,
            categories: _temporaryCategories,
            products: _temporaryProducts(storeId),
            quantities: const {},
          ),
        );

  static const List<GroceryProductCategory> _temporaryCategories = [
    GroceryProductCategory(
      id: 'popular',
      name: 'Popular',
      displayOrder: 1,
      isActive: true,
    ),
    GroceryProductCategory(
      id: 'offers',
      name: 'Offers',
      displayOrder: 2,
      isActive: true,
    ),
    GroceryProductCategory(
      id: 'fruit-vegetables',
      name: 'Fruits & Vegetables',
      displayOrder: 3,
      isActive: true,
    ),
    GroceryProductCategory(
      id: 'dairy-eggs',
      name: 'Dairy & Eggs',
      displayOrder: 4,
      isActive: true,
    ),
    GroceryProductCategory(
      id: 'bakery',
      name: 'Bakery',
      displayOrder: 5,
      isActive: true,
    ),
    GroceryProductCategory(
      id: 'beverages',
      name: 'Beverages',
      displayOrder: 6,
      isActive: true,
    ),
    GroceryProductCategory(
      id: 'snacks',
      name: 'Snacks',
      displayOrder: 7,
      isActive: true,
    ),
    GroceryProductCategory(
      id: 'pantry',
      name: 'Pantry',
      displayOrder: 8,
      isActive: true,
    ),
    GroceryProductCategory(
      id: 'household',
      name: 'Household',
      displayOrder: 9,
      isActive: true,
    ),
    GroceryProductCategory(
      id: 'personal-care',
      name: 'Personal Care',
      displayOrder: 10,
      isActive: true,
    ),
  ];

  static List<GroceryProduct> _temporaryProducts(
    String storeId,
  ) {
    // TODO(FOOD_GROCERY_API):
    // Replace with products returned by the selected store's API.
    return [
      GroceryProduct(
        id: 'product-001',
        storeId: storeId,
        categoryId: 'dairy-eggs',
        name: 'Fresh Milk',
        brand: 'Benna',
        description: 'Fresh full-fat milk produced in Malta',
        unitType: GroceryProductUnitType.fixedUnit,
        unitText: '1L',
        basePrice: 1.80,
        stockStatus: GroceryProductStockStatus.inStock,
        availableQuantity: 25,
        maximumQuantity: 10,
        hasVariants: false,
        isActive: true,
      ),
      GroceryProduct(
        id: 'product-002',
        storeId: storeId,
        categoryId: 'beverages',
        name: 'Coca-Cola',
        brand: 'Coca-Cola',
        description: 'Classic sparkling soft drink',
        unitType: GroceryProductUnitType.pack,
        unitText: '6 × 330ml',
        basePrice: 5.50,
        offerPrice: 4.95,
        offerText: '10% OFF',
        stockStatus: GroceryProductStockStatus.inStock,
        availableQuantity: 18,
        maximumQuantity: 6,
        hasVariants: true,
        isActive: true,
      ),
      GroceryProduct(
        id: 'product-003',
        storeId: storeId,
        categoryId: 'bakery',
        name: 'Maltese Bread',
        brand: 'Local Bakery',
        description: 'Traditional freshly baked Maltese bread',
        unitType: GroceryProductUnitType.piece,
        unitText: '1 loaf',
        basePrice: 1.25,
        stockStatus: GroceryProductStockStatus.lowStock,
        availableQuantity: 3,
        maximumQuantity: 5,
        hasVariants: false,
        isActive: true,
      ),
      GroceryProduct(
        id: 'product-004',
        storeId: storeId,
        categoryId: 'fruit-vegetables',
        name: 'Bananas',
        brand: 'Fresh Produce',
        description: 'Fresh bananas sold by approximate weight',
        unitType: GroceryProductUnitType.weight,
        unitText: '€2.40/kg',
        basePrice: 2.40,
        stockStatus: GroceryProductStockStatus.inStock,
        availableQuantity: 20,
        maximumQuantity: 5,
        hasVariants: true,
        isActive: true,
      ),
      GroceryProduct(
        id: 'product-005',
        storeId: storeId,
        categoryId: 'dairy-eggs',
        name: 'Free Range Eggs',
        brand: 'Farm Fresh',
        description: 'Locally sourced free-range eggs',
        unitType: GroceryProductUnitType.pack,
        unitText: '6 Pack',
        basePrice: 2.95,
        stockStatus: GroceryProductStockStatus.inStock,
        availableQuantity: 14,
        maximumQuantity: 6,
        hasVariants: false,
        isActive: true,
      ),
      GroceryProduct(
        id: 'product-006',
        storeId: storeId,
        categoryId: 'household',
        name: 'Laundry Detergent',
        brand: 'CleanHome',
        description: 'Concentrated laundry detergent',
        unitType: GroceryProductUnitType.fixedUnit,
        unitText: '1.5L',
        basePrice: 7.50,
        offerPrice: 6.50,
        offerText: 'SAVE €1',
        stockStatus: GroceryProductStockStatus.inStock,
        availableQuantity: 9,
        maximumQuantity: 4,
        hasVariants: false,
        isActive: true,
      ),
      GroceryProduct(
        id: 'product-007',
        storeId: storeId,
        categoryId: 'personal-care',
        name: 'Fresh Mint Toothpaste',
        brand: 'SmileCare',
        description: 'Daily protection fresh mint toothpaste',
        unitType: GroceryProductUnitType.fixedUnit,
        unitText: '100ml',
        basePrice: 2.75,
        stockStatus: GroceryProductStockStatus.outOfStock,
        availableQuantity: 0,
        maximumQuantity: 4,
        hasVariants: false,
        isActive: true,
      ),
      GroceryProduct(
        id: 'product-008',
        storeId: storeId,
        categoryId: 'snacks',
        name: 'Sea Salt Crisps',
        brand: 'Island Crunch',
        description: 'Crispy potato snacks with sea salt',
        unitType: GroceryProductUnitType.fixedUnit,
        unitText: '150g',
        basePrice: 2.20,
        stockStatus: GroceryProductStockStatus.inStock,
        availableQuantity: 16,
        maximumQuantity: 8,
        hasVariants: false,
        isActive: true,
      ),
    ];
  }

  void addSimpleProduct(GroceryProduct product) {
    if (!product.canAddDirectly) {
      return;
    }

    final currentQuantity = state.quantityFor(product.id);

    if (currentQuantity >= product.allowedQuantity) {
      return;
    }

    state = state.copyWith(
      quantities: {
        ...state.quantities,
        product.id: currentQuantity + 1,
      },
    );
  }

  void addProductFromDetails({
    required GroceryProduct product,
    required int quantity,
  }) {
    if (!product.isActive ||
        product.stockStatus == GroceryProductStockStatus.outOfStock ||
        quantity <= 0) {
      return;
    }

    final currentQuantity = state.quantityFor(product.id);

    final requestedQuantity = currentQuantity + quantity;

    state = state.copyWith(
      quantities: {
        ...state.quantities,
        product.id: requestedQuantity > product.allowedQuantity
            ? product.allowedQuantity
            : requestedQuantity,
      },
    );
  }

  void decreaseProduct(GroceryProduct product) {
    final currentQuantity = state.quantityFor(product.id);

    if (currentQuantity <= 0) {
      return;
    }

    final updatedQuantities = Map<String, int>.from(state.quantities);

    if (currentQuantity == 1) {
      updatedQuantities.remove(product.id);
    } else {
      updatedQuantities[product.id] = currentQuantity - 1;
    }

    state = state.copyWith(
      quantities: updatedQuantities,
    );
  }

  void refreshCatalogue() {
    // TODO(FOOD_GROCERY_API):
    // Re-fetch store status, products, prices and stock.
    state = state.copyWith(
      products: List<GroceryProduct>.from(state.products),
    );
  }

  void clearCartPreview() {
    state = state.copyWith(
      quantities: const {},
    );
  }
}
