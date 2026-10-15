import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/grocery_catalogue.dart';
import '../../data/models/grocery_product_details.dart';

final groceryProductDetailsProvider = StateNotifierProvider.family<
    GroceryProductDetailsNotifier, GroceryProductDetailsState, GroceryProduct>(
  (ref, product) {
    return GroceryProductDetailsNotifier(product);
  },
);

class GroceryProductDetailsState {
  const GroceryProductDetailsState({
    required this.product,
    required this.selectionOptions,
    required this.selectedOptionId,
    required this.quantity,
    required this.isFavourite,
  });

  final GroceryProduct product;
  final List<GroceryProductSelectionOption> selectionOptions;
  final String? selectedOptionId;
  final int quantity;
  final bool isFavourite;

  bool get requiresSelection {
    return product.hasVariants ||
        product.unitType == GroceryProductUnitType.weight;
  }

  GroceryProductSelectionOption? get selectedOption {
    if (selectedOptionId == null) {
      return null;
    }

    for (final option in selectionOptions) {
      if (option.id == selectedOptionId) {
        return option;
      }
    }

    return null;
  }

  bool get selectionComplete {
    if (!requiresSelection) {
      return true;
    }

    return selectedOption != null && selectedOption!.isAvailable;
  }

  double get selectedUnitPrice {
    return selectedOption?.price ?? product.currentPrice;
  }

  double? get selectedOriginalPrice {
    return selectedOption?.originalPrice ??
        (product.hasOffer ? product.basePrice : null);
  }

  int get allowedQuantity {
    final option = selectedOption;

    if (option != null) {
      return option.allowedQuantity;
    }

    return product.allowedQuantity;
  }

  double get totalPrice {
    return selectedUnitPrice * quantity;
  }

  String get selectedUnitText {
    return selectedOption?.unitText ?? product.unitText;
  }

  GroceryProductDetailsState copyWith({
    GroceryProduct? product,
    List<GroceryProductSelectionOption>? selectionOptions,
    String? selectedOptionId,
    bool clearSelectedOption = false,
    int? quantity,
    bool? isFavourite,
  }) {
    return GroceryProductDetailsState(
      product: product ?? this.product,
      selectionOptions: selectionOptions ?? this.selectionOptions,
      selectedOptionId: clearSelectedOption
          ? null
          : selectedOptionId ?? this.selectedOptionId,
      quantity: quantity ?? this.quantity,
      isFavourite: isFavourite ?? this.isFavourite,
    );
  }
}

class GroceryProductDetailsNotifier
    extends StateNotifier<GroceryProductDetailsState> {
  GroceryProductDetailsNotifier(
    GroceryProduct product,
  ) : super(
          GroceryProductDetailsState(
            product: product,
            selectionOptions: _optionsFor(product),
            selectedOptionId: null,
            quantity: 1,
            isFavourite: false,
          ),
        );

  static List<GroceryProductSelectionOption> _optionsFor(
    GroceryProduct product,
  ) {
    // TODO(FOOD_GROCERY_API):
    // Replace these temporary variants and weight options
    // with product-specific backend data.

    if (product.unitType == GroceryProductUnitType.weight) {
      final pricePerKg = product.currentPrice;

      return [
        GroceryProductSelectionOption(
          id: '${product.id}-250g',
          name: 'Approx. 250g',
          unitText: '250g',
          price: pricePerKg * 0.25,
          stockStatus: GroceryProductStockStatus.inStock,
          availableQuantity: 10,
          maximumQuantity: 5,
          isActive: true,
          isEstimatedWeight: true,
        ),
        GroceryProductSelectionOption(
          id: '${product.id}-500g',
          name: 'Approx. 500g',
          unitText: '500g',
          price: pricePerKg * 0.50,
          stockStatus: GroceryProductStockStatus.inStock,
          availableQuantity: 8,
          maximumQuantity: 5,
          isActive: true,
          isEstimatedWeight: true,
        ),
        GroceryProductSelectionOption(
          id: '${product.id}-1kg',
          name: 'Approx. 1kg',
          unitText: '1kg',
          price: pricePerKg,
          stockStatus: GroceryProductStockStatus.lowStock,
          availableQuantity: 3,
          maximumQuantity: 3,
          isActive: true,
          isEstimatedWeight: true,
        ),
      ];
    }

    if (product.hasVariants) {
      return [
        GroceryProductSelectionOption(
          id: '${product.id}-330ml',
          name: '330ml Can',
          unitText: '330ml',
          price: 1.20,
          stockStatus: GroceryProductStockStatus.inStock,
          availableQuantity: 20,
          maximumQuantity: 10,
          isActive: true,
        ),
        GroceryProductSelectionOption(
          id: '${product.id}-500ml',
          name: '500ml Bottle',
          unitText: '500ml',
          price: 1.75,
          stockStatus: GroceryProductStockStatus.inStock,
          availableQuantity: 15,
          maximumQuantity: 8,
          isActive: true,
        ),
        GroceryProductSelectionOption(
          id: '${product.id}-1-5l',
          name: '1.5L Bottle',
          unitText: '1.5L',
          price: 2.50,
          originalPrice: 2.80,
          stockStatus: GroceryProductStockStatus.lowStock,
          availableQuantity: 2,
          maximumQuantity: 4,
          isActive: true,
        ),
        GroceryProductSelectionOption(
          id: '${product.id}-6-pack',
          name: '6 Pack',
          unitText: '6 × 330ml',
          price: 4.95,
          originalPrice: 5.50,
          stockStatus: GroceryProductStockStatus.inStock,
          availableQuantity: 12,
          maximumQuantity: 6,
          isActive: true,
        ),
        GroceryProductSelectionOption(
          id: '${product.id}-12-pack',
          name: '12 Pack',
          unitText: '12 × 330ml',
          price: 8.90,
          stockStatus: GroceryProductStockStatus.outOfStock,
          availableQuantity: 0,
          maximumQuantity: 3,
          isActive: true,
        ),
      ];
    }

    return const [];
  }

  String? selectOption(
    GroceryProductSelectionOption option,
  ) {
    if (!option.isAvailable) {
      return '${option.name} is currently unavailable';
    }

    state = state.copyWith(
      selectedOptionId: option.id,
      quantity: 1,
    );

    return null;
  }

  void increaseQuantity() {
    if (!state.selectionComplete) {
      return;
    }

    if (state.quantity >= state.allowedQuantity) {
      return;
    }

    state = state.copyWith(
      quantity: state.quantity + 1,
    );
  }

  void decreaseQuantity() {
    if (state.quantity <= 1) {
      return;
    }

    state = state.copyWith(
      quantity: state.quantity - 1,
    );
  }

  void toggleFavourite() {
    state = state.copyWith(
      isFavourite: !state.isFavourite,
    );
  }

  void reset() {
    state = state.copyWith(
      clearSelectedOption: true,
      quantity: 1,
    );
  }
}
