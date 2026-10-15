import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/models/grocery_catalogue.dart';
import '../../data/models/grocery_store.dart';
import '../providers/grocery_catalogue_provider.dart';
import '../widgets/food_grocery_header.dart';

class GroceryCatalogueScreen extends ConsumerStatefulWidget {
  const GroceryCatalogueScreen({
    super.key,
    required this.store,
  });

  final GroceryStore store;

  @override
  ConsumerState<GroceryCatalogueScreen> createState() =>
      _GroceryCatalogueScreenState();
}

class _GroceryCatalogueScreenState
    extends ConsumerState<GroceryCatalogueScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedCategoryId = 'popular';
  bool _isFavourite = false;

  @override
  void initState() {
    super.initState();
    _isFavourite = widget.store.isFavourite;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<GroceryProduct> _visibleProducts(
    GroceryCatalogueState state,
  ) {
    return state.products.where((product) {
      final query = _searchQuery.trim().toLowerCase();

      final matchesSearch = query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.brand.toLowerCase().contains(query) ||
          product.description.toLowerCase().contains(query) ||
          product.unitText.toLowerCase().contains(query);

      bool matchesCategory;

      if (_selectedCategoryId == 'popular') {
        matchesCategory = true;
      } else if (_selectedCategoryId == 'offers') {
        matchesCategory = product.hasOffer;
      } else {
        matchesCategory = product.categoryId == _selectedCategoryId;
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

  void _openProductDetails(GroceryProduct product) {
    context.pushNamed(
      RouteNames.foodGroceryProductDetails,
      extra: <String, dynamic>{
        'store': widget.store,
        'product': product,
      },
    );
  }

  void _addProduct(
    GroceryProduct product,
    GroceryCatalogueState catalogueState,
  ) {
    if (!widget.store.isOrderable) {
      _showMessage(
        'This store is no longer accepting orders',
      );
      return;
    }

    if (product.stockStatus == GroceryProductStockStatus.outOfStock) {
      _showMessage(
        '${product.name} is currently out of stock',
      );
      return;
    }

    if (product.hasVariants ||
        product.unitType == GroceryProductUnitType.weight) {
      _openProductDetails(product);
      return;
    }

    final currentQuantity = catalogueState.quantityFor(product.id);

    if (currentQuantity >= product.allowedQuantity) {
      _showMessage(
        'Only ${product.allowedQuantity} available',
      );
      return;
    }

    ref
        .read(
          groceryCatalogueProvider(
            widget.store.id,
          ).notifier,
        )
        .addSimpleProduct(product);
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
                        widget.store.offerText ?? 'Store promotion',
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
                _OfferRule(
                  icon: Icons.shopping_bag_outlined,
                  text: 'Offer applies only to eligible products',
                  isDark: isDark,
                ),
                _OfferRule(
                  icon: Icons.payments_outlined,
                  text: 'Minimum-order conditions may apply',
                  isDark: isDark,
                ),
                _OfferRule(
                  icon: Icons.schedule_rounded,
                  text: 'Valid while the promotion remains active',
                  isDark: isDark,
                ),
                _OfferRule(
                  icon: Icons.verified_outlined,
                  text: 'Final eligibility is validated at checkout',
                  isDark: isDark,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final catalogueState = ref.watch(
      groceryCatalogueProvider(widget.store.id),
    );

    final visibleProducts = _visibleProducts(catalogueState);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Column(
        children: [
          const FoodGroceryHeader(
            title: 'Grocery Catalogue',
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primaryGoldDark,
              onRefresh: () async {
                ref
                    .read(
                      groceryCatalogueProvider(
                        widget.store.id,
                      ).notifier,
                    )
                    .refreshCatalogue();
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  catalogueState.cartItemCount > 0 ? 100 : 28,
                ),
                children: [
                  _StoreOverviewCard(
                    store: widget.store,
                    isDark: isDark,
                    isFavourite: _isFavourite,
                    onFavouritePressed: () {
                      setState(() {
                        _isFavourite = !_isFavourite;
                      });
                    },
                  ),
                  if (!widget.store.isOrderable) ...[
                    const SizedBox(height: 12),
                    _StoreUnavailableNotice(
                      isDark: isDark,
                    ),
                  ],
                  if (widget.store.offerText != null) ...[
                    const SizedBox(height: 12),
                    _GroceryOfferCard(
                      offerText: widget.store.offerText!,
                      isDark: isDark,
                      onTap: _showOfferDetails,
                    ),
                  ],
                  const SizedBox(height: 12),
                  _MinimumOrderProgress(
                    minimumOrder: widget.store.minimumOrder,
                    currentSubtotal: catalogueState.cartSubtotal,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Products',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: isDark
                          ? AppColors.textPrimary
                          : AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _ProductSearchField(
                    controller: _searchController,
                    storeName: widget.store.name,
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
                      itemCount: catalogueState.categories.length,
                      separatorBuilder: (context, index) {
                        return const SizedBox(
                          width: 8,
                        );
                      },
                      itemBuilder: (context, index) {
                        final category = catalogueState.categories[index];

                        return _ProductCategoryChip(
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
                  if (visibleProducts.isEmpty)
                    _EmptyCatalogueState(
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
                    LayoutBuilder(
                      builder: (
                        context,
                        constraints,
                      ) {
                        final crossAxisCount =
                            constraints.maxWidth >= 700 ? 3 : 2;

                        const spacing = 12.0;

                        final cardWidth = (constraints.maxWidth -
                                (spacing * (crossAxisCount - 1))) /
                            crossAxisCount;

                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: visibleProducts.map(
                            (product) {
                              return SizedBox(
                                width: cardWidth,
                                child: _GroceryProductCard(
                                  product: product,
                                  quantity: catalogueState.quantityFor(
                                    product.id,
                                  ),
                                  storeOrderable: widget.store.isOrderable,
                                  isDark: isDark,
                                  onTap: () {
                                    _openProductDetails(
                                      product,
                                    );
                                  },
                                  onAdd: () {
                                    _addProduct(
                                      product,
                                      catalogueState,
                                    );
                                  },
                                  onIncrease: () {
                                    _addProduct(
                                      product,
                                      catalogueState,
                                    );
                                  },
                                  onDecrease: () {
                                    ref
                                        .read(
                                          groceryCatalogueProvider(
                                            widget.store.id,
                                          ).notifier,
                                        )
                                        .decreaseProduct(
                                          product,
                                        );
                                  },
                                ),
                              );
                            },
                          ).toList(),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: catalogueState.cartItemCount == 0
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          15,
                        ),
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
                            color: AppColors.backgroundDark.withValues(
                              alpha: 0.10,
                            ),
                            borderRadius: BorderRadius.circular(
                              20,
                            ),
                          ),
                          child: Text(
                            '${catalogueState.cartItemCount}',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.backgroundDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${catalogueState.cartItemCount} ${catalogueState.cartItemCount == 1 ? 'Item' : 'Items'} • €${catalogueState.cartSubtotal.toStringAsFixed(2)}',
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

class _StoreOverviewCard extends StatelessWidget {
  const _StoreOverviewCard({
    required this.store,
    required this.isDark,
    required this.isFavourite,
    required this.onFavouritePressed,
  });

  final GroceryStore store;
  final bool isDark;
  final bool isFavourite;
  final VoidCallback onFavouritePressed;

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
                width: double.infinity,
                height: 142,
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withValues(alpha: 0.13),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  size: 54,
                  color: AppColors.primaryGoldDark,
                ),
              ),
              Positioned(
                left: 10,
                bottom: 10,
                child: _CatalogueBadge(
                  text: store.statusText,
                  backgroundColor: _storeStatusColor(store.status),
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
                        store.name,
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
                    Text(
                      store.storeType,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primaryGoldDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
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
                const SizedBox(height: 11),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _StoreDetailItem(
                      icon: Icons.star_rounded,
                      value: '${store.rating} (${store.ratingCount})',
                      iconColor: AppColors.primaryGoldDark,
                      isDark: isDark,
                    ),
                    _StoreDetailItem(
                      icon: Icons.schedule_rounded,
                      value: store.estimatedDeliveryTime,
                      isDark: isDark,
                    ),
                    _StoreDetailItem(
                      icon: Icons.delivery_dining_rounded,
                      value: store.deliveryFeeText,
                      isDark: isDark,
                    ),
                    _StoreDetailItem(
                      icon: Icons.location_on_outlined,
                      value: store.distanceText,
                      isDark: isDark,
                    ),
                    _StoreDetailItem(
                      icon: Icons.shopping_bag_outlined,
                      value: store.minimumOrderText,
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

Color _storeStatusColor(
  GroceryStoreOperationalStatus status,
) {
  switch (status) {
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

class _StoreDetailItem extends StatelessWidget {
  const _StoreDetailItem({
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

class _GroceryOfferCard extends StatelessWidget {
  const _GroceryOfferCard({
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
      color: AppColors.primaryGold.withValues(alpha: 0.11),
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

class _MinimumOrderProgress extends StatelessWidget {
  const _MinimumOrderProgress({
    required this.minimumOrder,
    required this.currentSubtotal,
    required this.isDark,
  });

  final double minimumOrder;
  final double currentSubtotal;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final remaining = minimumOrder - currentSubtotal;

    final reached = remaining <= 0;

    final progress = minimumOrder <= 0
        ? 1.0
        : (currentSubtotal / minimumOrder).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                reached
                    ? Icons.check_circle_rounded
                    : Icons.shopping_bag_outlined,
                size: 19,
                color: reached ? AppColors.success : AppColors.primaryGoldDark,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  reached
                      ? 'Minimum grocery order reached'
                      : currentSubtotal <= 0
                          ? 'Minimum grocery order: €${minimumOrder.toStringAsFixed(2)}'
                          : 'Add €${remaining.toStringAsFixed(2)} more to reach the minimum order',
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
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor:
                  isDark ? AppColors.borderDark : AppColors.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                reached ? AppColors.success : AppColors.primaryGold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductSearchField extends StatelessWidget {
  const _ProductSearchField({
    required this.controller,
    required this.storeName,
    required this.isDark,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String storeName;
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
        hintText: 'Search products in $storeName',
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

class _ProductCategoryChip extends StatelessWidget {
  const _ProductCategoryChip({
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

class _GroceryProductCard extends StatelessWidget {
  const _GroceryProductCard({
    required this.product,
    required this.quantity,
    required this.storeOrderable,
    required this.isDark,
    required this.onTap,
    required this.onAdd,
    required this.onIncrease,
    required this.onDecrease,
  });

  final GroceryProduct product;
  final int quantity;
  final bool storeOrderable;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  @override
  Widget build(BuildContext context) {
    final available = storeOrderable &&
        product.isActive &&
        product.stockStatus != GroceryProductStockStatus.outOfStock;

    final requiresSelection = product.hasVariants ||
        product.unitType == GroceryProductUnitType.weight;

    return Opacity(
      opacity: available ? 1 : 0.62,
      child: Material(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
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
                      height: 94,
                      decoration: BoxDecoration(
                        color: AppColors.primaryGold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.shopping_basket_rounded,
                        size: 36,
                        color: AppColors.primaryGoldDark,
                      ),
                    ),
                    if (product.offerText != null)
                      Positioned(
                        left: 6,
                        top: 6,
                        child: _CatalogueBadge(
                          text: product.offerText!,
                          backgroundColor: AppColors.primaryGold,
                          textColor: AppColors.backgroundDark,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 9),
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textPrimary
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  product.brand,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondary
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  product.unitTypeText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSmall.copyWith(
                    color:
                        isDark ? AppColors.textMuted : AppColors.textMutedLight,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  product.stockText,
                  maxLines: 1,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: product.stockStatus ==
                            GroceryProductStockStatus.outOfStock
                        ? AppColors.error
                        : product.stockStatus ==
                                GroceryProductStockStatus.lowStock
                            ? AppColors.warning
                            : AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Text(
                      '€${product.currentPrice.toStringAsFixed(2)}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.textPrimary
                            : AppColors.textPrimaryLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (product.hasOffer) ...[
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          '€${product.basePrice.toStringAsFixed(2)}',
                          maxLines: 1,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: isDark
                                ? AppColors.textMuted
                                : AppColors.textMutedLight,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 9),
                if (!available)
                  _CatalogueDisabledButton(
                    text: product.stockStatus ==
                            GroceryProductStockStatus.outOfStock
                        ? 'OUT OF STOCK'
                        : 'UNAVAILABLE',
                    isDark: isDark,
                  )
                else if (requiresSelection)
                  _CatalogueAddButton(
                    text: 'SELECT',
                    onPressed: onAdd,
                  )
                else if (quantity == 0)
                  _CatalogueAddButton(
                    text: 'ADD',
                    onPressed: onAdd,
                  )
                else
                  _CatalogueQuantityControl(
                    quantity: quantity,
                    onDecrease: onDecrease,
                    onIncrease: onIncrease,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CatalogueAddButton extends StatelessWidget {
  const _CatalogueAddButton({
    required this.text,
    required this.onPressed,
  });

  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 34,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGold,
          foregroundColor: AppColors.backgroundDark,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          text,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.backgroundDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _CatalogueDisabledButton extends StatelessWidget {
  const _CatalogueDisabledButton({
    required this.text,
    required this.isDark,
  });

  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? AppColors.inputDark : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(10),
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

class _CatalogueQuantityControl extends StatelessWidget {
  const _CatalogueQuantityControl({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.primaryGold,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: IconButton(
              onPressed: onDecrease,
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
              onPressed: onIncrease,
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

class _CatalogueBadge extends StatelessWidget {
  const _CatalogueBadge({
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
        horizontal: 7,
        vertical: 4,
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

class _StoreUnavailableNotice extends StatelessWidget {
  const _StoreUnavailableNotice({
    required this.isDark,
  });

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(13),
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
              'This store is no longer accepting orders.',
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

class _OfferRule extends StatelessWidget {
  const _OfferRule({
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

class _EmptyCatalogueState extends StatelessWidget {
  const _EmptyCatalogueState({
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
            'No grocery products found',
            style: AppTextStyles.titleSmall.copyWith(
              color:
                  isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Try another product name or category.',
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
