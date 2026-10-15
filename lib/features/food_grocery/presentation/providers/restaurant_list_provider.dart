import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/food_restaurant.dart';

final restaurantListProvider =
    StateNotifierProvider<RestaurantListNotifier, List<FoodRestaurant>>(
  (ref) => RestaurantListNotifier(),
);

class RestaurantListNotifier extends StateNotifier<List<FoodRestaurant>> {
  RestaurantListNotifier() : super(_temporaryRestaurants);

  // TODO(FOOD_GROCERY_API):
  // Replace this temporary list with restaurants returned by the API.
  // The backend must filter restaurants using the selected delivery location.
  static const List<FoodRestaurant> _temporaryRestaurants = [
    FoodRestaurant(
      id: 'restaurant-001',
      supplierId: 'supplier-001',
      name: 'Harbour Pizza',
      cuisines: ['Italian', 'Pizza', 'Pasta'],
      rating: 4.6,
      ratingCount: 320,
      estimatedDeliveryTime: '25–35 min',
      deliveryFee: 2.50,
      distanceKm: 1.8,
      priceLevel: '€€',
      status: RestaurantOperationalStatus.open,
      isFavourite: false,
      hasVegetarianOptions: true,
      offerText: '20% OFF',
      promotionalTag: 'Featured',
    ),
    FoodRestaurant(
      id: 'restaurant-002',
      supplierId: 'supplier-002',
      name: 'Malta Burger House',
      cuisines: ['Burgers', 'Fast Food'],
      rating: 4.8,
      ratingCount: 482,
      estimatedDeliveryTime: '20–30 min',
      deliveryFee: 0,
      distanceKm: 2.1,
      priceLevel: '€€',
      status: RestaurantOperationalStatus.busy,
      isFavourite: true,
      hasVegetarianOptions: true,
      offerText: 'Free delivery',
      promotionalTag: 'Popular',
    ),
    FoodRestaurant(
      id: 'restaurant-003',
      supplierId: 'supplier-003',
      name: 'Mediterranean Kitchen',
      cuisines: ['Mediterranean', 'Healthy'],
      rating: 4.7,
      ratingCount: 218,
      estimatedDeliveryTime: '30–40 min',
      deliveryFee: 1.50,
      distanceKm: 2.6,
      priceLevel: '€€€',
      status: RestaurantOperationalStatus.closingSoon,
      isFavourite: false,
      hasVegetarianOptions: true,
      promotionalTag: 'Recommended',
    ),
    FoodRestaurant(
      id: 'restaurant-004',
      supplierId: 'supplier-004',
      name: 'Spice of India',
      cuisines: ['Indian', 'Asian'],
      rating: 4.5,
      ratingCount: 176,
      estimatedDeliveryTime: '35–45 min',
      deliveryFee: 2.00,
      distanceKm: 3.2,
      priceLevel: '€€',
      status: RestaurantOperationalStatus.open,
      isFavourite: false,
      hasVegetarianOptions: true,
      offerText: '10% OFF',
    ),
    FoodRestaurant(
      id: 'restaurant-005',
      supplierId: 'supplier-005',
      name: 'Sweet Corner',
      cuisines: ['Desserts', 'Bakery'],
      rating: 4.4,
      ratingCount: 95,
      estimatedDeliveryTime: '20–30 min',
      deliveryFee: 1.00,
      distanceKm: 1.2,
      priceLevel: '€',
      status: RestaurantOperationalStatus.closed,
      isFavourite: false,
      hasVegetarianOptions: true,
    ),
    FoodRestaurant(
      id: 'restaurant-006',
      supplierId: 'supplier-006',
      name: 'Asian Bowl',
      cuisines: ['Asian', 'Chinese'],
      rating: 4.3,
      ratingCount: 142,
      estimatedDeliveryTime: '30–45 min',
      deliveryFee: 2.75,
      distanceKm: 4.0,
      priceLevel: '€€',
      status: RestaurantOperationalStatus.temporarilyUnavailable,
      isFavourite: false,
      hasVegetarianOptions: false,
    ),
  ];

  void toggleFavourite(String restaurantId) {
    state = [
      for (final restaurant in state)
        if (restaurant.id == restaurantId)
          restaurant.copyWith(
            isFavourite: !restaurant.isFavourite,
          )
        else
          restaurant,
    ];
  }

  void refreshRestaurants() {
    // TODO(FOOD_GROCERY_API):
    // Call the Restaurant Listing API using the current delivery location,
    // filters, sorting and search query.
    state = List<FoodRestaurant>.from(state);
  }
}
