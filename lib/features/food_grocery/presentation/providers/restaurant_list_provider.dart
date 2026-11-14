import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/food_grocery_remote_datasource.dart';
import '../../data/models/food_restaurant.dart';
import 'food_grocery_delivery_provider.dart';

final restaurantListLoadingProvider = StateProvider<bool>((ref) => false);
final restaurantListErrorProvider = StateProvider<String?>((ref) => null);

final restaurantListProvider =
    StateNotifierProvider<RestaurantListNotifier, List<FoodRestaurant>>(
  (ref) => RestaurantListNotifier(ref),
);

class RestaurantListNotifier extends StateNotifier<List<FoodRestaurant>> {
  RestaurantListNotifier(this._ref) : super(const []) {
    Future.microtask(() => refreshRestaurants());
  }

  final Ref _ref;
  bool _isFetching = false;

  Future<void> refreshRestaurants({
    String? search,
    String? category,
    String? sort,
    double? minRating,
    bool? freeDelivery,
    bool? hasOffers,
    bool? vegetarian,
    bool? openNow,
    int? maxMinutes,
  }) async {
    if (_isFetching) return;
    _isFetching = true;
    _ref.read(restaurantListLoadingProvider.notifier).state = true;
    _ref.read(restaurantListErrorProvider.notifier).state = null;

    try {
      final delivery = _ref.read(foodGroceryDeliveryProvider);
      final selected = delivery.selectedAddress;
      final ds = _ref.read(foodGroceryRemoteDatasourceProvider);
      final restaurants = await ds.getRestaurants(
        search: search,
        category: category,
        sort: sort,
        lat: selected?.latitude,
        lng: selected?.longitude,
        minRating: minRating,
        freeDelivery: freeDelivery,
        hasOffers: hasOffers,
        vegetarian: vegetarian,
        openNow: openNow,
        maxMinutes: maxMinutes,
      );
      if (mounted) {
        state = restaurants;
      }
    } catch (e) {
      if (mounted) {
        _ref.read(restaurantListErrorProvider.notifier).state =
            'Unable to load restaurants. Pull down or tap Retry.';
      }
    } finally {
      _isFetching = false;
      if (mounted) {
        _ref.read(restaurantListLoadingProvider.notifier).state = false;
      }
    }
  }

  Future<void> toggleFavourite(String restaurantId) async {
    final previous = state;
    state = [
      for (final restaurant in state)
        if (restaurant.id == restaurantId)
          restaurant.copyWith(isFavourite: !restaurant.isFavourite)
        else
          restaurant,
    ];

    try {
      final ds = _ref.read(foodGroceryRemoteDatasourceProvider);
      await ds.toggleFavourite(restaurantId);
    } catch (_) {
      if (mounted) {
        state = previous;
      }
    }
  }
}
