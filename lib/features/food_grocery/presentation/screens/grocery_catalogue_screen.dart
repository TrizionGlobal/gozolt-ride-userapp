import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/string_extensions.dart';
import '../../data/datasources/food_grocery_remote_datasource.dart';
import '../../data/models/food_grocery_cart.dart';
import '../../data/models/grocery_catalogue.dart';
import '../../data/models/grocery_store.dart';
import '../providers/food_grocery_cart_provider.dart';
import '../providers/grocery_catalogue_provider.dart';
import '../providers/food_grocery_delivery_provider.dart';
import '../widgets/food_grocery_header.dart';
import '../widgets/smart_product_image.dart';

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
  GroceryProductCategory? _selectedCategory;
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

      final matchesCategory = _selectedCategory == null ||
          product.categoryId == _selectedCategory!.id;

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

  int _cartQuantityForProduct(
    FoodGroceryCartState cartState,
    String productId,
  ) {
    if (cartState.supplierId != widget.store.id) return 0;
    return cartState.items
        .where((item) => item.productId == productId)
        .fold(0, (sum, item) => sum + item.quantity);
  }

  Future<bool> _confirmReplaceCart(String existingSupplierName) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.cardDark : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'Replace cart items?',
            style: AppTextStyles.titleMedium.copyWith(
              color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Your cart already contains items from $existingSupplierName. Would you like to replace them with items from ${widget.store.name}?',
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.textSecondary
                  : AppColors.textSecondaryLight,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                'CANCEL',
                style: AppTextStyles.labelLarge.copyWith(
                  color: isDark
                      ? AppColors.textSecondary
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                'REPLACE',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primaryGoldDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
    return confirmed ?? false;
  }

  Future<void> _addProduct(
    GroceryProduct product,
    GroceryCatalogueState catalogueState,
  ) async {
    final currentStore = catalogueState.store ?? widget.store;
    if (!currentStore.isOrderable) {
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

    final cartState = ref.read(foodGroceryCartProvider);
    final currentQuantity = _cartQuantityForProduct(cartState, product.id);

    if (currentQuantity >= product.allowedQuantity) {
      _showMessage(
        'Only ${product.allowedQuantity} available',
      );
      return;
    }

    final cartItem = FoodGroceryCartItem(
      lineId: '${widget.store.id}_${product.id}',
      productId: product.id,
      supplierId: widget.store.id,
      supplierName: currentStore.name,
      name: product.name,
      cartType: FoodGroceryCartType.grocery,
      unitPrice: product.currentPrice,
      quantity: 1,
      imageUrl: product.imageUrl,
      variantName: product.unitText.isNotEmpty ? product.unitText : null,
      maximumQuantity: product.allowedQuantity,
    );

    final cartNotifier = ref.read(foodGroceryCartProvider.notifier);
    final result = cartNotifier.addItem(cartItem);

    if (result == CartAddResult.differentSupplier) {
      final shouldReplace = await _confirmReplaceCart(
        cartState.supplierName ?? 'another store',
      );
      if (!shouldReplace || !mounted) {
        return;
      }
      cartNotifier.replaceCartWith(cartItem);
    } else if (result == CartAddResult.outOfStock) {
      _showMessage('Only ${product.allowedQuantity} available');
      return;
    }

    final selectedAddress =
        ref.read(foodGroceryDeliveryProvider).selectedAddress;
    final distance = currentStore.calculateDistanceTo(
          selectedAddress?.latitude,
          selectedAddress?.longitude,
        ) ??
        currentStore.distanceKm;
    final deliveryFee = double.parse((distance * 1.0).toStringAsFixed(2));

    cartNotifier.updateCharges(
      deliveryFee: deliveryFee,
      serviceFee: 0,
      distanceKm: distance,
    );

    ref
        .read(
          groceryCatalogueProvider(
            widget.store.id,
          ).notifier,
        )
        .addSimpleProduct(product);
  }

  void _decreaseProduct(GroceryProduct product) {
    final cartState = ref.read(foodGroceryCartProvider);
    if (cartState.supplierId == widget.store.id) {
      final matching = cartState.items
          .where((item) => item.productId == product.id)
          .toList();
      if (matching.isNotEmpty) {
        ref
            .read(foodGroceryCartProvider.notifier)
            .decreaseQuantity(matching.last.lineId);
      }
    }

    ref
        .read(
          groceryCatalogueProvider(
            widget.store.id,
          ).notifier,
        )
        .decreaseProduct(product);
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
    final cartState = ref.watch(foodGroceryCartProvider);
    final isCurrentStoreCart = cartState.supplierId == widget.store.id;
    final storeCartItemCount = isCurrentStoreCart ? cartState.itemCount : 0;
    final storeCartSubtotal = isCurrentStoreCart ? cartState.subtotal : 0.0;

    final visibleProducts = _visibleProducts(catalogueState);
    final deliveryState = ref.watch(foodGroceryDeliveryProvider);
    final userLat = deliveryState.selectedAddress?.latitude;
    final userLng = deliveryState.selectedAddress?.longitude;
    final currentStore = catalogueState.store ?? widget.store;
    final dynamicDistance = currentStore.dynamicDistanceText(userLat, userLng);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Column(
        children: [
          FoodGroceryHeader(
            title: _selectedCategory != null
                ? _selectedCategory!.name
                : 'Grocery Catalogue',
            onBackPressed: _selectedCategory != null
                ? () {
                    setState(() {
                      _selectedCategory = null;
                    });
                  }
                : null,
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
                  storeCartItemCount > 0 ? 100 : 28,
                ),
                children: [
                  if (_selectedCategory == null) ...[
                    _StoreOverviewCard(
                      store: currentStore,
                      isDark: isDark,
                      isFavourite: _isFavourite,
                      distanceText: dynamicDistance,
                      onFavouritePressed: () async {
                        final next = !_isFavourite;
                        setState(() {
                          _isFavourite = next;
                        });
                        try {
                          await ref
                              .read(foodGroceryRemoteDatasourceProvider)
                              .toggleFavourite(currentStore.id);
                        } catch (_) {
                          if (mounted) {
                            setState(() {
                              _isFavourite = !next;
                            });
                          }
                        }
                      },
                    ),
                    if (!currentStore.isOrderable) ...[
                      const SizedBox(height: 12),
                      _StoreUnavailableNotice(
                        isDark: isDark,
                      ),
                    ],
                    if (currentStore.offerText != null) ...[
                      const SizedBox(height: 12),
                      _GroceryOfferCard(
                        offerText: currentStore.offerText!,
                        isDark: isDark,
                        onTap: _showOfferDetails,
                      ),
                    ],
                    const SizedBox(height: 14),
                  ] else if (!currentStore.isOrderable) ...[
                    _StoreUnavailableNotice(
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                  ],
                  _ProductSearchField(
                    controller: _searchController,
                    storeName: currentStore.name.toTitleCase(),
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
                  if (catalogueState.isLoading && catalogueState.products.isEmpty && catalogueState.categories.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryGoldDark,
                        ),
                      ),
                    )
                  else if (catalogueState.errorMessage != null &&
                      catalogueState.products.isEmpty &&
                      catalogueState.categories.isEmpty)
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
                              catalogueState.errorMessage!,
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
                                    .read(
                                      groceryCatalogueProvider(
                                        widget.store.id,
                                      ).notifier,
                                    )
                                    .refreshCatalogue();
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
                  else if (_selectedCategory == null &&
                      _searchQuery.trim().isEmpty &&
                      catalogueState.categories.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Categories',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: isDark
                                ? AppColors.textPrimary
                                : AppColors.textPrimaryLight,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${catalogueState.categories.length} ${catalogueState.categories.length == 1 ? 'category' : 'categories'}',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: isDark
                                ? AppColors.textSecondary
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    GridView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: catalogueState.categories.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.92,
                      ),
                      itemBuilder: (context, index) {
                        final category = catalogueState.categories[index];
                        final itemCount = catalogueState.products
                            .where((p) => p.categoryId == category.id)
                            .length;
                        return _GroceryCategoryCard(
                          category: category,
                          productCount: itemCount,
                          isDark: isDark,
                          onTap: () {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                        );
                      },
                    ),
                  ] else ...[
                    if (_selectedCategory == null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Products',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: isDark
                                  ? AppColors.textPrimary
                                  : AppColors.textPrimaryLight,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${visibleProducts.length} ${visibleProducts.length == 1 ? 'item' : 'items'}',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: isDark
                                  ? AppColors.textSecondary
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (visibleProducts.isEmpty)
                      _EmptyCatalogueState(
                        isDark: isDark,
                        onClear: () {
                          _searchController.clear();

                          setState(() {
                            _searchQuery = '';
                            _selectedCategory = null;
                          });
                        },
                      )
                    else
                      ListView.separated(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: visibleProducts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final product = visibleProducts[index];
                          return _GroceryProductCard(
                            product: product,
                            quantity: _cartQuantityForProduct(
                              cartState,
                              product.id,
                            ),
                            storeOrderable: currentStore.isOrderable,
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
                              _decreaseProduct(product);
                            },
                          );
                        },
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: storeCartItemCount == 0
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
                            '$storeCartItemCount',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.backgroundDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '$storeCartItemCount ${storeCartItemCount == 1 ? 'Item' : 'Items'} • €${storeCartSubtotal.toStringAsFixed(2)}',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.backgroundDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          'View Cart',
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
    this.distanceText,
    required this.onFavouritePressed,
  });

  final GroceryStore store;
  final bool isDark;
  final bool isFavourite;
  final String? distanceText;
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
              SmartProductImage(
                imageUrl: store.imageUrl,
                width: double.infinity,
                height: 142,
                fallbackIcon: Icons.storefront_rounded,
                customBorderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              Positioned(
                left: 10,
                bottom: 10,
                child: _CatalogueBadge(
                  text: store.statusText,
                  backgroundColor: _storeStatusColor(store.effectiveStatus),
                  textColor: Colors.white,
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
                        store.name.toTitleCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: isDark
                              ? AppColors.textPrimary
                              : AppColors.textPrimaryLight,
                          fontWeight: FontWeight.w700,
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
                      value: store.formattedRatingText,
                      iconColor: AppColors.primaryGoldDark,
                      isDark: isDark,
                    ),
                    _StoreDetailItem(
                      icon: Icons.schedule_rounded,
                      value: '${store.preparationTime} prep',
                      isDark: isDark,
                    ),
                    if (distanceText != null && distanceText!.isNotEmpty)
                      _StoreDetailItem(
                        icon: Icons.location_on_outlined,
                        value: distanceText!,
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

class _GroceryCategoryCard extends StatelessWidget {
  const _GroceryCategoryCard({
    required this.category,
    required this.productCount,
    required this.isDark,
    required this.onTap,
  });

  final GroceryProductCategory category;
  final int productCount;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
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
              Expanded(
                child: SmartProductImage(
                  imageUrl: category.imageUrl,
                  width: double.infinity,
                  height: double.infinity,
                  fallbackIcon: Icons.category_rounded,
                  customBorderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.textPrimary
                            : AppColors.textPrimaryLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$productCount ${productCount == 1 ? 'product' : 'products'}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primaryGoldDark,
                        fontWeight: FontWeight.w600,
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SmartProductImage(
                  imageUrl: product.imageUrl,
                  width: 90,
                  height: 90,
                  fallbackIcon: Icons.shopping_basket_rounded,
                  customBorderRadius: BorderRadius.circular(11),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        product.name.toTitleCase(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isDark
                              ? AppColors.textPrimary
                              : AppColors.textPrimaryLight,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      if (product.displayBrand != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          product.displayBrand!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: isDark
                                ? AppColors.textSecondary
                                : AppColors.textSecondaryLight,
                            fontSize: 11,
                          ),
                        ),
                      ],
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.backgroundDark
                                  : AppColors.backgroundLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              product.unitTypeText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: isDark
                                    ? AppColors.textSecondary
                                    : AppColors.textSecondaryLight,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: (product.stockStatus ==
                                          GroceryProductStockStatus.outOfStock
                                      ? AppColors.error
                                      : product.stockStatus ==
                                              GroceryProductStockStatus.lowStock
                                          ? AppColors.warning
                                          : AppColors.success)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
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
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
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
                                overflow: TextOverflow.ellipsis,
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
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 96,
                  child: !storeOrderable
                      ? _CatalogueDisabledButton(
                          text: 'Store Closed',
                          isDark: isDark,
                        )
                      : !available
                          ? _CatalogueDisabledButton(
                              text: product.stockStatus ==
                                      GroceryProductStockStatus.outOfStock
                                  ? 'Out of Stock'
                                  : 'Unavailable',
                              isDark: isDark,
                            )
                          : requiresSelection
                              ? _CatalogueAddButton(
                                  text: 'Select Pack',
                                  onPressed: onAdd,
                                )
                              : quantity == 0
                                  ? _CatalogueAddButton(
                                      text: 'Add',
                                      onPressed: onAdd,
                                    )
                                  : _CatalogueQuantityControl(
                                      quantity: quantity,
                                      onDecrease: onDecrease,
                                      onIncrease: onIncrease,
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
