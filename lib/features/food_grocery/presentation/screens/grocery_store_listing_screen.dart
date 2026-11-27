import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../data/models/grocery_store.dart';
import '../providers/food_grocery_delivery_provider.dart';
import '../providers/grocery_store_list_provider.dart';
import '../widgets/food_grocery_header.dart';
import '../widgets/smart_product_image.dart';

enum GroceryStoreSortOption {
  recommended,
  nearest,
  fastestDelivery,
  rating,
  deliveryFee,
  minimumOrder,
}

class GroceryStoreListingScreen extends ConsumerStatefulWidget {
  const GroceryStoreListingScreen({super.key});

  @override
  ConsumerState<GroceryStoreListingScreen> createState() =>
      _GroceryStoreListingScreenState();
}

class _GroceryStoreListingScreenState
    extends ConsumerState<GroceryStoreListingScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'All';
  String _searchQuery = '';

  GroceryStoreSortOption _sortOption = GroceryStoreSortOption.recommended;

  bool _openNowOnly = false;
  bool _minimumFourStar = false;
  bool _freeDeliveryOnly = false;
  bool _offersOnly = false;
  bool _underThirtyMinutes = false;
  bool _underTwentyMinimum = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<GroceryStore> _visibleStores(
    List<GroceryStore> stores,
    double? userLat,
    double? userLng,
  ) {
    final result = stores.where((store) {
      final matchesSearch = store.matchesSearch(_searchQuery);

      final category = _selectedCategory.toLowerCase();

      final matchesCategory = _selectedCategory == 'All' ||
          store.storeType.toLowerCase().contains(category) ||
          store.mainCategories.any(
            (item) => item.toLowerCase().contains(category),
          );

      final matchesOpen = !_openNowOnly || store.isOrderable;

      final matchesRating = !_minimumFourStar || store.rating >= 4;

      final matchesFreeDelivery = !_freeDeliveryOnly || store.hasFreeDelivery;

      final matchesOffer = !_offersOnly || store.offerText != null;

      final matchesDeliveryTime = !_underThirtyMinutes ||
          _startingMinutes(
                store.estimatedDeliveryTime,
              ) <=
              30;

      final matchesMinimum = !_underTwentyMinimum || store.minimumOrder <= 20;

      return matchesSearch &&
          matchesCategory &&
          matchesOpen &&
          matchesRating &&
          matchesFreeDelivery &&
          matchesOffer &&
          matchesDeliveryTime &&
          matchesMinimum;
    }).toList();

    switch (_sortOption) {
      case GroceryStoreSortOption.recommended:
        break;

      case GroceryStoreSortOption.nearest:
        result.sort(
          (first, second) {
            final d1 = first.calculateDistanceTo(userLat, userLng) ?? first.distanceKm;
            final d2 = second.calculateDistanceTo(userLat, userLng) ?? second.distanceKm;
            return d1.compareTo(d2);
          },
        );

      case GroceryStoreSortOption.fastestDelivery:
        result.sort(
          (first, second) => _startingMinutes(
            first.estimatedDeliveryTime,
          ).compareTo(
            _startingMinutes(
              second.estimatedDeliveryTime,
            ),
          ),
        );

      case GroceryStoreSortOption.rating:
        result.sort(
          (first, second) => second.rating.compareTo(first.rating),
        );

      case GroceryStoreSortOption.deliveryFee:
        result.sort(
          (first, second) => first.deliveryFee.compareTo(
            second.deliveryFee,
          ),
        );

      case GroceryStoreSortOption.minimumOrder:
        result.sort(
          (first, second) => first.minimumOrder.compareTo(
            second.minimumOrder,
          ),
        );
    }

    return result;
  }

  int _startingMinutes(String deliveryTime) {
    final firstPart = deliveryTime.split('–').first;
    return int.tryParse(firstPart.trim()) ?? 999;
  }

  void _changeLocation() {
    context.pushNamed(RouteNames.foodGroceryDeliveryAddress);
  }

  void _selectStore(GroceryStore store) {
    // Allow users to view and browse the store catalogue even when closed.
    // Ordering / checkout is guarded inside the catalogue screen.
    context.pushNamed(
      RouteNames.foodGroceryCatalogue,
      extra: store,
    );
  }



  void _clearSearchAndFilters() {
    _searchController.clear();

    setState(() {
      _searchQuery = '';
      _selectedCategory = 'All';
      _sortOption = GroceryStoreSortOption.recommended;
      _openNowOnly = false;
      _minimumFourStar = false;
      _freeDeliveryOnly = false;
      _offersOnly = false;
      _underThirtyMinutes = false;
      _underTwentyMinimum = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final deliveryState = ref.watch(foodGroceryDeliveryProvider);
    final selectedAddress = deliveryState.selectedAddress;
    final deliveryLocation = selectedAddress?.locality.isNotEmpty == true
        ? selectedAddress!.locality
        : (selectedAddress?.city.isNotEmpty == true
            ? selectedAddress!.city
            : 'Set delivery location');
    final userLat = selectedAddress?.latitude;
    final userLng = selectedAddress?.longitude;
    final stores = ref.watch(groceryStoreListProvider);

    final visibleStores = _visibleStores(stores, userLat, userLng);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Column(
        children: [
          const FoodGroceryHeader(
            title: 'Grocery Stores',
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primaryGoldDark,
              onRefresh: () async {
                ref
                    .read(
                      groceryStoreListProvider.notifier,
                    )
                    .refreshStores();
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  28,
                ),
                children: [
                  _GrocerySearchField(
                    controller: _searchController,
                    isDark: isDark,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    onClear: () {
                      _searchController.clear();

                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${visibleStores.length} grocery stores',
                          style: AppTextStyles.titleSmall.copyWith(
                            color: isDark
                                ? AppColors.textPrimary
                                : AppColors.textPrimaryLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          'Delivering to $deliveryLocation',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: isDark
                                ? AppColors.textSecondary
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (ref.watch(groceryStoreListLoadingProvider) && stores.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryGoldDark,
                        ),
                      ),
                    )
                  else if (ref.watch(groceryStoreListErrorProvider) != null &&
                      stores.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 36,
                        horizontal: 16,
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 48,
                              color: AppColors.error,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              ref.watch(groceryStoreListErrorProvider)!,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: isDark
                                    ? AppColors.textSecondary
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                ref
                                    .read(groceryStoreListProvider.notifier)
                                    .refreshStores();
                              },
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGoldDark,
                                foregroundColor: AppColors.backgroundDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (visibleStores.isEmpty)
                    _GroceryEmptyState(
                      isDark: isDark,
                      hasSearch: _searchQuery.trim().isNotEmpty,
                      onClear: _clearSearchAndFilters,
                      onChangeLocation: _changeLocation,
                    )
                  else
                    ...visibleStores.map(
                      (store) => Padding(
                        padding: const EdgeInsets.only(
                          bottom: 12,
                        ),
                        child: _GroceryStoreCard(
                          store: store,
                          isDark: isDark,
                          distanceText: store.dynamicDistanceText(
                            userLat,
                            userLng,
                          ),
                          onTap: () {
                            _selectStore(store);
                          },
                          onFavouritePressed: () {
                            ref
                                .read(
                                  groceryStoreListProvider.notifier,
                                )
                                .toggleFavourite(
                                  store.id,
                                );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GrocerySearchField extends StatelessWidget {
  const _GrocerySearchField({
    required this.controller,
    required this.isDark,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool isDark;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: AppTextStyles.bodyMedium.copyWith(
        color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
      ),
      decoration: InputDecoration(
        hintText: 'Search stores or grocery products',
        hintStyle: AppTextStyles.bodySmall.copyWith(
          color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 21,
          color:
              isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
        ),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: onClear,
                icon: const Icon(
                  Icons.close_rounded,
                  size: 19,
                ),
              ),
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.primaryGold,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class _GroceryStoreCard extends StatelessWidget {
  const _GroceryStoreCard({
    required this.store,
    required this.isDark,
    required this.onTap,
    required this.onFavouritePressed,
    this.distanceText,
  });

  final GroceryStore store;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onFavouritePressed;
  final String? distanceText;

  Color get _statusColor {
    switch (store.effectiveStatus) {
      case GroceryStoreOperationalStatus.open:
        return AppColors.success;

      case GroceryStoreOperationalStatus.busy:
        return AppColors.info;

      case GroceryStoreOperationalStatus.closingSoon:
        return AppColors.warning;

      case GroceryStoreOperationalStatus.closed:
      case GroceryStoreOperationalStatus.temporarilyUnavailable:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: store.isOrderable ? 1 : 0.67,
      child: Material(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    SmartProductImage(
                      imageUrl: store.imageUrl,
                      width: double.infinity,
                      height: 140,
                      fallbackIcon: Icons.storefront_rounded,
                      customBorderRadius: const BorderRadius.vertical(
                        top: Radius.circular(15),
                      ),
                    ),
                    if (store.promotionalTag != null)
                      Positioned(
                        left: 10,
                        top: 10,
                        child: _StoreBadge(
                          text: store.promotionalTag!,
                          color: AppColors.backgroundDark,
                          textColor: Colors.white,
                        ),
                      ),
                    Positioned(
                      left: 10,
                      bottom: 10,
                      child: _StoreBadge(
                        text: store.statusText,
                        color: _statusColor,
                        textColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              store.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.titleSmall.copyWith(
                                color: isDark
                                    ? AppColors.textPrimary
                                    : AppColors.textPrimaryLight,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            store.storeType,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primaryGoldDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        store.categoryText.isNotEmpty
                            ? store.categoryText
                            : 'Supermarket • Groceries & Essentials',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.textSecondary
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 12,
                        runSpacing: 7,
                        children: [
                          _StoreMetaItem(
                            icon: Icons.star_rounded,
                            text: store.formattedRatingText,
                            isDark: isDark,
                            iconColor: AppColors.primaryGoldDark,
                          ),
                          _StoreMetaItem(
                            icon: Icons.schedule_rounded,
                            text: store.preparationTime,
                            isDark: isDark,
                          ),
                          if (distanceText != null || store.distanceText != null)
                            _StoreMetaItem(
                              icon: Icons.location_on_outlined,
                              text: (distanceText ?? store.distanceText)!,
                              isDark: isDark,
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            Icons.shopping_bag_outlined,
                            size: 16,
                            color: AppColors.primaryGoldDark,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              store.minimumOrderText,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: isDark
                                    ? AppColors.textSecondary
                                    : AppColors.textSecondaryLight,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (store.offerText != null)
                            _StoreBadge(
                              text: store.offerText!,
                              color: AppColors.primaryGold.withValues(
                                alpha: 0.17,
                              ),
                              textColor: AppColors.primaryGoldDark,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StoreBadge extends StatelessWidget {
  const _StoreBadge({
    required this.text,
    required this.color,
    required this.textColor,
  });

  final String text;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StoreMetaItem extends StatelessWidget {
  const _StoreMetaItem({
    required this.icon,
    required this.text,
    required this.isDark,
    this.iconColor,
  });

  final IconData icon;
  final String text;
  final bool isDark;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: iconColor ??
              (isDark ? AppColors.textSecondary : AppColors.textSecondaryLight),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTextStyles.labelSmall.copyWith(
            color:
                isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

class _GroceryEmptyState extends StatelessWidget {
  const _GroceryEmptyState({
    required this.isDark,
    required this.hasSearch,
    required this.onClear,
    required this.onChangeLocation,
  });

  final bool isDark;
  final bool hasSearch;
  final VoidCallback onClear;
  final VoidCallback onChangeLocation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        24,
        34,
        24,
        30,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          Icon(
            hasSearch ? Icons.search_off_rounded : Icons.storefront_rounded,
            size: 44,
            color: AppColors.primaryGoldDark,
          ),
          const SizedBox(height: 14),
          Text(
            hasSearch
                ? 'No stores or grocery products found'
                : 'No grocery stores are currently available',
            textAlign: TextAlign.center,
            style: AppTextStyles.titleSmall.copyWith(
              color:
                  isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasSearch
                ? 'Try another search or clear your filters.'
                : 'Try changing your delivery location.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppColors.textSecondary
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton(
            onPressed: hasSearch ? onClear : onChangeLocation,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.backgroundDark,
              backgroundColor: AppColors.primaryGold,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              hasSearch ? 'CLEAR SEARCH' : 'CHANGE LOCATION',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.backgroundDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
