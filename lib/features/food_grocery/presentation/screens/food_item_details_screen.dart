import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/models/food_item_customization.dart';
import '../../data/models/food_restaurant.dart';
import '../../data/models/restaurant_menu.dart';
import '../providers/food_item_customization_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../data/models/food_grocery_cart.dart';
import '../providers/food_grocery_cart_provider.dart';

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

    final modifiers = selectedOptions
        .where(
          (option) => option.id != selectedSize?.id,
        )
        .map(
          (option) => FoodGroceryCartModifier(
            id: option.id,
            name: option.name,
            price: option.priceAdjustment,
          ),
        )
        .toList();

    final selectionKey = selectedOptions.isEmpty
        ? 'standard'
        : selectedOptions.map((option) => option.id).join('_');

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

    cartNotifier.updateCharges(
      deliveryFee: widget.restaurant.deliveryFee,
      serviceFee: 0,
    );

    ref
        .read(
          foodItemCustomizationProvider(
            widget.item,
          ).notifier,
        )
        .reset();

    _instructionsController.clear();

    if (!mounted) return;

    context.pushNamed(
      RouteNames.foodGroceryCart,
    );
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
            title: widget.item.name,
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
                ...sortedGroups.map(
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
              child: Text(
                'ADD TO CART — €${customizationState.totalPrice.toStringAsFixed(2)}',
                style: AppTextStyles.labelLarge.copyWith(
                  color: canAddToCart
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
          Container(
            width: double.infinity,
            height: 174,
            decoration: BoxDecoration(
              color: AppColors.primaryGold.withValues(alpha: 0.14),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: const Icon(
              Icons.fastfood_rounded,
              size: 58,
              color: AppColors.primaryGoldDark,
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
                  item.name,
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
  });

  final FoodModifierGroup group;
  final FoodItemCustomizationState state;
  final bool isDark;
  final ValueChanged<FoodModifierOption> onOptionPressed;

  @override
  Widget build(BuildContext context) {
    final selectedCount = state.selectionsFor(group.id).length;

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
          ...group.options.map(
            (option) {
              final selected = state.isOptionSelected(
                groupId: group.id,
                optionId: option.id,
              );

              return _ModifierOptionTile(
                option: option,
                selectionType: group.selectionType,
                selected: selected,
                isDark: isDark,
                onTap: () {
                  onOptionPressed(option);
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
    required this.isDark,
    required this.onTap,
  });

  final FoodModifierOption option;
  final ModifierSelectionType selectionType;
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
              vertical: 9,
            ),
            child: Row(
              children: [
                Icon(
                  selectionType == ModifierSelectionType.single
                      ? selected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded
                      : selected
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                  size: 21,
                  color: selected
                      ? AppColors.primaryGoldDark
                      : isDark
                          ? AppColors.textMuted
                          : AppColors.textMutedLight,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    option.isAvailable
                        ? option.name
                        : '${option.name} • Sold Out',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textPrimary
                          : AppColors.textPrimaryLight,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  option.priceText,
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
    final selectedPaidOptions = <FoodModifierOption>[];

    for (final group in state.groups) {
      selectedPaidOptions.addAll(
        state.selectedOptionsFor(group).where(
              (option) => option.priceAdjustment > 0,
            ),
      );
    }

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
          _PriceRow(
            label: 'Base item',
            value: '€${state.item.currentPrice.toStringAsFixed(2)}',
            isDark: isDark,
          ),
          ...selectedPaidOptions.map(
            (option) {
              return _PriceRow(
                label: option.name,
                value: '+€${option.priceAdjustment.toStringAsFixed(2)}',
                isDark: isDark,
              );
            },
          ),
          _PriceRow(
            label: 'Subtotal for 1',
            value: '€${state.unitPrice.toStringAsFixed(2)}',
            isDark: isDark,
          ),
          _PriceRow(
            label: 'Quantity',
            value: '${state.quantity}',
            isDark: isDark,
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
                    ? AppColors.textSecondary
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              color:
                  isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w500,
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
