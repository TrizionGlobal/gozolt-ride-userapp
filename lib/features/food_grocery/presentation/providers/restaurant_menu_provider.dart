import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/restaurant_menu.dart';

final restaurantMenuProvider = StateNotifierProvider.family<
    RestaurantMenuNotifier, RestaurantMenuState, String>(
  (ref, restaurantId) {
    return RestaurantMenuNotifier(restaurantId);
  },
);

class RestaurantMenuState {
  const RestaurantMenuState({
    required this.restaurantId,
    required this.categories,
    required this.items,
    required this.quantities,
  });

  final String restaurantId;
  final List<RestaurantMenuCategory> categories;
  final List<RestaurantMenuItem> items;
  final Map<String, int> quantities;

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
  }) {
    return RestaurantMenuState(
      restaurantId: restaurantId ?? this.restaurantId,
      categories: categories ?? this.categories,
      items: items ?? this.items,
      quantities: quantities ?? this.quantities,
    );
  }
}

class RestaurantMenuNotifier extends StateNotifier<RestaurantMenuState> {
  RestaurantMenuNotifier(String restaurantId)
      : super(
          RestaurantMenuState(
            restaurantId: restaurantId,
            categories: _temporaryCategories,
            items: _temporaryItems(
              restaurantId,
            ),
            quantities: const {},
          ),
        );

  static const List<RestaurantMenuCategory> _temporaryCategories = [
    RestaurantMenuCategory(
      id: 'popular',
      name: 'Popular',
      displayOrder: 1,
      isActive: true,
    ),
    RestaurantMenuCategory(
      id: 'offers',
      name: 'Offers',
      displayOrder: 2,
      isActive: true,
    ),
    RestaurantMenuCategory(
      id: 'pizza',
      name: 'Pizza',
      displayOrder: 3,
      isActive: true,
    ),
    RestaurantMenuCategory(
      id: 'pasta',
      name: 'Pasta',
      displayOrder: 4,
      isActive: true,
    ),
    RestaurantMenuCategory(
      id: 'starters',
      name: 'Starters',
      displayOrder: 5,
      isActive: true,
    ),
    RestaurantMenuCategory(
      id: 'desserts',
      name: 'Desserts',
      displayOrder: 6,
      isActive: true,
    ),
    RestaurantMenuCategory(
      id: 'drinks',
      name: 'Drinks',
      displayOrder: 7,
      isActive: true,
    ),
  ];

  static List<RestaurantMenuItem> _temporaryItems(
    String restaurantId,
  ) {
    // TODO(FOOD_GROCERY_API):
    // Replace these values with menu categories and items returned
    // by the selected restaurant's API.
    return [
      RestaurantMenuItem(
        id: 'item-001',
        restaurantId: restaurantId,
        categoryId: 'pizza',
        name: 'Margherita Pizza',
        description: 'Tomato sauce, mozzarella and fresh basil',
        basePrice: 10.50,
        isAvailable: true,
        isPopular: true,
        isCustomizable: true,
        dietaryTags: [
          FoodDietaryTag.vegetarian,
        ],
        maximumQuantity: 10,
      ),
      RestaurantMenuItem(
        id: 'item-002',
        restaurantId: restaurantId,
        categoryId: 'pizza',
        name: 'Pepperoni Pizza',
        description: 'Tomato sauce, mozzarella and pepperoni',
        basePrice: 13.00,
        offerPrice: 11.00,
        offerText: '15% OFF',
        isAvailable: true,
        isPopular: true,
        isCustomizable: true,
        dietaryTags: [
          FoodDietaryTag.halal,
        ],
        maximumQuantity: 8,
      ),
      RestaurantMenuItem(
        id: 'item-003',
        restaurantId: restaurantId,
        categoryId: 'pasta',
        name: 'Creamy Chicken Pasta',
        description: 'Penne pasta with chicken and creamy sauce',
        basePrice: 12.50,
        isAvailable: true,
        isPopular: true,
        isCustomizable: false,
        dietaryTags: [
          FoodDietaryTag.halal,
        ],
        maximumQuantity: 6,
      ),
      RestaurantMenuItem(
        id: 'item-004',
        restaurantId: restaurantId,
        categoryId: 'starters',
        name: 'Garlic Bread',
        description: 'Oven-baked bread with garlic and herbs',
        basePrice: 4.50,
        isAvailable: true,
        isPopular: false,
        isCustomizable: false,
        dietaryTags: [
          FoodDietaryTag.vegetarian,
        ],
        maximumQuantity: 10,
      ),
      RestaurantMenuItem(
        id: 'item-005',
        restaurantId: restaurantId,
        categoryId: 'desserts',
        name: 'Chocolate Brownie',
        description: 'Warm chocolate brownie with cocoa sauce',
        basePrice: 6.00,
        isAvailable: false,
        isPopular: false,
        isCustomizable: false,
        dietaryTags: [
          FoodDietaryTag.vegetarian,
        ],
        maximumQuantity: 5,
      ),
      RestaurantMenuItem(
        id: 'item-006',
        restaurantId: restaurantId,
        categoryId: 'drinks',
        name: 'Fresh Orange Juice',
        description: 'Freshly prepared orange juice',
        basePrice: 3.50,
        isAvailable: true,
        isPopular: false,
        isCustomizable: false,
        dietaryTags: [
          FoodDietaryTag.vegan,
          FoodDietaryTag.glutenFree,
        ],
        maximumQuantity: 8,
      ),
    ];
  }

  void addSimpleItem(RestaurantMenuItem item) {
    if (!item.isAvailable || item.isCustomizable) {
      return;
    }

    final currentQuantity = state.quantityFor(item.id);

    if (currentQuantity >= item.maximumQuantity) {
      return;
    }

    state = state.copyWith(
      quantities: {
        ...state.quantities,
        item.id: currentQuantity + 1,
      },
    );
  }

  void addCustomizedItem({
    required RestaurantMenuItem item,
    int quantity = 1,
  }) {
    if (!item.isAvailable || quantity <= 0) {
      return;
    }

    final currentQuantity = state.quantityFor(item.id);
    final nextQuantity = currentQuantity + quantity;

    state = state.copyWith(
      quantities: {
        ...state.quantities,
        item.id: nextQuantity > item.maximumQuantity
            ? item.maximumQuantity
            : nextQuantity,
      },
    );
  }

  void decreaseItem(RestaurantMenuItem item) {
    final currentQuantity = state.quantityFor(item.id);

    if (currentQuantity <= 0) {
      return;
    }

    final updatedQuantities = Map<String, int>.from(state.quantities);

    if (currentQuantity == 1) {
      updatedQuantities.remove(item.id);
    } else {
      updatedQuantities[item.id] = currentQuantity - 1;
    }

    state = state.copyWith(
      quantities: updatedQuantities,
    );
  }

  void clearCartPreview() {
    state = state.copyWith(
      quantities: const {},
    );
  }

  void refreshMenu() {
    // TODO(FOOD_GROCERY_API):
    // Re-fetch restaurant operational status, categories,
    // item availability and current prices.
    state = state.copyWith(
      items: List<RestaurantMenuItem>.from(state.items),
    );
  }
}
