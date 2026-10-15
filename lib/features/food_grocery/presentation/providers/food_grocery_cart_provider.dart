import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/food_grocery_cart.dart';

enum CartAddResult {
  added,
  updated,
  differentSupplier,
  outOfStock,
}

final foodGroceryCartProvider =
    StateNotifierProvider<FoodGroceryCartNotifier, FoodGroceryCartState>(
  (ref) => FoodGroceryCartNotifier(),
);

class FoodGroceryCartNotifier extends StateNotifier<FoodGroceryCartState> {
  FoodGroceryCartNotifier() : super(const FoodGroceryCartState());

  CartAddResult addItem(FoodGroceryCartItem item) {
    if (item.quantity <= 0) {
      return CartAddResult.outOfStock;
    }

    if (item.maximumQuantity != null && item.quantity > item.maximumQuantity!) {
      return CartAddResult.outOfStock;
    }

    if (state.isNotEmpty && state.supplierId != item.supplierId) {
      return CartAddResult.differentSupplier;
    }

    final existingIndex = state.items.indexWhere(
      (existingItem) => existingItem.lineId == item.lineId,
    );

    if (existingIndex == -1) {
      state = state.copyWith(
        items: [
          ...state.items,
          item,
        ],
      );

      return CartAddResult.added;
    }

    final existingItem = state.items[existingIndex];

    final updatedQuantity = existingItem.quantity + item.quantity;

    if (existingItem.maximumQuantity != null &&
        updatedQuantity > existingItem.maximumQuantity!) {
      return CartAddResult.outOfStock;
    }

    final updatedItems = List<FoodGroceryCartItem>.from(state.items);

    updatedItems[existingIndex] = existingItem.copyWith(
      quantity: updatedQuantity,
      instructions: item.instructions ?? existingItem.instructions,
    );

    state = state.copyWith(items: updatedItems);

    return CartAddResult.updated;
  }

  void increaseQuantity(String lineId) {
    final index = state.items.indexWhere(
      (item) => item.lineId == lineId,
    );

    if (index == -1) return;

    final item = state.items[index];
    final nextQuantity = item.quantity + 1;

    if (item.maximumQuantity != null && nextQuantity > item.maximumQuantity!) {
      return;
    }

    final updatedItems = List<FoodGroceryCartItem>.from(state.items);

    updatedItems[index] = item.copyWith(
      quantity: nextQuantity,
    );

    state = state.copyWith(items: updatedItems);
  }

  void decreaseQuantity(String lineId) {
    final index = state.items.indexWhere(
      (item) => item.lineId == lineId,
    );

    if (index == -1) return;

    final item = state.items[index];

    if (item.quantity <= 1) {
      removeItem(lineId);
      return;
    }

    final updatedItems = List<FoodGroceryCartItem>.from(state.items);

    updatedItems[index] = item.copyWith(
      quantity: item.quantity - 1,
    );

    state = state.copyWith(items: updatedItems);
  }

  void updateQuantity(
    String lineId,
    int quantity,
  ) {
    if (quantity <= 0) {
      removeItem(lineId);
      return;
    }

    final index = state.items.indexWhere(
      (item) => item.lineId == lineId,
    );

    if (index == -1) return;

    final item = state.items[index];

    final safeQuantity = item.maximumQuantity == null
        ? quantity
        : quantity.clamp(
            1,
            item.maximumQuantity!,
          );

    final updatedItems = List<FoodGroceryCartItem>.from(state.items);

    updatedItems[index] = item.copyWith(
      quantity: safeQuantity,
    );

    state = state.copyWith(items: updatedItems);
  }

  void removeItem(String lineId) {
    state = state.copyWith(
      items: state.items.where((item) => item.lineId != lineId).toList(),
    );
  }

  void replaceCartWith(FoodGroceryCartItem item) {
    state = FoodGroceryCartState(
      items: [item],
    );
  }

  void updateCharges({
    required double deliveryFee,
    required double serviceFee,
    double discount = 0,
  }) {
    state = state.copyWith(
      deliveryFee: deliveryFee,
      serviceFee: serviceFee,
      discount: discount,
    );
  }

  void clearCart() {
    state = const FoodGroceryCartState();
  }
}
