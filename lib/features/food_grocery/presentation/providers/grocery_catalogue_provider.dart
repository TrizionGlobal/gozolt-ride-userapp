import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/food_grocery_remote_datasource.dart';
import '../../data/models/grocery_catalogue.dart';
import '../../data/models/grocery_product_details.dart';

final groceryCatalogueProvider = StateNotifierProvider.family<
    GroceryCatalogueNotifier, GroceryCatalogueState, String>(
  (ref, storeId) {
    return GroceryCatalogueNotifier(ref, storeId);
  },
);

class GroceryCatalogueState {
  const GroceryCatalogueState({
    required this.storeId,
    required this.categories,
    required this.products,
    required this.quantities,
    this.variantsByProductId = const {},
    this.isLoading = false,
    this.errorMessage,
  });

  final String storeId;
  final List<GroceryProductCategory> categories;
  final List<GroceryProduct> products;
  final Map<String, int> quantities;
  final Map<String, List<GroceryProductSelectionOption>> variantsByProductId;
  final bool isLoading;
  final String? errorMessage;

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
    Map<String, List<GroceryProductSelectionOption>>? variantsByProductId,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return GroceryCatalogueState(
      storeId: storeId ?? this.storeId,
      categories: categories ?? this.categories,
      products: products ?? this.products,
      quantities: quantities ?? this.quantities,
      variantsByProductId: variantsByProductId ?? this.variantsByProductId,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class GroceryCatalogueNotifier extends StateNotifier<GroceryCatalogueState> {
  GroceryCatalogueNotifier(this._ref, String storeId)
      : super(
          GroceryCatalogueState(
            storeId: storeId,
            categories: const [],
            products: const [],
            quantities: const {},
            isLoading: true,
          ),
        ) {
    Future.microtask(() => loadCatalogue());
  }

  final Ref _ref;

  Future<void> loadCatalogue() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final ds = _ref.read(foodGroceryRemoteDatasourceProvider);
      final catalogue = await ds.getStoreCatalogue(state.storeId);
      if (!mounted) return;
      state = state.copyWith(
        categories: catalogue.categories,
        products: catalogue.products,
        variantsByProductId: catalogue.variantsByProductId,
        isLoading: false,
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to load store catalogue. Please try again.',
      );
    }
  }

  void incrementProduct(String productId) {
    final product = state.products.firstWhere(
      (element) => element.id == productId,
      orElse: () => const GroceryProduct(
        id: '',
        storeId: '',
        categoryId: '',
        name: '',
        brand: '',
        description: '',
        unitType: GroceryProductUnitType.fixedUnit,
        unitText: '',
        basePrice: 0,
        stockStatus: GroceryProductStockStatus.outOfStock,
        availableQuantity: 0,
        maximumQuantity: 0,
        hasVariants: false,
        isActive: false,
      ),
    );

    if (product.id.isEmpty || !product.canAddDirectly) {
      return;
    }

    final current = state.quantityFor(productId);
    if (current >= product.allowedQuantity) {
      return;
    }

    state = state.copyWith(
      quantities: {
        ...state.quantities,
        productId: current + 1,
      },
    );
  }

  void decrementProduct(String productId) {
    final current = state.quantityFor(productId);
    if (current <= 0) {
      return;
    }

    final updated = Map<String, int>.from(state.quantities);
    if (current == 1) {
      updated.remove(productId);
    } else {
      updated[productId] = current - 1;
    }

    state = state.copyWith(quantities: updated);
  }

  Future<void> refreshCatalogue() async => loadCatalogue();

  void addSimpleProduct(GroceryProduct product) => incrementProduct(product.id);

  void decreaseProduct(dynamic productOrId) {
    if (productOrId is GroceryProduct) {
      decrementProduct(productOrId.id);
    } else if (productOrId is String) {
      decrementProduct(productOrId);
    }
  }

  void clearQuantities() {
    state = state.copyWith(quantities: const {});
  }
}
