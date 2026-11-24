import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/string_extensions.dart';
import '../../data/models/food_item_customization.dart';
import '../../data/models/food_restaurant.dart';
import '../../data/models/restaurant_menu.dart';
import '../providers/food_item_customization_provider.dart';
import '../providers/restaurant_menu_provider.dart';
import '../../data/models/food_grocery_cart.dart';
import '../providers/food_grocery_cart_provider.dart';
import '../providers/food_grocery_delivery_provider.dart';
import '../widgets/smart_product_image.dart';

class FoodItemDetailsScreen extends ConsumerStatefulWidget {
  const FoodItemDetailsScreen({
    super.key,
    required this.restaurant,
    required this.item,
  });

  final FoodRestaurant restaurant;
  final RestaurantMenuItem item;

  @override
  ConsumerState<FoodItemDetailsScreen> createState() =>
      _FoodItemDetailsScreenState();
}

class _FoodItemDetailsScreenState extends ConsumerState<FoodItemDetailsScreen> {
  final TextEditingController _instructionsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final cart = ref.read(foodGroceryCartProvider);
    final existingItem = cart.items
        .where((c) =>
            c.cartType == FoodGroceryCartType.food &&
            c.productId == widget.item.id &&
            c.supplierId == widget.restaurant.id)
        .lastOrNull;
    if (existingItem != null &&
        existingItem.instructions != null &&
        existingItem.instructions!.isNotEmpty) {
      _instructionsController.text = existingItem.instructions!;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final menuState =
          ref.read(restaurantMenuProvider(widget.item.restaurantId));
      if (menuState.items.isEmpty) {
        ref
            .read(restaurantMenuProvider(widget.item.restaurantId).notifier)
            .loadMenu();
      }
      final currentCart = ref.read(foodGroceryCartProvider);
      final itemInCart = currentCart.items
          .where((c) =>
              c.cartType == FoodGroceryCartType.food &&
              c.productId == widget.item.id &&
              c.supplierId == widget.restaurant.id)
          .lastOrNull;
      if (itemInCart != null) {
        ref
            .read(foodItemCustomizationProvider(widget.item).notifier)
            .loadFromCartItem(itemInCart);
      }
    });
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
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

  void _selectOption({
    required FoodModifierGroup group,
    required FoodModifierOption option,
  }) {
    final error = ref
        .read(
          foodItemCustomizationProvider(
            widget.item,
          ).notifier,
        )
        .toggleOption(
          group: group,
          option: option,
        );

    if (error != null) {
      _showMessage(error);
    }
  }

  void _incrementOption({
    required FoodModifierGroup group,
    required FoodModifierOption option,
  }) {
    final error = ref
        .read(
          foodItemCustomizationProvider(
            widget.item,
          ).notifier,
        )
        .incrementOption(
          group: group,
          option: option,
        );

    if (error != null) {
      _showMessage(error);
    }
  }

  void _decrementOption({
    required FoodModifierGroup group,
    required FoodModifierOption option,
  }) {
    ref
        .read(
          foodItemCustomizationProvider(
            widget.item,
          ).notifier,
        )
        .decrementOption(
          group: group,
          option: option,
        );
  }

  Future<bool> _confirmReplaceCart(
    BuildContext context,
    String currentRestaurantName,
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
            'Your cart contains items from '
            '$currentRestaurantName. Starting a new cart '
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
                'Keep Current Cart',
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
                'Start New Cart',
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
    FoodItemCustomizationState state,
  ) async {
    if (!widget.restaurant.isOrderable) {
      _showMessage(
        'This restaurant is currently not accepting orders',
      );
      return;
    }

    if (!widget.item.isAvailable) {
      _showMessage(
        'This food item is currently unavailable',
      );
      return;
    }

    if (!state.requiredSelectionsComplete) {
      final missingGroup = state.firstMissingRequiredGroup;

      _showMessage(
        missingGroup == null
            ? 'Complete the required selections'
            : 'Please complete ${missingGroup.name}',
      );
      return;
    }

    final selectedOptions = <FoodModifierOption>[];

    for (final group in state.groups) {
      selectedOptions.addAll(
        state.selectedOptionsFor(group),
      );
    }

    selectedOptions.sort(
      (first, second) => first.id.compareTo(second.id),
    );

    FoodModifierOption? selectedSize;

    for (final group in state.groups) {
      if (group.id == 'size') {
        final sizeOptions = state.selectedOptionsFor(group);

        if (sizeOptions.isNotEmpty) {
          selectedSize = sizeOptions.first;
        }

        break;
      }
    }

    final modifiers = <FoodGroceryCartModifier>[];
    for (final group in state.groups) {
      if (group.id == 'size') continue;
      for (final option in state.selectedOptionsFor(group)) {
        if (option.id == selectedSize?.id) continue;
        final count = state.optionCount(group.id, option.id);
        if (count > 0) {
          modifiers.add(
            FoodGroceryCartModifier(
              id: option.id,
              name: '${option.name.toTitleCase()} ($count×)',
              price: option.priceAdjustment,
              quantity: count,
            ),
          );
        }
      }
    }

    final selectionKey = selectedOptions.isEmpty
        ? 'standard'
        : selectedOptions.map((option) {
            final group = state.groups.firstWhere(
              (g) => g.options.any((o) => o.id == option.id),
              orElse: () => state.groups.first,
            );
            final count = state.optionCount(group.id, option.id);
            return '${option.id}x$count';
          }).join('_');

    final cartItem = FoodGroceryCartItem(
      lineId: [
        widget.restaurant.id,
        widget.item.id,
        selectionKey,
      ].join('_'),
      productId: widget.item.id,
      supplierId: widget.restaurant.id,
      supplierName: widget.restaurant.name,
      name: widget.item.name,
      cartType: FoodGroceryCartType.food,
      unitPrice: state.unitPrice,
      quantity: state.quantity,
      imageUrl: widget.item.imageUrl,
      variantId: selectedSize?.id,
      variantName: selectedSize?.name,
      modifiers: modifiers,
      instructions: state.specialInstructions.trim().isEmpty
          ? null
          : state.specialInstructions.trim(),
      maximumQuantity: widget.item.maximumQuantity,
    );

    final cartNotifier = ref.read(foodGroceryCartProvider.notifier);

    // If an existing customized line item exists for this product, remove it so it's replaced rather than duplicated
    final currentItems = ref.read(foodGroceryCartProvider).items;
    final existingMatchingIndex = currentItems.indexWhere(
      (it) =>
          it.productId == widget.item.id &&
          it.supplierId == widget.restaurant.id,
    );
    if (existingMatchingIndex != -1) {
      final oldLineId = currentItems[existingMatchingIndex].lineId;
      cartNotifier.removeItem(oldLineId);
    }

    final result = cartNotifier.addItem(cartItem);

    if (result == CartAddResult.differentSupplier) {
      final currentCart = ref.read(foodGroceryCartProvider);

      final shouldReplace = await _confirmReplaceCart(
        context,
        currentCart.supplierName ?? 'another restaurant or store',
      );

      if (!shouldReplace || !mounted) {
        return;
      }

      cartNotifier.replaceCartWith(cartItem);
    } else if (result == CartAddResult.outOfStock) {
      _showMessage(
        'The selected quantity is not available',
      );
      return;
    }

    final selectedAddress = ref.read(foodGroceryDeliveryProvider).selectedAddress;
    final distance = widget.restaurant.calculateDistanceTo(
      selectedAddress?.latitude,
      selectedAddress?.longitude,
    );
    final deliveryFee = double.parse((distance * 1.0).toStringAsFixed(2));

    cartNotifier.updateCharges(
      deliveryFee: deliveryFee,
      serviceFee: 0,
      distanceKm: distance,
    );

    if (!mounted) return;

    // Pop back to the restaurant menu so the user can continue shopping
    // with the bottom cart bar showing the updated cart state
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final customizationState = ref.watch(
      foodItemCustomizationProvider(widget.item),
    );

    final canAddToCart = widget.restaurant.isOrderable &&
        widget.item.isAvailable &&
        customizationState.requiredSelectionsComplete;

    final sortedGroups = [
      ...customizationState.groups,
    ]..sort(
        (first, second) => first.displayOrder.compareTo(
          second.displayOrder,
        ),
      );

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Column(
        children: [
          _FoodItemHeader(
            title: widget.item.name.toTitleCase(),
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
                _ItemOverviewCard(
                  item: widget.item,
                  isDark: isDark,
                ),
                const SizedBox(height: 14),
                if (!widget.restaurant.isOrderable)
                  _AvailabilityNotice(
                    text: 'This restaurant is no longer accepting orders.',
                    isDark: isDark,
                  ),
                if (!widget.item.isAvailable)
                  _AvailabilityNotice(
                    text: 'This item is currently sold out.',
                    isDark: isDark,
                  ),
                if (!widget.restaurant.isOrderable || !widget.item.isAvailable)
                  const SizedBox(height: 14),
                ...sortedGroups
                    .where((group) => group.options.any((o) => o.isAvailable))
                    .map(
                  (group) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ModifierGroupCard(
                        group: group,
                        state: customizationState,
                        isDark: isDark,
                        onOptionPressed: (option) {
                          _selectOption(
                            group: group,
                            option: option,
                          );
                        },
                        onIncrementOption: (option) {
                          _incrementOption(
                            group: group,
                            option: option,
                          );
                        },
                        onDecrementOption: (option) {
                          _decrementOption(
                            group: group,
                            option: option,
                          );
                        },
                      ),
                    );
                  },
                ),
                _QuantityCard(
                  quantity: customizationState.quantity,
                  maximumQuantity: widget.item.maximumQuantity,
                  isDark: isDark,
                  onDecrease: () {
                    ref
                        .read(
                          foodItemCustomizationProvider(
                            widget.item,
                          ).notifier,
                        )
                        .decreaseQuantity();
                  },
                  onIncrease: () {
                    if (customizationState.quantity >=
                        widget.item.maximumQuantity) {
                      _showMessage(
                        'Maximum quantity is ${widget.item.maximumQuantity}',
                      );
                      return;
                    }

                    ref
                        .read(
                          foodItemCustomizationProvider(
                            widget.item,
                          ).notifier,
                        )
                        .increaseQuantity();
                  },
                ),
                const SizedBox(height: 12),
                _SpecialInstructionsCard(
                  controller: _instructionsController,
                  isDark: isDark,
                  onChanged: (value) {
                    ref
                        .read(
                          foodItemCustomizationProvider(
                            widget.item,
                          ).notifier,
                        )
                        .updateSpecialInstructions(
                          value,
                        );
                  },
                ),
                const SizedBox(height: 12),
                _AllergyNotice(
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _DynamicPriceCard(
                  state: customizationState,
                  isDark: isDark,
                ),
                if (!customizationState.requiredSelectionsComplete) ...[
                  const SizedBox(height: 10),
                  Text(
                    customizationState.firstMissingRequiredGroup == null
                        ? 'Complete all required selections'
                        : 'Required: ${customizationState.firstMissingRequiredGroup!.name}',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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
              onPressed: canAddToCart
                  ? () async {
                      await _addToCart(
                        customizationState,
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
              child: Builder(
                builder: (context) {
                  final isInCart = ref.watch(foodGroceryCartProvider).items.any(
                        (it) =>
                            it.productId == widget.item.id &&
                            it.supplierId == widget.restaurant.id,
                      );
                  final btnText = isInCart
                      ? 'Update Cart — €${customizationState.totalPrice.toStringAsFixed(2)}'
                      : 'Add to Cart — €${customizationState.totalPrice.toStringAsFixed(2)}';
                  return Text(
                    btnText,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: canAddToCart
                          ? AppColors.backgroundDark
                          : isDark
                              ? AppColors.textMuted
                              : AppColors.textMutedLight,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FoodItemHeader extends StatelessWidget {
  const _FoodItemHeader({
    required this.title,
  });

  final String title;

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
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.backgroundDark,
                    fontWeight: FontWeight.w700,
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

class _ItemOverviewCard extends StatelessWidget {
  const _ItemOverviewCard({
    required this.item,
    required this.isDark,
  });

  final RestaurantMenuItem item;
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
          RepaintBoundary(
            child: SmartProductImage(
              imageUrl: item.imageUrl,
              width: double.infinity,
              height: 174,
              fallbackIcon: Icons.fastfood_rounded,
              borderRadius: 16,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 7,
                  runSpacing: 6,
                  children: [
                    if (item.isPopular)
                      const _ItemTag(
                        text: 'Popular',
                        color: AppColors.primaryGoldDark,
                      ),
                    if (item.offerText != null)
                      _ItemTag(
                        text: item.offerText!,
                        color: AppColors.success,
                      ),
                    if (item.isCustomizable)
                      const _ItemTag(
                        text: 'Customizable',
                        color: AppColors.info,
                      ),
                  ],
                ),
                const SizedBox(height: 9),
                Text(
                  item.name.toTitleCase(),
                  style: AppTextStyles.titleMedium.copyWith(
                    color: isDark
                        ? AppColors.textPrimary
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  item.description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondary
                        : AppColors.textSecondaryLight,
                    height: 1.45,
                  ),
                ),
                if (item.dietaryTags.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      const Icon(
                        Icons.eco_outlined,
                        size: 17,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          item.dietaryText,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 11),
                Row(
                  children: [
                    Text(
                      '€${item.currentPrice.toStringAsFixed(2)}',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: isDark
                            ? AppColors.textPrimary
                            : AppColors.textPrimaryLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (item.hasOffer) ...[
                      const SizedBox(width: 8),
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
        ],
      ),
    );
  }
}

class _ItemTag extends StatelessWidget {
  const _ItemTag({
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
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

class _ModifierGroupCard extends StatelessWidget {
  const _ModifierGroupCard({
    required this.group,
    required this.state,
    required this.isDark,
    required this.onOptionPressed,
    required this.onIncrementOption,
    required this.onDecrementOption,
  });

  final FoodModifierGroup group;
  final FoodItemCustomizationState state;
  final bool isDark;
  final ValueChanged<FoodModifierOption> onOptionPressed;
  final ValueChanged<FoodModifierOption> onIncrementOption;
  final ValueChanged<FoodModifierOption> onDecrementOption;

  @override
  Widget build(BuildContext context) {
    final selectedCount = state.totalGroupCount(group.id);

    final missingRequired =
        group.isRequired && selectedCount < group.minimumSelection;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: missingRequired
              ? AppColors.primaryGold
              : isDark
                  ? AppColors.borderDark
                  : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  group.name,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: isDark
                        ? AppColors.textPrimary
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (group.isRequired)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'REQUIRED',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primaryGoldDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            group.requirementText,
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppColors.textSecondary
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 10),
          ...group.options.where((option) => option.isAvailable).map(
            (option) {
              final selected = state.isOptionSelected(
                groupId: group.id,
                optionId: option.id,
              );
              final count = state.optionCount(group.id, option.id);

              return _ModifierOptionTile(
                option: option,
                selectionType: group.selectionType,
                selected: selected,
                count: count,
                isDark: isDark,
                onTap: () {
                  onOptionPressed(option);
                },
                onIncrement: () {
                  onIncrementOption(option);
                },
                onDecrement: () {
                  onDecrementOption(option);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ModifierOptionTile extends StatelessWidget {
  const _ModifierOptionTile({
    required this.option,
    required this.selectionType,
    required this.selected,
    required this.count,
    required this.isDark,
    required this.onTap,
    required this.onIncrement,
    required this.onDecrement,
  });

  final FoodModifierOption option;
  final ModifierSelectionType selectionType;
  final bool selected;
  final int count;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final isMultiple = selectionType == ModifierSelectionType.multiple;
    final isSelected = isMultiple ? count > 0 : selected;

    final totalPrice = option.priceAdjustment * (count > 0 ? count : 1);
    final priceLabel = option.priceAdjustment == 0
        ? 'Included'
        : '+€${totalPrice.toStringAsFixed(2)}';

    return Opacity(
      opacity: option.isAvailable ? 1 : 0.52,
      child: Container(
        margin: const EdgeInsets.only(bottom: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryGold.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryGold.withValues(alpha: 0.35)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: option.isAvailable
              ? () {
                  if (isMultiple && count == 0) {
                    onIncrement();
                  } else {
                    onTap();
                  }
                }
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
            child: Row(
              children: [
                Icon(
                  selectionType == ModifierSelectionType.single
                      ? selected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded
                      : isSelected
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                  size: 21,
                  color: isSelected
                      ? AppColors.primaryGoldDark
                      : isDark
                          ? AppColors.textMuted
                          : AppColors.textMutedLight,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        option.isAvailable
                            ? option.name.toTitleCase()
                            : '${option.name.toTitleCase()} • Sold Out',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.textPrimary
                              : AppColors.textPrimaryLight,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      if (isMultiple && count > 1 && option.priceAdjustment > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Text(
                            '€${option.priceAdjustment.toStringAsFixed(2)} each',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: isDark
                                  ? AppColors.textMuted
                                  : AppColors.textMutedLight,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isMultiple) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceDark
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryGold.withValues(alpha: 0.5)
                            : (isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight),
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _MiniModifierButton(
                          icon: count == 1
                              ? Icons.delete_outline_rounded
                              : Icons.remove_rounded,
                          iconColor: count == 0
                              ? (isDark
                                      ? AppColors.textMuted
                                      : AppColors.textMutedLight)
                                  .withValues(alpha: 0.3)
                              : count == 1
                                  ? AppColors.error
                                  : (isDark
                                      ? AppColors.textPrimary
                                      : AppColors.textPrimaryLight),
                          onTap: count > 0 ? onDecrement : null,
                        ),
                        Container(
                          constraints: const BoxConstraints(minWidth: 20),
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Text(
                            '$count',
                            style: AppTextStyles.labelLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              color: count > 0
                                  ? (isDark
                                      ? AppColors.textPrimary
                                      : AppColors.textPrimaryLight)
                                  : (isDark
                                      ? AppColors.textMuted
                                      : AppColors.textMutedLight),
                            ),
                          ),
                        ),
                        _MiniModifierButton(
                          icon: Icons.add_rounded,
                          iconColor: AppColors.primaryGoldDark,
                          onTap: onIncrement,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  priceLabel,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: option.priceAdjustment > 0
                        ? AppColors.primaryGoldDark
                        : isDark
                            ? AppColors.textSecondary
                            : AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w600,
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

class _MiniModifierButton extends StatelessWidget {
  const _MiniModifierButton({
    required this.icon,
    required this.iconColor,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            icon,
            size: 15,
            color: iconColor,
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
    required this.isDark,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int quantity;
  final int maximumQuantity;
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
                  'Maximum $maximumQuantity per order',
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
              color: AppColors.primaryGold,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: quantity > 1 ? onDecrease : null,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 38,
                    height: 38,
                  ),
                  icon: const Icon(
                    Icons.remove_rounded,
                    size: 18,
                    color: AppColors.backgroundDark,
                  ),
                ),
                SizedBox(
                  width: 30,
                  child: Text(
                    '$quantity',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.backgroundDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: quantity < maximumQuantity ? onIncrease : null,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 38,
                    height: 38,
                  ),
                  icon: const Icon(
                    Icons.add_rounded,
                    size: 18,
                    color: AppColors.backgroundDark,
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

class _SpecialInstructionsCard extends StatelessWidget {
  const _SpecialInstructionsCard({
    required this.controller,
    required this.isDark,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool isDark;
  final ValueChanged<String> onChanged;

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
            'Special Instructions',
            style: AppTextStyles.titleSmall.copyWith(
              color:
                  isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Optional • Paid extras must be selected above',
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppColors.textSecondary
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            onChanged: onChanged,
            maxLength: 300,
            maxLines: 3,
            style: AppTextStyles.bodySmall.copyWith(
              color:
                  isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
            ),
            decoration: InputDecoration(
              hintText: 'Add notes for the restaurant',
              hintStyle: AppTextStyles.bodySmall.copyWith(
                color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
              ),
              filled: true,
              fillColor:
                  isDark ? AppColors.inputDark : AppColors.backgroundLight,
              contentPadding: const EdgeInsets.all(12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primaryGold,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AllergyNotice extends StatelessWidget {
  const _AllergyNotice({
    required this.isDark,
  });

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 20,
            color: AppColors.warning,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Have an allergy? Please review ingredient information or contact the restaurant before ordering.',
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

class _DynamicPriceCard extends StatelessWidget {
  const _DynamicPriceCard({
    required this.state,
    required this.isDark,
  });

  final FoodItemCustomizationState state;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    FoodModifierOption? sizeOption;
    for (final group in state.groups) {
      if (group.id == 'size') {
        final sizeOptions = state.selectedOptionsFor(group);
        if (sizeOptions.isNotEmpty) {
          sizeOption = sizeOptions.first;
        }
        break;
      }
    }

    final selectedAddOns = <({FoodModifierOption option, int count})>[];

    for (final group in state.groups) {
      if (group.id == 'size') continue;
      for (final option in state.selectedOptionsFor(group)) {
        final count = state.optionCount(group.id, option.id);
        if (count > 0) {
          selectedAddOns.add((option: option, count: count));
        }
      }
    }

    final itemTitle = sizeOption != null
        ? '${state.item.name} (${sizeOption.name})'
        : state.item.name;

    final itemTotal = state.baseItemPrice * state.quantity;

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
          Row(
            children: [
              const Icon(
                Icons.receipt_long_rounded,
                size: 18,
                color: AppColors.primaryGoldDark,
              ),
              const SizedBox(width: 8),
              Text(
                'Price Summary',
                style: AppTextStyles.titleSmall.copyWith(
                  color: isDark
                      ? AppColors.textPrimary
                      : AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _PriceRow(
            label: '${itemTitle.toTitleCase()} (${state.quantity}×)',
            value: '€${itemTotal.toStringAsFixed(2)}',
            isDark: isDark,
          ),
          ...selectedAddOns.map(
            (entry) {
              final count = entry.count;
              final price = entry.option.priceAdjustment * count;
              final value = entry.option.priceAdjustment > 0
                  ? '+€${price.toStringAsFixed(2)}'
                  : 'Included';

              return _PriceRow(
                label: '${entry.option.name.toTitleCase()} ($count×)',
                value: value,
                isDark: isDark,
              );
            },
          ),
          const Divider(height: 22),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Item Total',
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
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.primaryGoldDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    required this.isDark,
  });

  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? AppColors.textPrimary
                    : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              color:
                  isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityNotice extends StatelessWidget {
  const _AvailabilityNotice({
    required this.text,
    required this.isDark,
  });

  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
