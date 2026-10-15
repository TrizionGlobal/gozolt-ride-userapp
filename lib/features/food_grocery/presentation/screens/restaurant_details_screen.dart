import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../data/models/food_restaurant.dart';
import '../../data/models/restaurant_menu.dart';
import '../providers/restaurant_menu_provider.dart';
import '../widgets/food_grocery_header.dart';
import '../../data/models/food_grocery_cart.dart';
import '../providers/food_grocery_cart_provider.dart';

class RestaurantDetailsScreen extends ConsumerStatefulWidget {
  const RestaurantDetailsScreen({
    super.key,
    required this.restaurant,
  });

  final FoodRestaurant restaurant;

  @override
  ConsumerState<RestaurantDetailsScreen> createState() =>
      _RestaurantDetailsScreenState();
}

class _RestaurantDetailsScreenState
    extends ConsumerState<RestaurantDetailsScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategoryId = 'popular';
  String _searchQuery = '';
  bool _isFavourite = false;

  static const double _minimumOrder = 15;

  @override
  void initState() {
    super.initState();
    _isFavourite = widget.restaurant.isFavourite;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<RestaurantMenuItem> _visibleItems(
    RestaurantMenuState menuState,
  ) {
    return menuState.items.where((item) {
      final query = _searchQuery.trim().toLowerCase();

      final matchesSearch = query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query);

      bool matchesCategory;

      if (_selectedCategoryId == 'popular') {
        matchesCategory = item.isPopular;
      } else if (_selectedCategoryId == 'offers') {
        matchesCategory = item.hasOffer;
      } else {
        matchesCategory = item.categoryId == _selectedCategoryId;
      }

      return matchesSearch && matchesCategory;
    }).toList();
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

  int _cartQuantityFor(
    RestaurantMenuItem item,
    FoodGroceryCartState cart,
  ) {
    return cart.items
        .where(
          (cartItem) =>
              cartItem.cartType == FoodGroceryCartType.food &&
              cartItem.supplierId == widget.restaurant.id &&
              cartItem.productId == item.id,
        )
        .fold<int>(
          0,
          (total, cartItem) => total + cartItem.quantity,
        );
  }

  Future<bool> _confirmReplaceCart(
    String currentSupplierName,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final replace = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.cardDark : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'Start a new cart?',
            style: AppTextStyles.titleMedium.copyWith(
              color:
                  isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Your cart contains items from '
            '$currentSupplierName. Starting a new cart '
            'will remove those items.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.textSecondary
                  : AppColors.textSecondaryLight,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: Text(
                'KEEP CURRENT CART',
                style: AppTextStyles.labelLarge.copyWith(
                  color: isDark
                      ? AppColors.textSecondary
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: AppColors.backgroundDark,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              child: Text(
                'START NEW CART',
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    return replace ?? false;
  }

  Future<void> _addSimpleItem(
    RestaurantMenuItem item,
  ) async {
    if (!widget.restaurant.isOrderable) {
      _showMessage(
        'This restaurant is currently not accepting orders',
      );
      return;
    }

    if (!item.isAvailable) {
      _showMessage(
        'This item is currently unavailable',
      );
      return;
    }

    if (item.isCustomizable) {
      await context.pushNamed(
        RouteNames.foodGroceryFoodItemDetails,
        extra: <String, dynamic>{
          'restaurant': widget.restaurant,
          'item': item,
        },
      );
      return;
    }

    final cartItem = FoodGroceryCartItem(
      lineId: [
        widget.restaurant.id,
        item.id,
        'standard',
      ].join('_'),
      productId: item.id,
      supplierId: widget.restaurant.id,
      supplierName: widget.restaurant.name,
      name: item.name,
      cartType: FoodGroceryCartType.food,
      unitPrice: item.currentPrice,
      quantity: 1,
      imageUrl: item.imageUrl,
      variantId: 'standard',
      variantName: 'Standard',
      maximumQuantity: item.maximumQuantity,
    );

    final notifier = ref.read(foodGroceryCartProvider.notifier);

    final result = notifier.addItem(cartItem);

    if (result == CartAddResult.differentSupplier) {
      final currentCart = ref.read(foodGroceryCartProvider);

      final replace = await _confirmReplaceCart(
        currentCart.supplierName ?? 'another restaurant or store',
      );

      if (!replace || !mounted) {
        return;
      }

      notifier.replaceCartWith(cartItem);
    } else if (result == CartAddResult.outOfStock) {
      _showMessage(
        'Maximum quantity reached for ${item.name}',
      );
      return;
    }

    notifier.updateCharges(
      deliveryFee: widget.restaurant.deliveryFee,
      serviceFee: 0,
    );
  }

  Future<void> _selectMenuItem(
    RestaurantMenuItem item,
  ) async {
    if (!widget.restaurant.isOrderable) {
      _showMessage(
        'This restaurant is currently not accepting orders',
      );
      return;
    }

    if (!item.isAvailable) {
      _showMessage(
        'This item is currently unavailable',
      );
      return;
    }

    if (item.isCustomizable) {
      await context.pushNamed(
        RouteNames.foodGroceryFoodItemDetails,
        extra: <String, dynamic>{
          'restaurant': widget.restaurant,
          'item': item,
        },
      );
      return;
    }

    await _addSimpleItem(item);
  }

  void _decreaseSimpleItem(
    RestaurantMenuItem item,
  ) {
    final cart = ref.read(foodGroceryCartProvider);

    final matchingItems = cart.items
        .where(
          (cartItem) =>
              cartItem.cartType == FoodGroceryCartType.food &&
              cartItem.supplierId == widget.restaurant.id &&
              cartItem.productId == item.id,
        )
        .toList();

    if (matchingItems.isEmpty) {
      return;
    }

    if (matchingItems.length > 1) {
      context.pushNamed(
        RouteNames.foodGroceryCart,
      );
      return;
    }

    ref.read(foodGroceryCartProvider.notifier).decreaseQuantity(
          matchingItems.first.lineId,
        );
  }

  Future<void> _showOfferDetails() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              18,
              12,
              18,
              20,
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
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryGold.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.local_offer_rounded,
                        size: 21,
                        color: AppColors.primaryGoldDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.restaurant.offerText ?? 'Restaurant offer',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: isDark
                              ? AppColors.textPrimary
                              : AppColors.textPrimaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _OfferConditionRow(
                  icon: Icons.shopping_bag_outlined,
                  text: 'Minimum food order: €25.00',
                  isDark: isDark,
                ),
                _OfferConditionRow(
                  icon: Icons.restaurant_menu_rounded,
                  text: 'Applies to eligible menu items',
                  isDark: isDark,
                ),
                _OfferConditionRow(
                  icon: Icons.schedule_rounded,
                  text: 'Valid while the promotion is active',
                  isDark: isDark,
                ),
                _OfferConditionRow(
                  icon: Icons.info_outline_rounded,
                  text: 'Final eligibility will be validated at checkout',
                  isDark: isDark,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showRestaurantInformation() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              18,
              12,
              18,
              20,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
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
                  Text(
                    'Restaurant information',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: isDark
                          ? AppColors.textPrimary
                          : AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _InformationRow(
                    icon: Icons.location_on_outlined,
                    label: 'Address',
                    value: 'Sliema, Malta',
                    isDark: isDark,
                  ),
                  _InformationRow(
                    icon: Icons.schedule_rounded,
                    label: 'Opening hours',
                    value: '10:00 AM – 11:00 PM',
                    isDark: isDark,
                  ),
                  _InformationRow(
                    icon: Icons.restaurant_rounded,
                    label: 'Cuisine',
                    value: widget.restaurant.cuisineText,
                    isDark: isDark,
                  ),
                  _InformationRow(
                    icon: Icons.delivery_dining_rounded,
                    label: 'Delivery',
                    value:
                        '${widget.restaurant.estimatedDeliveryTime} • ${widget.restaurant.deliveryFeeText}',
                    isDark: isDark,
                  ),
                  _InformationRow(
                    icon: Icons.verified_user_outlined,
                    label: 'Business information',
                    value: 'Verified GOZOLT food supplier',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: AppColors.primaryGoldDark,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'For allergy or ingredient information, check the item details or contact the restaurant.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.textSecondary
                                  : AppColors.textSecondaryLight,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final menuState = ref.watch(
      restaurantMenuProvider(widget.restaurant.id),
    );

    final cart = ref.watch(foodGroceryCartProvider);

    final restaurantCartItems = cart.items.where(
      (cartItem) =>
          cartItem.cartType == FoodGroceryCartType.food &&
          cartItem.supplierId == widget.restaurant.id,
    );

    final restaurantCartItemCount = restaurantCartItems.fold<int>(
      0,
      (total, cartItem) => total + cartItem.quantity,
    );

    final restaurantCartSubtotal = restaurantCartItems.fold<double>(
      0,
      (total, cartItem) => total + cartItem.lineTotal,
    );

    final visibleItems = _visibleItems(menuState);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Column(
        children: [
          const FoodGroceryHeader(
            title: 'Restaurant Menu',
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primaryGoldDark,
              onRefresh: () async {
                ref
                    .read(
                      restaurantMenuProvider(
                        widget.restaurant.id,
                      ).notifier,
                    )
                    .refreshMenu();
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  restaurantCartItemCount > 0 ? 100 : 28,
                ),
                children: [
                  _RestaurantOverviewCard(
                    restaurant: widget.restaurant,
                    isDark: isDark,
                    isFavourite: _isFavourite,
                    onFavouritePressed: () {
                      setState(() {
                        _isFavourite = !_isFavourite;
                      });
                    },
                    onInformationPressed: _showRestaurantInformation,
                  ),
                  if (!widget.restaurant.isOrderable) ...[
                    const SizedBox(height: 12),
                    _UnavailableNotice(
                      restaurant: widget.restaurant,
                      isDark: isDark,
                    ),
                  ],
                  if (widget.restaurant.offerText != null) ...[
                    const SizedBox(height: 12),
                    _RestaurantOfferCard(
                      offerText: widget.restaurant.offerText!,
                      isDark: isDark,
                      onTap: _showOfferDetails,
                    ),
                  ],
                  const SizedBox(height: 12),
                  _MinimumOrderCard(
                    minimumOrder: _minimumOrder,
                    currentSubtotal: menuState.cartSubtotal,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Menu',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: isDark
                          ? AppColors.textPrimary
                          : AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _MenuSearchField(
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
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: menuState.categories.length,
                      separatorBuilder: (context, index) {
                        return const SizedBox(width: 8);
                      },
                      itemBuilder: (context, index) {
                        final category = menuState.categories[index];

                        return _MenuCategoryChip(
                          label: category.name,
                          selected: category.id == _selectedCategoryId,
                          isDark: isDark,
                          onTap: () {
                            setState(() {
                              _selectedCategoryId = category.id;
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (visibleItems.isEmpty)
                    _EmptyMenuResult(
                      isDark: isDark,
                      onClear: () {
                        _searchController.clear();

                        setState(() {
                          _searchQuery = '';
                          _selectedCategoryId = 'popular';
                        });
                      },
                    )
                  else
                    ...visibleItems.map(
                      (item) {
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: 12,
                          ),
                          child: _MenuItemCard(
                            item: item,
                            quantity: _cartQuantityFor(
                              item,
                              cart,
                            ),
                            restaurantOrderable: widget.restaurant.isOrderable,
                            isDark: isDark,
                            onTap: () {
                              _selectMenuItem(item);
                            },
                            onAdd: () {
                              _selectMenuItem(item);
                            },
                            onIncrease: () {
                              _addSimpleItem(item);
                            },
                            onDecrease: () {
                              _decreaseSimpleItem(item);
                            },
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: restaurantCartItemCount == 0
          ? null
          : SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  9,
                  16,
                  12,
                ),
                decoration: BoxDecoration(
                  color:
                      isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  border: Border(
                    top: BorderSide(
                      color:
                          isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                ),
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      context.pushNamed(
                        RouteNames.foodGroceryCart,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: AppColors.backgroundDark,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundDark
                                .withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$restaurantCartItemCount',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.backgroundDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '$restaurantCartItemCount ${restaurantCartItemCount == 1 ? 'Item' : 'Items'} • €$restaurantCartSubtotal',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.backgroundDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          'VIEW CART',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.backgroundDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 19,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _RestaurantOverviewCard extends StatelessWidget {
  const _RestaurantOverviewCard({
    required this.restaurant,
    required this.isDark,
    required this.isFavourite,
    required this.onFavouritePressed,
    required this.onInformationPressed,
  });

  final FoodRestaurant restaurant;
  final bool isDark;
  final bool isFavourite;
  final VoidCallback onFavouritePressed;
  final VoidCallback onInformationPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(17),
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
                height: 142,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withValues(alpha: 0.14),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: const Icon(
                  Icons.restaurant_menu_rounded,
                  size: 54,
                  color: AppColors.primaryGoldDark,
                ),
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Material(
                  color: isDark
                      ? AppColors.backgroundDark.withValues(alpha: 0.85)
                      : Colors.white.withValues(alpha: 0.94),
                  shape: const CircleBorder(),
                  child: IconButton(
                    onPressed: onFavouritePressed,
                    constraints: const BoxConstraints.tightFor(
                      width: 40,
                      height: 40,
                    ),
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      isFavourite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 22,
                      color: isFavourite
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
            padding: const EdgeInsets.all(14),
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
                        style: AppTextStyles.titleMedium.copyWith(
                          color: isDark
                              ? AppColors.textPrimary
                              : AppColors.textPrimaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: onInformationPressed,
                      tooltip: 'Restaurant information',
                      constraints: const BoxConstraints.tightFor(
                        width: 34,
                        height: 34,
                      ),
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.info_outline_rounded,
                        size: 20,
                        color: AppColors.primaryGoldDark,
                      ),
                    ),
                  ],
                ),
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
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _OverviewDetail(
                      icon: Icons.star_rounded,
                      value: '${restaurant.rating} (${restaurant.ratingCount})',
                      isDark: isDark,
                      iconColor: AppColors.primaryGoldDark,
                    ),
                    _OverviewDetail(
                      icon: Icons.schedule_rounded,
                      value: restaurant.estimatedDeliveryTime,
                      isDark: isDark,
                    ),
                    _OverviewDetail(
                      icon: Icons.location_on_outlined,
                      value: restaurant.distanceText,
                      isDark: isDark,
                    ),
                    _OverviewDetail(
                      icon: Icons.delivery_dining_rounded,
                      value: restaurant.deliveryFeeText,
                      isDark: isDark,
                    ),
                    _OverviewDetail(
                      icon: Icons.euro_rounded,
                      value: restaurant.priceLevel,
                      isDark: isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewDetail extends StatelessWidget {
  const _OverviewDetail({
    required this.icon,
    required this.value,
    required this.isDark,
    this.iconColor,
  });

  final IconData icon;
  final String value;
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
          value,
          style: AppTextStyles.labelSmall.copyWith(
            color:
                isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

class _RestaurantOfferCard extends StatelessWidget {
  const _RestaurantOfferCard({
    required this.offerText,
    required this.isDark,
    required this.onTap,
  });

  final String offerText;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryGold.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primaryGold.withValues(alpha: 0.55),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.local_offer_rounded,
                size: 21,
                color: AppColors.primaryGoldDark,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offerText,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.textPrimary
                            : AppColors.textPrimaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap to view offer conditions',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.textSecondary
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.primaryGoldDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MinimumOrderCard extends StatelessWidget {
  const _MinimumOrderCard({
    required this.minimumOrder,
    required this.currentSubtotal,
    required this.isDark,
  });

  final double minimumOrder;
  final double currentSubtotal;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final remainingAmount = minimumOrder - currentSubtotal;

    final reachedMinimum = remainingAmount <= 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Icon(
            reachedMinimum
                ? Icons.check_circle_rounded
                : Icons.shopping_bag_outlined,
            size: 20,
            color:
                reachedMinimum ? AppColors.success : AppColors.primaryGoldDark,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              reachedMinimum
                  ? 'Minimum food order reached'
                  : currentSubtotal <= 0
                      ? 'Minimum food order: €${minimumOrder.toStringAsFixed(2)}'
                      : 'Add €${remainingAmount.toStringAsFixed(2)} more to reach the minimum order',
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? AppColors.textSecondary
                    : AppColors.textSecondaryLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuSearchField extends StatelessWidget {
  const _MenuSearchField({
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
      style: AppTextStyles.bodyMedium.copyWith(
        color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
      ),
      decoration: InputDecoration(
        hintText: 'Search this menu',
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

class _MenuCategoryChip extends StatelessWidget {
  const _MenuCategoryChip({
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

class _MenuItemCard extends StatelessWidget {
  const _MenuItemCard({
    required this.item,
    required this.quantity,
    required this.restaurantOrderable,
    required this.isDark,
    required this.onTap,
    required this.onAdd,
    required this.onIncrease,
    required this.onDecrease,
  });

  final RestaurantMenuItem item;
  final int quantity;
  final bool restaurantOrderable;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  @override
  Widget build(BuildContext context) {
    final enabled = restaurantOrderable && item.isAvailable;

    return Opacity(
      opacity: enabled ? 1 : 0.62,
      child: Material(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 5,
                        children: [
                          if (item.isPopular)
                            const _MenuBadge(
                              text: 'Popular',
                              color: AppColors.primaryGoldDark,
                            ),
                          if (item.offerText != null)
                            _MenuBadge(
                              text: item.offerText!,
                              color: AppColors.success,
                            ),
                          if (!item.isAvailable)
                            const _MenuBadge(
                              text: 'Sold Out',
                              color: AppColors.error,
                            ),
                        ],
                      ),
                      if (item.isPopular ||
                          item.offerText != null ||
                          !item.isAvailable)
                        const SizedBox(height: 7),
                      Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isDark
                              ? AppColors.textPrimary
                              : AppColors.textPrimaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.textSecondary
                              : AppColors.textSecondaryLight,
                          height: 1.35,
                        ),
                      ),
                      if (item.dietaryTags.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          item.dietaryText,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      if (item.isCustomizable) ...[
                        const SizedBox(height: 5),
                        Text(
                          'Customizable',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.primaryGoldDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          Text(
                            '€${item.currentPrice.toStringAsFixed(2)}',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isDark
                                  ? AppColors.textPrimary
                                  : AppColors.textPrimaryLight,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (item.hasOffer) ...[
                            const SizedBox(width: 7),
                            Text(
                              '€${item.basePrice.toStringAsFixed(2)}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: isDark
                                    ? AppColors.textMuted
                                    : AppColors.textMutedLight,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 94,
                  child: Column(
                    children: [
                      Container(
                        width: 94,
                        height: 78,
                        decoration: BoxDecoration(
                          color: AppColors.primaryGold.withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.fastfood_rounded,
                          size: 33,
                          color: AppColors.primaryGoldDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (!item.isAvailable)
                        _DisabledAddButton(
                          text: 'SOLD OUT',
                          isDark: isDark,
                        )
                      else if (item.isCustomizable)
                        _AddButton(
                          text: 'ADD',
                          enabled: restaurantOrderable,
                          onPressed: onAdd,
                        )
                      else if (quantity == 0)
                        _AddButton(
                          text: 'ADD',
                          enabled: restaurantOrderable,
                          onPressed: onAdd,
                        )
                      else
                        _QuantityControl(
                          quantity: quantity,
                          enabled: restaurantOrderable,
                          onDecrease: onDecrease,
                          onIncrease: onIncrease,
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

class _MenuBadge extends StatelessWidget {
  const _MenuBadge({
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({
    required this.text,
    required this.enabled,
    required this.onPressed,
  });

  final String text;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      height: 34,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.backgroundDark,
          backgroundColor:
              enabled ? AppColors.primaryGold : AppColors.borderLight,
          side: BorderSide.none,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
        child: Text(
          text,
          style: AppTextStyles.labelSmall.copyWith(
            color:
                enabled ? AppColors.backgroundDark : AppColors.textMutedLight,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _DisabledAddButton extends StatelessWidget {
  const _DisabledAddButton({
    required this.text,
    required this.isDark,
  });

  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? AppColors.inputDark : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(
          color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  const _QuantityControl({
    required this.quantity,
    required this.enabled,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int quantity;
  final bool enabled;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.primaryGold,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          Expanded(
            child: IconButton(
              onPressed: enabled ? onDecrease : null,
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.remove_rounded,
                size: 17,
                color: AppColors.backgroundDark,
              ),
            ),
          ),
          Text(
            '$quantity',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.backgroundDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          Expanded(
            child: IconButton(
              onPressed: enabled ? onIncrease : null,
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.add_rounded,
                size: 17,
                color: AppColors.backgroundDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnavailableNotice extends StatelessWidget {
  const _UnavailableNotice({
    required this.restaurant,
    required this.isDark,
  });

  final FoodRestaurant restaurant;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 20,
            color: AppColors.error,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              '${restaurant.statusText}. This restaurant is currently not accepting orders.',
              style: AppTextStyles.bodySmall.copyWith(
                color:
                    isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferConditionRow extends StatelessWidget {
  const _OfferConditionRow({
    required this.icon,
    required this.text,
    required this.isDark,
  });

  final IconData icon;
  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: AppColors.primaryGoldDark,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? AppColors.textSecondary
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InformationRow extends StatelessWidget {
  const _InformationRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 19,
            color: AppColors.primaryGoldDark,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondary
                        : AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textPrimary
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMenuResult extends StatelessWidget {
  const _EmptyMenuResult({
    required this.isDark,
    required this.onClear,
  });

  final bool isDark;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        24,
        30,
        24,
        26,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 42,
            color: AppColors.primaryGoldDark,
          ),
          const SizedBox(height: 12),
          Text(
            'No menu items found',
            style: AppTextStyles.titleSmall.copyWith(
              color:
                  isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Try another search or menu category.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppColors.textSecondary
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: onClear,
            child: Text(
              'CLEAR SEARCH',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primaryGoldDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
