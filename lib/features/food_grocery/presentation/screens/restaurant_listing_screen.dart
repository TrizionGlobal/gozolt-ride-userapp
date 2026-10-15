import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../data/models/food_restaurant.dart';
import '../providers/restaurant_list_provider.dart';
import '../widgets/food_grocery_header.dart';

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

  static const List<String> _categories = [
    'All',
    'Pizza',
    'Burgers',
    'Mediterranean',
    'Indian',
    'Asian',
    'Italian',
    'Healthy',
    'Desserts',
    'Fast Food',
  ];

  String _deliveryLocation = 'Sliema, Malta';
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

  int get _activeFilterCount {
    return [
      _minimumFourStar,
      _freeDeliveryOnly,
      _offersOnly,
      _vegetarianOnly,
      _openNowOnly,
      _underThirtyMinutes,
    ].where((selected) => selected).length;
  }

  List<FoodRestaurant> _applyFilters(
    List<FoodRestaurant> restaurants,
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
          (first, second) => first.distanceKm.compareTo(second.distanceKm),
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
    // TODO(FOOD_GROCERY_API):
    // Open the common saved-address/location selection screen.
    setState(() {
      _deliveryLocation = _deliveryLocation == 'Sliema, Malta'
          ? 'Valletta, Malta'
          : 'Sliema, Malta';
    });

    ref.read(restaurantListProvider.notifier).refreshRestaurants();
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
    if (!restaurant.isOrderable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            restaurant.status == RestaurantOperationalStatus.closed
                ? 'This restaurant is no longer accepting orders'
                : 'This restaurant is currently unavailable',
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white,
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // TODO(FOOD_GROCERY_API):
    // Revalidate restaurant availability with the backend
    // before opening the restaurant menu.
    context.pushNamed(
      RouteNames.foodGroceryRestaurantDetails,
      extra: restaurant,
    );
  }

  Future<void> _showFilterSheet() async {
    var temporaryMinimumFourStar = _minimumFourStar;
    var temporaryFreeDeliveryOnly = _freeDeliveryOnly;
    var temporaryOffersOnly = _offersOnly;
    var temporaryVegetarianOnly = _vegetarianOnly;
    var temporaryOpenNowOnly = _openNowOnly;
    var temporaryUnderThirtyMinutes = _underThirtyMinutes;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(
                  18,
                  12,
                  18,
                  18,
                ),
                decoration: BoxDecoration(
                  color:
                      isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Filter restaurants',
                              style: AppTextStyles.titleMedium.copyWith(
                                color: isDark
                                    ? AppColors.textPrimary
                                    : AppColors.textPrimaryLight,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setSheetState(() {
                                temporaryMinimumFourStar = false;
                                temporaryFreeDeliveryOnly = false;
                                temporaryOffersOnly = false;
                                temporaryVegetarianOnly = false;
                                temporaryOpenNowOnly = false;
                                temporaryUnderThirtyMinutes = false;
                              });
                            },
                            child: Text(
                              'Clear',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primaryGoldDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _FilterCheckbox(
                        title: 'Rating 4.0+',
                        subtitle: 'Show highly rated restaurants',
                        value: temporaryMinimumFourStar,
                        isDark: isDark,
                        onChanged: (value) {
                          setSheetState(() {
                            temporaryMinimumFourStar = value;
                          });
                        },
                      ),
                      _FilterCheckbox(
                        title: 'Free delivery',
                        subtitle: 'No delivery charge',
                        value: temporaryFreeDeliveryOnly,
                        isDark: isDark,
                        onChanged: (value) {
                          setSheetState(() {
                            temporaryFreeDeliveryOnly = value;
                          });
                        },
                      ),
                      _FilterCheckbox(
                        title: 'Offers',
                        subtitle: 'Restaurants with active offers',
                        value: temporaryOffersOnly,
                        isDark: isDark,
                        onChanged: (value) {
                          setSheetState(() {
                            temporaryOffersOnly = value;
                          });
                        },
                      ),
                      _FilterCheckbox(
                        title: 'Vegetarian options',
                        subtitle: 'Vegetarian items available',
                        value: temporaryVegetarianOnly,
                        isDark: isDark,
                        onChanged: (value) {
                          setSheetState(() {
                            temporaryVegetarianOnly = value;
                          });
                        },
                      ),
                      _FilterCheckbox(
                        title: 'Open now',
                        subtitle: 'Hide closed restaurants',
                        value: temporaryOpenNowOnly,
                        isDark: isDark,
                        onChanged: (value) {
                          setSheetState(() {
                            temporaryOpenNowOnly = value;
                          });
                        },
                      ),
                      _FilterCheckbox(
                        title: 'Under 30 minutes',
                        subtitle: 'Faster delivery options',
                        value: temporaryUnderThirtyMinutes,
                        isDark: isDark,
                        onChanged: (value) {
                          setSheetState(() {
                            temporaryUnderThirtyMinutes = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _minimumFourStar = temporaryMinimumFourStar;
                              _freeDeliveryOnly = temporaryFreeDeliveryOnly;
                              _offersOnly = temporaryOffersOnly;
                              _vegetarianOnly = temporaryVegetarianOnly;
                              _openNowOnly = temporaryOpenNowOnly;
                              _underThirtyMinutes = temporaryUnderThirtyMinutes;
                            });

                            Navigator.pop(sheetContext);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGold,
                            foregroundColor: AppColors.backgroundDark,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'APPLY FILTERS',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.backgroundDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showSortSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;

        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              18,
              12,
              18,
              18,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color:
                          isDark ? AppColors.borderDark : AppColors.borderLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Sort by',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: isDark
                        ? AppColors.textPrimary
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ...RestaurantSortOption.values.map(
                  (option) {
                    return _SortOptionTile(
                      title: _sortOptionText(option),
                      selected: _sortOption == option,
                      isDark: isDark,
                      onTap: () {
                        setState(() {
                          _sortOption = option;
                        });

                        Navigator.pop(sheetContext);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _sortOptionText(RestaurantSortOption option) {
    switch (option) {
      case RestaurantSortOption.recommended:
        return 'Recommended';

      case RestaurantSortOption.rating:
        return 'Rating';

      case RestaurantSortOption.fastestDelivery:
        return 'Fastest delivery';

      case RestaurantSortOption.nearest:
        return 'Nearest';

      case RestaurantSortOption.deliveryFee:
        return 'Delivery fee';

      case RestaurantSortOption.price:
        return 'Price';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final restaurants = ref.watch(restaurantListProvider);
    final visibleRestaurants = _applyFilters(restaurants);

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
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (context, index) {
                        return const SizedBox(width: 8);
                      },
                      itemBuilder: (context, index) {
                        final category = _categories[index];

                        return _CategoryChip(
                          label: category,
                          selected: category == _selectedCategory,
                          isDark: isDark,
                          onTap: () {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _ControlButton(
                          icon: Icons.tune_rounded,
                          label: _activeFilterCount == 0
                              ? 'Filter'
                              : 'Filter ($_activeFilterCount)',
                          highlighted: _activeFilterCount > 0,
                          isDark: isDark,
                          onTap: _showFilterSheet,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ControlButton(
                          icon: Icons.swap_vert_rounded,
                          label: _sortOptionText(
                            _sortOption,
                          ),
                          highlighted:
                              _sortOption != RestaurantSortOption.recommended,
                          isDark: isDark,
                          onTap: _showSortSheet,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
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
                      Text(
                        'Delivering to $_deliveryLocation',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.textSecondary
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (visibleRestaurants.isEmpty)
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

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primaryGold
          : isDark
              ? AppColors.surfaceDark
              : AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppColors.primaryGold
                  : isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: selected
                  ? AppColors.backgroundDark
                  : isDark
                      ? AppColors.textSecondary
                      : AppColors.textSecondaryLight,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.highlighted,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool highlighted;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(
        icon,
        size: 18,
      ),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.labelSmall.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: highlighted
            ? AppColors.backgroundDark
            : isDark
                ? AppColors.textPrimary
                : AppColors.textPrimaryLight,
        backgroundColor: highlighted
            ? AppColors.primaryGold
            : isDark
                ? AppColors.surfaceDark
                : AppColors.surfaceLight,
        side: BorderSide(
          color: highlighted
              ? AppColors.primaryGold
              : isDark
                  ? AppColors.borderDark
                  : AppColors.borderLight,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 11,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
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
  });

  final FoodRestaurant restaurant;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onFavouritePressed;

  Color get _statusColor {
    switch (restaurant.status) {
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
                    Container(
                      height: 132,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.primaryGold.withValues(
                          alpha: 0.14,
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(15),
                        ),
                      ),
                      child: const Icon(
                        Icons.restaurant_menu_rounded,
                        size: 48,
                        color: AppColors.primaryGoldDark,
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
                      right: 10,
                      top: 10,
                      child: Material(
                        color: isDark
                            ? AppColors.backgroundDark.withValues(alpha: 0.82)
                            : Colors.white.withValues(alpha: 0.92),
                        shape: const CircleBorder(),
                        child: IconButton(
                          onPressed: onFavouritePressed,
                          constraints: const BoxConstraints.tightFor(
                            width: 38,
                            height: 38,
                          ),
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            restaurant.isFavourite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 21,
                            color: restaurant.isFavourite
                                ? AppColors.error
                                : isDark
                                    ? AppColors.textPrimary
                                    : AppColors.textPrimaryLight,
                          ),
                        ),
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
                        restaurant.cuisineText,
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
                            text:
                                '${restaurant.rating} (${restaurant.ratingCount})',
                            iconColor: AppColors.primaryGoldDark,
                            isDark: isDark,
                          ),
                          _RestaurantMetaItem(
                            icon: Icons.schedule_rounded,
                            text: restaurant.estimatedDeliveryTime,
                            isDark: isDark,
                          ),
                          _RestaurantMetaItem(
                            icon: Icons.location_on_outlined,
                            text: restaurant.distanceText,
                            isDark: isDark,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            restaurant.hasFreeDelivery
                                ? Icons.delivery_dining_rounded
                                : Icons.moped_outlined,
                            size: 18,
                            color: restaurant.hasFreeDelivery
                                ? AppColors.success
                                : AppColors.primaryGoldDark,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              restaurant.deliveryFeeText,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: restaurant.hasFreeDelivery
                                    ? AppColors.success
                                    : isDark
                                        ? AppColors.textSecondary
                                        : AppColors.textSecondaryLight,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
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

class _FilterCheckbox extends StatelessWidget {
  const _FilterCheckbox({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final bool isDark;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: (newValue) {
        onChanged(newValue ?? false);
      },
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: AppColors.primaryGold,
      checkColor: AppColors.backgroundDark,
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.copyWith(
          color:
              isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
        ),
      ),
    );
  }
}

class _SortOptionTile extends StatelessWidget {
  const _SortOptionTile({
    required this.title,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          color: selected
              ? AppColors.primaryGoldDark
              : isDark
                  ? AppColors.textPrimary
                  : AppColors.textPrimaryLight,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing: selected
          ? const Icon(
              Icons.check_circle_rounded,
              size: 21,
              color: AppColors.primaryGoldDark,
            )
          : Icon(
              Icons.circle_outlined,
              size: 21,
              color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
            ),
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
