import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/models/grocery_catalogue.dart';
import '../../data/models/grocery_product_details.dart';
import '../../data/models/grocery_store.dart';
import '../providers/grocery_product_details_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../data/models/food_grocery_cart.dart';
import '../providers/food_grocery_cart_provider.dart';

class GroceryProductDetailsScreen extends ConsumerWidget {
  const GroceryProductDetailsScreen({
    super.key,
    required this.store,
    required this.product,
  });

  final GroceryStore store;
  final GroceryProduct product;

  void _showMessage(
    BuildContext context,
    String message,
  ) {
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

  void _selectOption(
    BuildContext context,
    WidgetRef ref,
    GroceryProductSelectionOption option,
  ) {
    final error = ref
        .read(
          groceryProductDetailsProvider(
            product,
          ).notifier,
        )
        .selectOption(option);

    if (error != null) {
      _showMessage(context, error);
    }
  }

  Future<bool> _confirmReplaceCart(
    BuildContext context,
    String currentStoreName,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final shouldReplace = await showDialog<bool>(
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
            'Your cart contains products from $currentStoreName. '
            'Starting a new cart will remove those products.',
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

    return shouldReplace ?? false;
  }

  Future<void> _addToCart(
    BuildContext context,
    WidgetRef ref,
    GroceryProductDetailsState state,
  ) async {
    if (!store.isOrderable) {
      _showMessage(
        context,
        'This store is no longer accepting orders',
      );
      return;
    }

    if (!product.isActive ||
        product.stockStatus == GroceryProductStockStatus.outOfStock) {
      _showMessage(
        context,
        'This product is currently unavailable',
      );
      return;
    }

    if (!state.selectionComplete || state.selectedOption == null) {
      _showMessage(
        context,
        product.unitType == GroceryProductUnitType.weight
            ? 'Please select an approximate weight'
            : 'Please select a product option',
      );
      return;
    }

    final selectedOption = state.selectedOption!;

    final cartItem = FoodGroceryCartItem(
      lineId: [
        store.id,
        product.id,
        selectedOption.id,
      ].join('_'),
      productId: product.id,
      supplierId: store.id,
      supplierName: store.name,
      name: product.name,
      cartType: FoodGroceryCartType.grocery,
      unitPrice: state.selectedUnitPrice,
      quantity: state.quantity,
      imageUrl: product.imageUrl,
      variantId: selectedOption.id,
      variantName: '${selectedOption.name} • ${selectedOption.unitText}',
      maximumQuantity: state.allowedQuantity,
      isEstimatedWeight: selectedOption.isEstimatedWeight,
    );

    final cartNotifier = ref.read(foodGroceryCartProvider.notifier);

    final result = cartNotifier.addItem(cartItem);

    if (result == CartAddResult.differentSupplier) {
      final currentCart = ref.read(foodGroceryCartProvider);

      final shouldReplace = await _confirmReplaceCart(
        context,
        currentCart.supplierName ?? 'another store',
      );

      if (!shouldReplace || !context.mounted) {
        return;
      }

      cartNotifier.replaceCartWith(cartItem);
    } else if (result == CartAddResult.outOfStock) {
      _showMessage(
        context,
        'The selected quantity is no longer available',
      );
      return;
    }

    cartNotifier.updateCharges(
      deliveryFee: store.deliveryFee,
      serviceFee: 0,
    );

    ref
        .read(
          groceryProductDetailsProvider(product).notifier,
        )
        .reset();

    if (!context.mounted) return;

    context.pushNamed(
      RouteNames.foodGroceryCart,
    );
  }

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final state = ref.watch(
      groceryProductDetailsProvider(product),
    );

    final canAdd = store.isOrderable &&
        product.isActive &&
        product.stockStatus != GroceryProductStockStatus.outOfStock &&
        state.selectionComplete;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Column(
        children: [
          _ProductDetailsHeader(
            productName: product.name,
            isFavourite: state.isFavourite,
            onFavouritePressed: () {
              ref
                  .read(
                    groceryProductDetailsProvider(
                      product,
                    ).notifier,
                  )
                  .toggleFavourite();
            },
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                28,
              ),
              children: [
                _ProductOverviewCard(
                  product: product,
                  state: state,
                  isDark: isDark,
                ),
                if (!store.isOrderable) ...[
                  const SizedBox(height: 12),
                  _ProductWarning(
                    text: 'This store is no longer accepting orders.',
                    isDark: isDark,
                  ),
                ],
                if (product.stockStatus ==
                    GroceryProductStockStatus.outOfStock) ...[
                  const SizedBox(height: 12),
                  _ProductWarning(
                    text: 'This product is currently out of stock.',
                    isDark: isDark,
                  ),
                ],
                if (state.requiresSelection) ...[
                  const SizedBox(height: 14),
                  _SelectionCard(
                    state: state,
                    isDark: isDark,
                    onSelected: (option) {
                      _selectOption(
                        context,
                        ref,
                        option,
                      );
                    },
                  ),
                ],
                const SizedBox(height: 12),
                _QuantityCard(
                  quantity: state.quantity,
                  maximumQuantity: state.allowedQuantity,
                  enabled: state.selectionComplete,
                  isDark: isDark,
                  onDecrease: () {
                    ref
                        .read(
                          groceryProductDetailsProvider(
                            product,
                          ).notifier,
                        )
                        .decreaseQuantity();
                  },
                  onIncrease: () {
                    if (state.quantity >= state.allowedQuantity) {
                      _showMessage(
                        context,
                        'Only ${state.allowedQuantity} available',
                      );
                      return;
                    }

                    ref
                        .read(
                          groceryProductDetailsProvider(
                            product,
                          ).notifier,
                        )
                        .increaseQuantity();
                  },
                ),
                const SizedBox(height: 12),
                _DynamicProductTotal(
                  state: state,
                  isDark: isDark,
                ),
                if (state.selectedOption?.isEstimatedWeight ?? false) ...[
                  const SizedBox(height: 10),
                  _EstimatedWeightNotice(
                    isDark: isDark,
                  ),
                ],
                const SizedBox(height: 16),
                _DetailsExpansionCard(
                  title: 'Product Information',
                  icon: Icons.info_outline_rounded,
                  isDark: isDark,
                  children: [
                    _InformationRow(
                      label: 'Brand',
                      value: product.brand,
                      isDark: isDark,
                    ),
                    _InformationRow(
                      label: 'Category',
                      value: _categoryName(
                        product.categoryId,
                      ),
                      isDark: isDark,
                    ),
                    _InformationRow(
                      label: 'Selected unit',
                      value: state.selectedUnitText,
                      isDark: isDark,
                    ),
                    _InformationRow(
                      label: 'Country of origin',
                      value: 'Supplier-provided information',
                      isDark: isDark,
                    ),
                    _InformationRow(
                      label: 'Manufacturer',
                      value: product.brand,
                      isDark: isDark,
                      showBottomSpacing: false,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _DetailsExpansionCard(
                  title: 'Ingredients',
                  icon: Icons.receipt_long_outlined,
                  isDark: isDark,
                  children: [
                    Text(
                      'Ingredient information will be provided by the supplier and loaded from the product catalogue.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.textSecondary
                            : AppColors.textSecondaryLight,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _DetailsExpansionCard(
                  title: 'Nutritional Information',
                  icon: Icons.monitor_heart_outlined,
                  isDark: isDark,
                  children: [
                    _InformationRow(
                      label: 'Calories',
                      value: 'Supplier provided',
                      isDark: isDark,
                    ),
                    _InformationRow(
                      label: 'Protein',
                      value: 'Supplier provided',
                      isDark: isDark,
                    ),
                    _InformationRow(
                      label: 'Carbohydrates',
                      value: 'Supplier provided',
                      isDark: isDark,
                    ),
                    _InformationRow(
                      label: 'Fat',
                      value: 'Supplier provided',
                      isDark: isDark,
                      showBottomSpacing: false,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _DetailsExpansionCard(
                  title: 'Allergens & Storage',
                  icon: Icons.warning_amber_rounded,
                  isDark: isDark,
                  initiallyExpanded: true,
                  children: [
                    _InformationRow(
                      label: 'Allergens',
                      value:
                          'Check supplier-provided allergen information before purchasing.',
                      isDark: isDark,
                    ),
                    _InformationRow(
                      label: 'Storage',
                      value:
                          'Follow the storage instructions printed on the product packaging.',
                      isDark: isDark,
                      showBottomSpacing: false,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'You Might Also Like',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: isDark
                        ? AppColors.textPrimary
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 130,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _RelatedProductCard(
                        name: 'Greek Yoghurt',
                        price: '€2.20',
                        isDark: isDark,
                        onTap: () {
                          _showMessage(
                            context,
                            'Greek Yoghurt details will open here',
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      _RelatedProductCard(
                        name: 'Fresh Butter',
                        price: '€2.85',
                        isDark: isDark,
                        onTap: () {
                          _showMessage(
                            context,
                            'Fresh Butter details will open here',
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      _RelatedProductCard(
                        name: 'Local Cheese',
                        price: '€3.40',
                        isDark: isDark,
                        onTap: () {
                          _showMessage(
                            context,
                            'Local Cheese details will open here',
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            16,
            9,
            16,
            12,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
          ),
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: canAdd
                  ? () {
                      _addToCart(
                        context,
                        ref,
                        state,
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                disabledBackgroundColor:
                    isDark ? AppColors.inputDark : AppColors.borderLight,
                foregroundColor: AppColors.backgroundDark,
                disabledForegroundColor:
                    isDark ? AppColors.textMuted : AppColors.textMutedLight,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Text(
                'ADD TO CART — €${state.totalPrice.toStringAsFixed(2)}',
                style: AppTextStyles.labelLarge.copyWith(
                  color: canAdd
                      ? AppColors.backgroundDark
                      : isDark
                          ? AppColors.textMuted
                          : AppColors.textMutedLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _categoryName(String categoryId) {
    return categoryId
        .split('-')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' & ');
  }
}

class _ProductDetailsHeader extends StatelessWidget {
  const _ProductDetailsHeader({
    required this.productName,
    required this.isFavourite,
    required this.onFavouritePressed,
  });

  final String productName;
  final bool isFavourite;
  final VoidCallback onFavouritePressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryGoldDark,
            AppColors.primaryGold,
          ],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            18,
          ),
          child: Row(
            children: [
              Material(
                color: AppColors.backgroundDark.withValues(alpha: 0.14),
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: () => context.pop(),
                  customBorder: const CircleBorder(),
                  child: const SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(
                      Icons.close_rounded,
                      size: 21,
                      color: AppColors.backgroundDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.backgroundDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Material(
                color: AppColors.backgroundDark.withValues(alpha: 0.14),
                shape: const CircleBorder(),
                child: IconButton(
                  onPressed: onFavouritePressed,
                  constraints: const BoxConstraints.tightFor(
                    width: 36,
                    height: 36,
                  ),
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    isFavourite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 20,
                    color: isFavourite
                        ? AppColors.error
                        : AppColors.backgroundDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductOverviewCard extends StatelessWidget {
  const _ProductOverviewCard({
    required this.product,
    required this.state,
    required this.isDark,
  });

  final GroceryProduct product;
  final GroceryProductDetailsState state;
  final bool isDark;

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
                height: 190,
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withValues(alpha: 0.13),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: const Icon(
                  Icons.shopping_basket_rounded,
                  size: 62,
                  color: AppColors.primaryGoldDark,
                ),
              ),
              if (product.offerText != null)
                Positioned(
                  left: 12,
                  top: 12,
                  child: _DetailsBadge(
                    text: product.offerText!,
                    color: AppColors.primaryGold,
                    textColor: AppColors.backgroundDark,
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: isDark
                        ? AppColors.textPrimary
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  product.brand,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primaryGoldDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  product.description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondary
                        : AppColors.textSecondaryLight,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 7,
                  children: [
                    _DetailsBadge(
                      text: state.selectedUnitText,
                      color: isDark
                          ? AppColors.inputDark
                          : AppColors.backgroundLight,
                      textColor: isDark
                          ? AppColors.textPrimary
                          : AppColors.textPrimaryLight,
                    ),
                    _DetailsBadge(
                      text: product.stockText,
                      color: _stockColor(
                        product.stockStatus,
                      ).withValues(alpha: 0.12),
                      textColor: _stockColor(
                        product.stockStatus,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 11),
                Row(
                  children: [
                    Text(
                      '€${state.selectedUnitPrice.toStringAsFixed(2)}',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: isDark
                            ? AppColors.textPrimary
                            : AppColors.textPrimaryLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (state.selectedOriginalPrice != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '€${state.selectedOriginalPrice!.toStringAsFixed(2)}',
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
        ],
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({
    required this.state,
    required this.isDark,
    required this.onSelected,
  });

  final GroceryProductDetailsState state;
  final bool isDark;
  final ValueChanged<GroceryProductSelectionOption> onSelected;

  @override
  Widget build(BuildContext context) {
    final isWeight = state.product.unitType == GroceryProductUnitType.weight;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: state.selectionComplete
              ? isDark
                  ? AppColors.borderDark
                  : AppColors.borderLight
              : AppColors.primaryGold,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isWeight ? 'Select Approximate Weight' : 'Select Size / Pack',
            style: AppTextStyles.titleSmall.copyWith(
              color:
                  isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Required • Select 1',
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppColors.textSecondary
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 10),
          ...state.selectionOptions.map(
            (option) {
              final selected = state.selectedOptionId == option.id;

              return _SelectionOptionTile(
                option: option,
                selected: selected,
                isDark: isDark,
                onTap: () {
                  onSelected(option);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SelectionOptionTile extends StatelessWidget {
  const _SelectionOptionTile({
    required this.option,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final GroceryProductSelectionOption option;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: option.isAvailable ? 1 : 0.52,
      child: Material(
        color: selected
            ? AppColors.primaryGold.withValues(alpha: 0.10)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: option.isAvailable ? onTap : null,
          borderRadius: BorderRadius.circular(11),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 10,
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  size: 21,
                  color: selected
                      ? AppColors.primaryGoldDark
                      : isDark
                          ? AppColors.textMuted
                          : AppColors.textMutedLight,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.name,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.textPrimary
                              : AppColors.textPrimaryLight,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        option.stockText,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: _stockColor(
                            option.stockStatus,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '€${option.price.toStringAsFixed(2)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.textPrimary
                            : AppColors.textPrimaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (option.originalPrice != null)
                      Text(
                        '€${option.originalPrice!.toStringAsFixed(2)}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.textMuted
                              : AppColors.textMutedLight,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuantityCard extends StatelessWidget {
  const _QuantityCard({
    required this.quantity,
    required this.maximumQuantity,
    required this.enabled,
    required this.isDark,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int quantity;
  final int maximumQuantity;
  final bool enabled;
  final bool isDark;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quantity',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: isDark
                        ? AppColors.textPrimary
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  enabled
                      ? 'Maximum $maximumQuantity'
                      : 'Select an option first',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondary
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: enabled
                  ? AppColors.primaryGold
                  : isDark
                      ? AppColors.inputDark
                      : AppColors.borderLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: enabled && quantity > 1 ? onDecrease : null,
                  constraints: const BoxConstraints.tightFor(
                    width: 38,
                    height: 38,
                  ),
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.remove_rounded,
                    size: 18,
                    color: enabled
                        ? AppColors.backgroundDark
                        : AppColors.textMutedLight,
                  ),
                ),
                SizedBox(
                  width: 30,
                  child: Text(
                    '$quantity',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: enabled
                          ? AppColors.backgroundDark
                          : AppColors.textMutedLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed:
                      enabled && quantity < maximumQuantity ? onIncrease : null,
                  constraints: const BoxConstraints.tightFor(
                    width: 38,
                    height: 38,
                  ),
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.add_rounded,
                    size: 18,
                    color: enabled
                        ? AppColors.backgroundDark
                        : AppColors.textMutedLight,
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

class _DynamicProductTotal extends StatelessWidget {
  const _DynamicProductTotal({
    required this.state,
    required this.isDark,
  });

  final GroceryProductDetailsState state;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Price Summary',
            style: AppTextStyles.titleSmall.copyWith(
              color:
                  isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _InformationRow(
            label: 'Selected unit',
            value: state.selectedUnitText,
            isDark: isDark,
          ),
          _InformationRow(
            label: 'Unit price',
            value: '€${state.selectedUnitPrice.toStringAsFixed(2)}',
            isDark: isDark,
          ),
          _InformationRow(
            label: 'Quantity',
            value: '${state.quantity}',
            isDark: isDark,
          ),
          const Divider(height: 22),
          Row(
            children: [
              Expanded(
                child: Text(
                  state.selectedOption?.isEstimatedWeight ?? false
                      ? 'Estimated Total'
                      : 'Product Total',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.textPrimary
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '€${state.totalPrice.toStringAsFixed(2)}',
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.primaryGoldDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailsExpansionCard extends StatelessWidget {
  const _DetailsExpansionCard({
    required this.title,
    required this.icon,
    required this.isDark,
    required this.children,
    this.initiallyExpanded = false,
  });

  final String title;
  final IconData icon;
  final bool isDark;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 2,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          14,
          0,
          14,
          14,
        ),
        leading: Icon(
          icon,
          size: 21,
          color: AppColors.primaryGoldDark,
        ),
        title: Text(
          title,
          style: AppTextStyles.titleSmall.copyWith(
            color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
            fontWeight: FontWeight.w600,
          ),
        ),
        children: children,
      ),
    );
  }
}

class _InformationRow extends StatelessWidget {
  const _InformationRow({
    required this.label,
    required this.value,
    required this.isDark,
    this.showBottomSpacing = true,
  });

  final String label;
  final String value;
  final bool isDark;
  final bool showBottomSpacing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: showBottomSpacing ? 9 : 0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? AppColors.textSecondary
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTextStyles.bodySmall.copyWith(
                color:
                    isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EstimatedWeightNotice extends StatelessWidget {
  const _EstimatedWeightNotice({
    required this.isDark,
  });

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.scale_outlined,
            size: 20,
            color: AppColors.info,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'The final picked weight and amount may differ slightly from this estimate.',
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
    );
  }
}

class _RelatedProductCard extends StatelessWidget {
  const _RelatedProductCard({
    required this.name,
    required this.price,
    required this.isDark,
    required this.onTap,
  });

  final String name;
  final String price;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 150,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.shopping_basket_rounded,
                  size: 22,
                  color: AppColors.primaryGoldDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isDark
                            ? AppColors.textPrimary
                            : AppColors.textPrimaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      price,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primaryGoldDark,
                        fontWeight: FontWeight.w700,
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

class _DetailsBadge extends StatelessWidget {
  const _DetailsBadge({
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
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ProductWarning extends StatelessWidget {
  const _ProductWarning({
    required this.text,
    required this.isDark,
  });

  final String text;
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
              text,
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

Color _stockColor(
  GroceryProductStockStatus status,
) {
  switch (status) {
    case GroceryProductStockStatus.inStock:
      return AppColors.success;

    case GroceryProductStockStatus.lowStock:
      return AppColors.warning;

    case GroceryProductStockStatus.outOfStock:
      return AppColors.error;
  }
}
