import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/food_grocery_remote_datasource.dart';
import '../../data/models/grocery_store.dart';
import 'food_grocery_delivery_provider.dart';

final groceryStoreListLoadingProvider = StateProvider<bool>((ref) => false);
final groceryStoreListErrorProvider = StateProvider<String?>((ref) => null);

final groceryStoreListProvider =
    StateNotifierProvider<GroceryStoreListNotifier, List<GroceryStore>>(
  (ref) => GroceryStoreListNotifier(ref),
);

class GroceryStoreListNotifier extends StateNotifier<List<GroceryStore>> {
  GroceryStoreListNotifier(this._ref) : super(const []) {
    Future.microtask(() => refreshStores());
  }

  final Ref _ref;
  bool _isFetching = false;

  Future<void> refreshStores({
    String? search,
    String? category,
    String? sort,
    double? minRating,
    bool? freeDelivery,
    bool? hasOffers,
    bool? openNow,
    int? maxMinutes,
    double? maxMinimumOrder,
  }) async {
    if (_isFetching) return;
    _isFetching = true;
    _ref.read(groceryStoreListLoadingProvider.notifier).state = true;
    _ref.read(groceryStoreListErrorProvider.notifier).state = null;

    try {
      final delivery = _ref.read(foodGroceryDeliveryProvider);
      final selected = delivery.selectedAddress;
      final ds = _ref.read(foodGroceryRemoteDatasourceProvider);
      final stores = await ds.getStores(
        search: search,
        category: category,
        sort: sort,
        lat: selected?.latitude,
        lng: selected?.longitude,
        minRating: minRating,
        freeDelivery: freeDelivery,
        hasOffers: hasOffers,
        openNow: openNow,
        maxMinutes: maxMinutes,
        maxMinimumOrder: maxMinimumOrder,
      );
      if (mounted) {
        state = stores;
      }
    } catch (e) {
      if (mounted) {
        _ref.read(groceryStoreListErrorProvider.notifier).state =
            'Unable to load grocery stores. Pull down or tap Retry.';
      }
    } finally {
      _isFetching = false;
      if (mounted) {
        _ref.read(groceryStoreListLoadingProvider.notifier).state = false;
      }
    }
  }

  Future<void> toggleFavourite(String storeId) async {
    final previous = state;
    state = [
      for (final store in state)
        if (store.id == storeId)
          store.copyWith(isFavourite: !store.isFavourite)
        else
          store,
    ];

    try {
      final ds = _ref.read(foodGroceryRemoteDatasourceProvider);
      await ds.toggleFavourite(storeId);
    } catch (_) {
      if (mounted) {
        state = previous;
      }
    }
  }
}
