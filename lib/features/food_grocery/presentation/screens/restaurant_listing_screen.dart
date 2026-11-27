import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../data/models/food_restaurant.dart';
import '../providers/food_grocery_delivery_provider.dart';
import '../providers/restaurant_list_provider.dart';
import '../widgets/food_grocery_header.dart';
import '../widgets/smart_product_image.dart';

enum RestaurantSortOption {
  recommended,
  rating,
  fastestDelivery,
  nearest,
  deliveryFee,
  price,
}

class RestaurantListingScreen extends ConsumerStatefulWidget {
  const RestaurantListingScreen({super.key});

  @override
  ConsumerState<RestaurantListingScreen> createState() =>
      _RestaurantListingScreenState();
}

class _RestaurantListingScreenState
    extends ConsumerState<RestaurantListingScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'All';
  String _searchQuery = '';

  RestaurantSortOption _sortOption = RestaurantSortOption.recommended;

  bool _minimumFourStar = false;
  bool _freeDeliveryOnly = false;
  bool _offersOnly = false;
  bool _vegetarianOnly = false;
  bool _openNowOnly = false;
  bool _underThirtyMinutes = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FoodRestaurant> _applyFilters(
    List<FoodRestaurant> restaurants,
    double? userLat,
    double? userLng,
  ) {
    var result = restaurants.where((restaurant) {
      final query = _searchQuery.trim().toLowerCase();

      final matchesSearch = query.isEmpty ||
          restaurant.name.toLowerCase().contains(query) ||
          restaurant.cuisines.any(
            (cuisine) => cuisine.toLowerCase().contains(query),
          );

      final matchesCategory = _selectedCategory == 'All' ||
          restaurant.cuisines.any(
            (cuisine) =>
                cuisine.toLowerCase() == _selectedCategory.toLowerCase(),
          );

      final matchesRating = !_minimumFourStar || restaurant.rating >= 4.0;

      final matchesFreeDelivery =
          !_freeDeliveryOnly || restaurant.hasFreeDelivery;

      final matchesOffers = !_offersOnly || restaurant.offerText != null;

      final matchesVegetarian =
          !_vegetarianOnly || restaurant.hasVegetarianOptions;

      final matchesOpenNow = !_openNowOnly || restaurant.isOrderable;

      final matchesDeliveryTime = !_underThirtyMinutes ||
          restaurant.estimatedDeliveryTime.startsWith('20') ||
          restaurant.estimatedDeliveryTime.startsWith('25');

      return matchesSearch &&
          matchesCategory &&
          matchesRating &&
          matchesFreeDelivery &&
          matchesOffers &&
          matchesVegetarian &&
          matchesOpenNow &&
          matchesDeliveryTime;
    }).toList();

    switch (_sortOption) {
      case RestaurantSortOption.recommended:
        break;

      case RestaurantSortOption.rating:
        result.sort(
          (first, second) => second.rating.compareTo(first.rating),
        );

      case RestaurantSortOption.fastestDelivery:
        result.sort(
          (first, second) => _startingMinutes(
            first.estimatedDeliveryTime,
          ).compareTo(
            _startingMinutes(second.estimatedDeliveryTime),
          ),
        );

      case RestaurantSortOption.nearest:
        result.sort(
          (first, second) {
            final d1 = first.calculateDistanceTo(userLat, userLng) ?? first.distanceKm;
            final d2 = second.calculateDistanceTo(userLat, userLng) ?? second.distanceKm;
            return d1.compareTo(d2);
          },
        );

      case RestaurantSortOption.deliveryFee:
        result.sort(
          (first, second) => first.deliveryFee.compareTo(second.deliveryFee),
        );

      case RestaurantSortOption.price:
        result.sort(
          (first, second) => first.priceLevel.length.compareTo(
            second.priceLevel.length,
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

  void _clearSearchAndFilters() {
    _searchController.clear();

    setState(() {
      _searchQuery = '';
      _selectedCategory = 'All';
      _minimumFourStar = false;
      _freeDeliveryOnly = false;
      _offersOnly = false;
      _vegetarianOnly = false;
      _openNowOnly = false;
      _underThirtyMinutes = false;
      _sortOption = RestaurantSortOption.recommended;
    });
  }

  void _selectRestaurant(FoodRestaurant restaurant) {
    // Allow users to view and browse the restaurant menu even when closed.
    // Ordering / checkout is guarded inside the details screen.
    context.pushNamed(
      RouteNames.foodGroceryRestaurantDetails,
      extra: restaurant,
    );
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
    final restaurants = ref.watch(restaurantListProvider);
    final visibleRestaurants = _applyFilters(restaurants, userLat, userLng);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Column(
        children: [
          const FoodGroceryHeader(
            title: 'Restaurants',
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primaryGoldDark,
              onRefresh: () async {
                ref.read(restaurantListProvider.notifier).refreshRestaurants();
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
                  _RestaurantSearchField(
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
                          '${visibleRestaurants.length} restaurants',
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
                  if (ref.watch(restaurantListLoadingProvider) && restaurants.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryGoldDark,
                        ),
                      ),
                    )
                  else if (ref.watch(restaurantListErrorProvider) != null &&
                      restaurants.isEmpty)
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
                              ref.watch(restaurantListErrorProvider)!,
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
                                    .read(restaurantListProvider.notifier)
                                    .refreshRestaurants();
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
                  else if (visibleRestaurants.isEmpty)
                    _RestaurantEmptyState(
                      isDark: isDark,
                      hasSearch: _searchQuery.trim().isNotEmpty,
                      onClear: _clearSearchAndFilters,
                      onChangeLocation: _changeLocation,
                    )
                  else
                    ...visibleRestaurants.map(
                      (restaurant) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _RestaurantCard(
                          restaurant: restaurant,
                          isDark: isDark,
                          distanceText: restaurant.dynamicDistanceText(
                            userLat,
                            userLng,
                          ),
                          onTap: () {
                            _selectRestaurant(restaurant);
                          },
                          onFavouritePressed: () {
                            ref
                                .read(
                                  restaurantListProvider.notifier,
                                )
                                .toggleFavourite(
                                  restaurant.id,
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

class _RestaurantSearchField extends StatelessWidget {
  const _RestaurantSearchField({
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
        hintText: 'Search restaurants or food',
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

class _RestaurantCard extends StatelessWidget {
  const _RestaurantCard({
    required this.restaurant,
    required this.isDark,
    required this.onTap,
    required this.onFavouritePressed,
    this.distanceText,
  });

  final FoodRestaurant restaurant;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onFavouritePressed;
  final String? distanceText;

  Color get _statusColor {
    switch (restaurant.effectiveStatus) {
      case RestaurantOperationalStatus.open:
        return AppColors.success;

      case RestaurantOperationalStatus.closingSoon:
        return AppColors.warning;

      case RestaurantOperationalStatus.busy:
        return AppColors.info;

      case RestaurantOperationalStatus.closed:
      case RestaurantOperationalStatus.temporarilyUnavailable:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: restaurant.isOrderable ? 1 : 0.68,
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
                      imageUrl: restaurant.imageUrl,
                      width: double.infinity,
                      height: 140,
                      fallbackIcon: Icons.restaurant_menu_rounded,
                      customBorderRadius: const BorderRadius.vertical(
                        top: Radius.circular(15),
                      ),
                    ),
                    if (restaurant.promotionalTag != null)
                      Positioned(
                        left: 10,
                        top: 10,
                        child: _CardBadge(
                          text: restaurant.promotionalTag!,
                          backgroundColor: AppColors.backgroundDark,
                          textColor: Colors.white,
                        ),
                      ),
                    Positioned(
                      left: 10,
                      bottom: 10,
                      child: _CardBadge(
                        text: restaurant.statusText,
                        backgroundColor: _statusColor,
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
                              restaurant.name,
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
                            restaurant.priceLevel,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primaryGoldDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        restaurant.cuisineText.isNotEmpty
                            ? restaurant.cuisineText
                            : 'Restaurant • Multi-Cuisine',
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
                          _RestaurantMetaItem(
                            icon: Icons.star_rounded,
                            text: restaurant.formattedRatingText,
                            iconColor: AppColors.primaryGoldDark,
                            isDark: isDark,
                          ),
                          _RestaurantMetaItem(
                            icon: Icons.schedule_rounded,
                            text: restaurant.preparationTime,
                            isDark: isDark,
                          ),
                          if (distanceText != null || restaurant.distanceText != null)
                            _RestaurantMetaItem(
                              icon: Icons.location_on_outlined,
                              text: (distanceText ?? restaurant.distanceText)!,
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
                          Text(
                            restaurant.minimumOrderText,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.textSecondary
                                  : AppColors.textSecondaryLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          if (restaurant.offerText != null)
                            _CardBadge(
                              text: restaurant.offerText!,
                              backgroundColor:
                                  AppColors.primaryGold.withValues(alpha: 0.18),
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

class _CardBadge extends StatelessWidget {
  const _CardBadge({
    required this.text,
    required this.backgroundColor,
    required this.textColor,
  });

  final String text;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
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

class _RestaurantMetaItem extends StatelessWidget {
  const _RestaurantMetaItem({
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

class _RestaurantEmptyState extends StatelessWidget {
  const _RestaurantEmptyState({
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
      padding: const EdgeInsets.fromLTRB(24, 34, 24, 30),
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
            hasSearch
                ? Icons.search_off_rounded
                : Icons.restaurant_menu_rounded,
            size: 44,
            color: AppColors.primaryGoldDark,
          ),
          const SizedBox(height: 14),
          Text(
            hasSearch
                ? 'No restaurants or food items found'
                : 'No restaurants are currently available',
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
