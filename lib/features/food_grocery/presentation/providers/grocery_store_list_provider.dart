import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/grocery_store.dart';

final groceryStoreListProvider =
    StateNotifierProvider<GroceryStoreListNotifier, List<GroceryStore>>(
  (ref) => GroceryStoreListNotifier(),
);

class GroceryStoreListNotifier extends StateNotifier<List<GroceryStore>> {
  GroceryStoreListNotifier() : super(_temporaryGroceryStores);

  // TODO(FOOD_GROCERY_API):
  // Replace these temporary stores with eligible stores returned
  // by the backend for the customer's selected delivery location.
  static const List<GroceryStore> _temporaryGroceryStores = [
    GroceryStore(
      id: 'store-001',
      supplierId: 'grocery-supplier-001',
      name: 'FreshMart Sliema',
      storeType: 'Supermarket',
      mainCategories: [
        'Fresh Produce',
        'Dairy',
        'Household',
      ],
      rating: 4.7,
      ratingCount: 1240,
      estimatedDeliveryTime: '25–35 min',
      deliveryFee: 2.50,
      distanceKm: 1.2,
      minimumOrder: 20,
      status: GroceryStoreOperationalStatus.open,
      isFavourite: true,
      matchingProductNames: [
        'Milk',
        'Bread',
        'Eggs',
        'Vegetables',
        'Coca-Cola',
        'Cleaning Products',
      ],
      offerText: '10% OFF above €40',
      promotionalTag: 'Featured',
    ),
    GroceryStore(
      id: 'store-002',
      supplierId: 'grocery-supplier-002',
      name: 'Daily Needs',
      storeType: 'Convenience Store',
      mainCategories: [
        'Bakery',
        'Beverages',
        'Personal Care',
      ],
      rating: 4.5,
      ratingCount: 450,
      estimatedDeliveryTime: '20–30 min',
      deliveryFee: 0,
      distanceKm: 0.9,
      minimumOrder: 15,
      status: GroceryStoreOperationalStatus.busy,
      isFavourite: false,
      matchingProductNames: [
        'Milk',
        'Bread',
        'Water',
        'Juice',
        'Shampoo',
        'Snacks',
      ],
      offerText: 'Free Delivery',
      promotionalTag: 'Popular',
    ),
    GroceryStore(
      id: 'store-003',
      supplierId: 'grocery-supplier-003',
      name: 'Green Basket Malta',
      storeType: 'Organic Store',
      mainCategories: [
        'Fruits & Vegetables',
        'Organic',
        'Healthy',
      ],
      rating: 4.8,
      ratingCount: 328,
      estimatedDeliveryTime: '30–40 min',
      deliveryFee: 1.50,
      distanceKm: 2.4,
      minimumOrder: 18,
      status: GroceryStoreOperationalStatus.closingSoon,
      isFavourite: false,
      matchingProductNames: [
        'Organic Milk',
        'Fresh Vegetables',
        'Fruits',
        'Organic Bread',
        'Healthy Snacks',
      ],
      promotionalTag: 'GO Coins Bonus',
    ),
    GroceryStore(
      id: 'store-004',
      supplierId: 'grocery-supplier-004',
      name: 'Malta Family Market',
      storeType: 'Local Grocery',
      mainCategories: [
        'Meat & Fish',
        'Dairy',
        'Bakery',
      ],
      rating: 4.4,
      ratingCount: 286,
      estimatedDeliveryTime: '35–45 min',
      deliveryFee: 2.00,
      distanceKm: 3.1,
      minimumOrder: 25,
      status: GroceryStoreOperationalStatus.open,
      isFavourite: false,
      matchingProductNames: [
        'Chicken',
        'Fish',
        'Cheese',
        'Bread',
        'Yoghurt',
      ],
      offerText: '€5 OFF above €40',
    ),
    GroceryStore(
      id: 'store-005',
      supplierId: 'grocery-supplier-005',
      name: 'Harbour Mini Market',
      storeType: 'Convenience Store',
      mainCategories: [
        'Beverages',
        'Snacks',
        'Household',
      ],
      rating: 4.2,
      ratingCount: 174,
      estimatedDeliveryTime: '25–35 min',
      deliveryFee: 1.00,
      distanceKm: 1.7,
      minimumOrder: 10,
      status: GroceryStoreOperationalStatus.closed,
      isFavourite: false,
      matchingProductNames: [
        'Water',
        'Coca-Cola',
        'Biscuits',
        'Cleaning Products',
      ],
    ),
    GroceryStore(
      id: 'store-006',
      supplierId: 'grocery-supplier-006',
      name: 'Home Essentials',
      storeType: 'Specialty Store',
      mainCategories: [
        'Household',
        'Cleaning Products',
        'Personal Care',
      ],
      rating: 4.3,
      ratingCount: 112,
      estimatedDeliveryTime: '40–50 min',
      deliveryFee: 3.00,
      distanceKm: 4.2,
      minimumOrder: 20,
      status: GroceryStoreOperationalStatus.temporarilyUnavailable,
      isFavourite: false,
      matchingProductNames: [
        'Detergent',
        'Dish Soap',
        'Shampoo',
        'Toilet Paper',
        'Cleaning Products',
      ],
    ),
  ];

  void toggleFavourite(String storeId) {
    state = [
      for (final store in state)
        if (store.id == storeId)
          store.copyWith(
            isFavourite: !store.isFavourite,
          )
        else
          store,
    ];
  }

  void refreshStores() {
    // TODO(FOOD_GROCERY_API):
    // Fetch stores using the selected location, search query,
    // filters and sort selection.
    state = List<GroceryStore>.from(state);
  }
}
