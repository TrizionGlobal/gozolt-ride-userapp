import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/food_grocery_remote_datasource.dart';
import '../../data/models/food_item_customization.dart';
import '../../data/models/restaurant_menu.dart';

final restaurantMenuProvider = StateNotifierProvider.family<
    RestaurantMenuNotifier, RestaurantMenuState, String>(
  (ref, restaurantId) {
    return RestaurantMenuNotifier(ref, restaurantId);
  },
);

class RestaurantMenuState {
  const RestaurantMenuState({
    required this.restaurantId,
    required this.categories,
    required this.items,
    required this.quantities,
    this.modifiersByItemId = const {},
    this.isLoading = false,
    this.errorMessage,
  });

  final String restaurantId;
  final List<RestaurantMenuCategory> categories;
  final List<RestaurantMenuItem> items;
  final Map<String, int> quantities;
  final Map<String, List<FoodModifierGroup>> modifiersByItemId;
  final bool isLoading;
  final String? errorMessage;

  int quantityFor(String itemId) {
    return quantities[itemId] ?? 0;
  }

  int get cartItemCount {
    return quantities.values.fold(
      0,
      (total, quantity) => total + quantity,
    );
  }

  double get cartSubtotal {
    var subtotal = 0.0;

    for (final item in items) {
      final quantity = quantityFor(item.id);
      if (quantity > 0) {
        subtotal += item.currentPrice * quantity;
      }
    }

    return subtotal;
  }

  RestaurantMenuState copyWith({
    String? restaurantId,
    List<RestaurantMenuCategory>? categories,
    List<RestaurantMenuItem>? items,
    Map<String, int>? quantities,
    Map<String, List<FoodModifierGroup>>? modifiersByItemId,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RestaurantMenuState(
      restaurantId: restaurantId ?? this.restaurantId,
      categories: categories ?? this.categories,
      items: items ?? this.items,
      quantities: quantities ?? this.quantities,
      modifiersByItemId: modifiersByItemId ?? this.modifiersByItemId,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class RestaurantMenuNotifier extends StateNotifier<RestaurantMenuState> {
  RestaurantMenuNotifier(this._ref, String restaurantId)
      : super(
          RestaurantMenuState(
            restaurantId: restaurantId,
            categories: const [],
            items: const [],
            quantities: const {},
            isLoading: true,
          ),
        ) {
    Future.microtask(() => loadMenu());
  }

  final Ref _ref;

  Future<void> loadMenu() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final ds = _ref.read(foodGroceryRemoteDatasourceProvider);
      final menu = await ds.getRestaurantMenu(state.restaurantId);
      if (!mounted) return;
      state = state.copyWith(
        categories: menu.categories,
        items: menu.items,
        modifiersByItemId: menu.modifiersByItemId,
        isLoading: false,
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to load menu. Please try again.',
      );
    }
  }

  void incrementItem(String itemId) {
    final item = state.items.firstWhere(
      (element) => element.id == itemId,
      orElse: () => const RestaurantMenuItem(
        id: '',
        restaurantId: '',
        categoryId: '',
        name: '',
        description: '',
        basePrice: 0,
        isAvailable: false,
        isPopular: false,
        isCustomizable: false,
        dietaryTags: [],
        maximumQuantity: 0,
      ),
    );

    if (item.id.isEmpty || !item.isAvailable) {
      return;
    }

    final current = state.quantityFor(itemId);
    if (current >= item.maximumQuantity) {
      return;
    }

    state = state.copyWith(
      quantities: {
        ...state.quantities,
        itemId: current + 1,
      },
    );
  }

  void decrementItem(String itemId) {
    final current = state.quantityFor(itemId);
    if (current <= 0) {
      return;
    }

    final updated = Map<String, int>.from(state.quantities);
    if (current == 1) {
      updated.remove(itemId);
    } else {
      updated[itemId] = current - 1;
    }

    state = state.copyWith(quantities: updated);
  }

  void setQuantity(String itemId, int quantity) {
    final updated = Map<String, int>.from(state.quantities);
    if (quantity <= 0) {
      updated.remove(itemId);
    } else {
      updated[itemId] = quantity;
    }
    state = state.copyWith(quantities: updated);
  }

  Future<void> refreshMenu() async => loadMenu();

  void clearCart() {
    state = state.copyWith(quantities: const {});
  }
}
