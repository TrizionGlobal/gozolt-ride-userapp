import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../data/models/grocery_store.dart';
import '../providers/grocery_store_list_provider.dart';
import '../widgets/food_grocery_header.dart';

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

  static const List<String> _categories = [
    'All',
    'Supermarkets',
    'Convenience',
    'Fruits & Vegetables',
    'Bakery',
    'Dairy',
    'Meat & Fish',
    'Beverages',
    'Household',
    'Personal Care',
  ];

  String _deliveryLocation = 'Sliema, Malta';
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

  int get _activeFilterCount {
    return [
      _openNowOnly,
      _minimumFourStar,
      _freeDeliveryOnly,
      _offersOnly,
      _underThirtyMinutes,
      _underTwentyMinimum,
    ].where((selected) => selected).length;
  }

  List<GroceryStore> _visibleStores(
    List<GroceryStore> stores,
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
          (first, second) => first.distanceKm.compareTo(
            second.distanceKm,
          ),
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
    setState(() {
      _deliveryLocation = _deliveryLocation == 'Sliema, Malta'
          ? 'Valletta, Malta'
          : 'Sliema, Malta';
    });

    ref.read(groceryStoreListProvider.notifier).refreshStores();
  }

  void _selectStore(GroceryStore store) {
    if (!store.isOrderable) {
      _showMessage(
        store.status == GroceryStoreOperationalStatus.closed
            ? 'This store is no longer accepting orders'
            : 'This grocery store is currently unavailable',
      );
      return;
    }

    // TODO(FOOD_GROCERY_API):
    // Revalidate store availability, delivery eligibility
    // and delivery-zone coverage before navigation.
    context.pushNamed(
      RouteNames.foodGroceryCatalogue,
      extra: store,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white,
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
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

  String _sortText(
    GroceryStoreSortOption option,
  ) {
    switch (option) {
      case GroceryStoreSortOption.recommended:
        return 'Recommended';

      case GroceryStoreSortOption.nearest:
        return 'Nearest';

      case GroceryStoreSortOption.fastestDelivery:
        return 'Fastest delivery';

      case GroceryStoreSortOption.rating:
        return 'Rating';

      case GroceryStoreSortOption.deliveryFee:
        return 'Delivery fee';

      case GroceryStoreSortOption.minimumOrder:
        return 'Minimum order';
    }
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
                const _SheetHandle(),
                const SizedBox(height: 16),
                Text(
                  'Sort grocery stores',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: isDark
                        ? AppColors.textPrimary
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ...GroceryStoreSortOption.values.map(
                  (option) {
                    return _StoreSortTile(
                      title: _sortText(option),
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

  Future<void> _showFilterSheet() async {
    var temporaryOpenNow = _openNowOnly;
    var temporaryFourStar = _minimumFourStar;
    var temporaryFreeDelivery = _freeDeliveryOnly;
    var temporaryOffers = _offersOnly;
    var temporaryFastDelivery = _underThirtyMinutes;
    var temporaryLowMinimum = _underTwentyMinimum;

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
                      const _SheetHandle(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Filter grocery stores',
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
                                temporaryOpenNow = false;
                                temporaryFourStar = false;
                                temporaryFreeDelivery = false;
                                temporaryOffers = false;
                                temporaryFastDelivery = false;
                                temporaryLowMinimum = false;
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
                      const SizedBox(height: 6),
                      _StoreFilterCheckbox(
                        title: 'Open now',
                        subtitle: 'Hide closed and unavailable stores',
                        value: temporaryOpenNow,
                        isDark: isDark,
                        onChanged: (value) {
                          setSheetState(() {
                            temporaryOpenNow = value;
                          });
                        },
                      ),
                      _StoreFilterCheckbox(
                        title: 'Rating 4.0+',
                        subtitle: 'Show highly rated grocery stores',
                        value: temporaryFourStar,
                        isDark: isDark,
                        onChanged: (value) {
                          setSheetState(() {
                            temporaryFourStar = value;
                          });
                        },
                      ),
                      _StoreFilterCheckbox(
                        title: 'Free delivery',
                        subtitle: 'No delivery charge',
                        value: temporaryFreeDelivery,
                        isDark: isDark,
                        onChanged: (value) {
                          setSheetState(() {
                            temporaryFreeDelivery = value;
                          });
                        },
                      ),
                      _StoreFilterCheckbox(
                        title: 'Active offers',
                        subtitle: 'Stores with promotions',
                        value: temporaryOffers,
                        isDark: isDark,
                        onChanged: (value) {
                          setSheetState(() {
                            temporaryOffers = value;
                          });
                        },
                      ),
                      _StoreFilterCheckbox(
                        title: 'Under 30 minutes',
                        subtitle: 'Faster grocery delivery',
                        value: temporaryFastDelivery,
                        isDark: isDark,
                        onChanged: (value) {
                          setSheetState(() {
                            temporaryFastDelivery = value;
                          });
                        },
                      ),
                      _StoreFilterCheckbox(
                        title: 'Minimum order €20 or less',
                        subtitle: 'Lower minimum-order stores',
                        value: temporaryLowMinimum,
                        isDark: isDark,
                        onChanged: (value) {
                          setSheetState(() {
                            temporaryLowMinimum = value;
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
                              _openNowOnly = temporaryOpenNow;
                              _minimumFourStar = temporaryFourStar;
                              _freeDeliveryOnly = temporaryFreeDelivery;
                              _offersOnly = temporaryOffers;
                              _underThirtyMinutes = temporaryFastDelivery;
                              _underTwentyMinimum = temporaryLowMinimum;
                            });

                            Navigator.pop(
                              sheetContext,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGold,
                            foregroundColor: AppColors.backgroundDark,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                14,
                              ),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final stores = ref.watch(groceryStoreListProvider);

    final visibleStores = _visibleStores(stores);

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
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (context, index) {
                        return const SizedBox(
                          width: 8,
                        );
                      },
                      itemBuilder: (context, index) {
                        final category = _categories[index];

                        return _GroceryCategoryChip(
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
                        child: _ListingControlButton(
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
                        child: _ListingControlButton(
                          icon: Icons.swap_vert_rounded,
                          label: _sortText(_sortOption),
                          highlighted:
                              _sortOption != GroceryStoreSortOption.recommended,
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
                          'Delivering to $_deliveryLocation',
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
                  if (visibleStores.isEmpty)
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

class _GroceryCategoryChip extends StatelessWidget {
  const _GroceryCategoryChip({
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

class _ListingControlButton extends StatelessWidget {
  const _ListingControlButton({
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
      icon: Icon(icon, size: 18),
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

class _GroceryStoreCard extends StatelessWidget {
  const _GroceryStoreCard({
    required this.store,
    required this.isDark,
    required this.onTap,
    required this.onFavouritePressed,
  });

  final GroceryStore store;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onFavouritePressed;

  Color get _statusColor {
    switch (store.status) {
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
                    Container(
                      width: double.infinity,
                      height: 132,
                      decoration: BoxDecoration(
                        color: AppColors.primaryGold.withValues(alpha: 0.13),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(15),
                        ),
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        size: 49,
                        color: AppColors.primaryGoldDark,
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
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Material(
                        color: isDark
                            ? AppColors.backgroundDark.withValues(alpha: 0.84)
                            : Colors.white.withValues(
                                alpha: 0.94,
                              ),
                        shape: const CircleBorder(),
                        child: IconButton(
                          onPressed: onFavouritePressed,
                          constraints: const BoxConstraints.tightFor(
                            width: 38,
                            height: 38,
                          ),
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            store.isFavourite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 21,
                            color: store.isFavourite
                                ? AppColors.error
                                : isDark
                                    ? AppColors.textPrimary
                                    : AppColors.textPrimaryLight,
                          ),
                        ),
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
                        store.categoryText,
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
                            text: '${store.rating} (${store.ratingCount})',
                            isDark: isDark,
                            iconColor: AppColors.primaryGoldDark,
                          ),
                          _StoreMetaItem(
                            icon: Icons.schedule_rounded,
                            text: store.estimatedDeliveryTime,
                            isDark: isDark,
                          ),
                          _StoreMetaItem(
                            icon: Icons.location_on_outlined,
                            text: store.distanceText,
                            isDark: isDark,
                          ),
                          _StoreMetaItem(
                            icon: Icons.shopping_bag_outlined,
                            text: store.minimumOrderText,
                            isDark: isDark,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.delivery_dining_rounded,
                            size: 18,
                            color: store.hasFreeDelivery
                                ? AppColors.success
                                : AppColors.primaryGoldDark,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              store.deliveryFeeText,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: store.hasFreeDelivery
                                    ? AppColors.success
                                    : isDark
                                        ? AppColors.textSecondary
                                        : AppColors.textSecondaryLight,
                                fontWeight: FontWeight.w500,
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

class _StoreFilterCheckbox extends StatelessWidget {
  const _StoreFilterCheckbox({
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
      contentPadding: EdgeInsets.zero,
      dense: true,
      activeColor: AppColors.primaryGold,
      checkColor: AppColors.backgroundDark,
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

class _StoreSortTile extends StatelessWidget {
  const _StoreSortTile({
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
      trailing: Icon(
        selected ? Icons.check_circle_rounded : Icons.circle_outlined,
        size: 21,
        color: selected
            ? AppColors.primaryGoldDark
            : isDark
                ? AppColors.textMuted
                : AppColors.textMutedLight,
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Container(
        width: 42,
        height: 4,
        decoration: BoxDecoration(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
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
