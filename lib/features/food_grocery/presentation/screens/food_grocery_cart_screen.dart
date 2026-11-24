import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/asset_paths.dart';
import '../../../../core/utils/string_extensions.dart';
import '../../data/models/food_grocery_cart.dart';
import '../providers/food_grocery_cart_provider.dart';
import '../widgets/food_grocery_header.dart';
import '../widgets/smart_product_image.dart';
import '../../../rewards/presentation/providers/rewards_providers.dart';
import '../../../ride/presentation/providers/ride_providers.dart';

class FoodGroceryCartScreen extends ConsumerStatefulWidget {
  const FoodGroceryCartScreen({super.key});

  @override
  ConsumerState<FoodGroceryCartScreen> createState() =>
      _FoodGroceryCartScreenState();
}

class _FoodGroceryCartScreenState extends ConsumerState<FoodGroceryCartScreen> {
  bool _useGoCoins = false;

  void _showRemoveDialog(FoodGroceryCartItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.cardDark : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'Remove item?',
            style: AppTextStyles.titleMedium.copyWith(
              color:
                  isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Do you want to remove ${item.name} from your cart?',
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.textSecondary
                  : AppColors.textSecondaryLight,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
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
              onPressed: () {
                ref
                    .read(foodGroceryCartProvider.notifier)
                    .removeItem(item.lineId);

                Navigator.pop(dialogContext);
              },
              child: Text(
                'REMOVE',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _continueToDelivery({
    required double goCoinsDiscount,
  }) {
    final cart = ref.read(
      foodGroceryCartProvider,
    );

    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Your cart is empty',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white,
            ),
          ),
          backgroundColor: AppColors.error,
        ),
      );

      return;
    }

    ref.read(foodGroceryCartProvider.notifier).updateCharges(
          deliveryFee: cart.deliveryFee,
          serviceFee: cart.serviceFee,
          discount: goCoinsDiscount,
          distanceKm: cart.distanceKm,
        );

    FocusScope.of(context).unfocus();

    context.pushNamed(
      RouteNames.foodGroceryDeliveryAddress,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cart = ref.watch(foodGroceryCartProvider);

    // GoCoins logic (standardized with Car Rental, Bike Rental, Airport Transfer)
    final rewardSummary = ref.watch(rewardSummaryProvider).value;
    final int balance = (rewardSummary?.currentPoints.toInt() ?? 0) > 0
        ? rewardSummary!.currentPoints.toInt()
        : (ref.watch(userRewardsPointsProvider).value ?? 0);

    final double coinValueInEur = rewardSummary?.coinValueInEur ?? 0.01;

    final double totalBeforeDiscount =
        cart.subtotal + cart.deliveryFee + cart.vat;
    final double maxEurValue = balance * coinValueInEur;
    final double appliedEurValue =
        maxEurValue > totalBeforeDiscount ? totalBeforeDiscount : maxEurValue;
    final int coinsUsed =
        coinValueInEur > 0 ? (appliedEurValue / coinValueInEur).ceil() : 0;

    final int minRedeemCoins =
        ref.watch(rewardRulesProvider).value?.redemption.minimumPoints ?? 200;
    final bool canRedeem = balance >= minRedeemCoins && balance > 0;

    final double goCoinsDiscount =
        (_useGoCoins && canRedeem) ? appliedEurValue : 0.0;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Column(
        children: [
          const FoodGroceryHeader(
            title: 'Your Cart',
          ),
          Expanded(
            child: cart.isEmpty
                ? _EmptyCart(isDark: isDark)
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      24,
                    ),
                    children: [
                      _SupplierCard(
                        isDark: isDark,
                        supplierName: cart.supplierName ?? 'Selected store',
                        cartType: cart.cartType ?? FoodGroceryCartType.food,
                        itemCount: cart.itemCount,
                      ),
                      const SizedBox(height: 12),
                      ...cart.items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: 10,
                          ),
                          child: _CartItemCard(
                            item: item,
                            isDark: isDark,
                            onIncrease: () {
                              ref
                                  .read(
                                    foodGroceryCartProvider.notifier,
                                  )
                                  .increaseQuantity(
                                    item.lineId,
                                  );
                            },
                            onDecrease: () {
                              ref
                                  .read(
                                    foodGroceryCartProvider.notifier,
                                  )
                                  .decreaseQuantity(
                                    item.lineId,
                                  );
                            },
                            onRemove: () => _showRemoveDialog(item),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _GoCoinsCard(
                        isDark: isDark,
                        balance: balance,
                        coinsUsed: coinsUsed,
                        appliedEurValue: appliedEurValue,
                        minRedeemCoins: minRedeemCoins,
                        canRedeem: canRedeem,
                        useGoCoins: _useGoCoins,
                        onChanged: canRedeem
                            ? (value) {
                                setState(() {
                                  _useGoCoins = value;
                                });
                              }
                            : null,
                      ),
                      const SizedBox(height: 12),
                      _PriceSummaryCard(
                        isDark: isDark,
                        cart: cart,
                        goCoinsDiscount: goCoinsDiscount,
                      ),
                      if (cart.items.any(
                        (item) => item.isEstimatedWeight,
                      )) ...[
                        const SizedBox(height: 12),
                        _EstimatedWeightNotice(
                          isDark: isDark,
                        ),
                      ],
                      if (cart.items.any(
                        (item) => item.isEstimatedWeight,
                      )) ...[
                        const SizedBox(height: 12),
                        _EstimatedWeightNotice(
                          isDark: isDark,
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  10,
                  16,
                  12,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.white,
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
                      _continueToDelivery(
                        goCoinsDiscount: goCoinsDiscount,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: AppColors.backgroundDark,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Continue to Delivery',
                          style: AppTextStyles.labelLarge.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 20,
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

class _SupplierCard extends StatelessWidget {
  const _SupplierCard({
    required this.isDark,
    required this.supplierName,
    required this.cartType,
    required this.itemCount,
  });

  final bool isDark;
  final String supplierName;
  final FoodGroceryCartType cartType;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final isGrocery = cartType == FoodGroceryCartType.grocery;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              color: AppColors.primaryGold.withValues(
                alpha: 0.14,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isGrocery
                  ? Icons.local_grocery_store_outlined
                  : Icons.restaurant_rounded,
              size: 22,
              color: AppColors.primaryGoldDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  supplierName.toTitleCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: isDark
                        ? AppColors.textPrimary
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$itemCount ${itemCount == 1 ? 'item' : 'items'} from this ${isGrocery ? 'store' : 'restaurant'}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondary
                        : AppColors.textSecondaryLight,
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

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.item,
    required this.isDark,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
  });

  final FoodGroceryCartItem item;
  final bool isDark;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final hasMaximumQuantity = item.maximumQuantity != null;

    final reachedMaximum =
        hasMaximumQuantity && item.quantity >= item.maximumQuantity!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SmartProductImage(
            imageUrl: item.imageUrl,
            width: 76,
            height: 76,
            fallbackIcon: item.cartType == FoodGroceryCartType.grocery
                ? Icons.shopping_basket_rounded
                : Icons.fastfood_rounded,
            borderRadius: 12,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.name.toTitleCase(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isDark
                              ? AppColors.textPrimary
                              : AppColors.textPrimaryLight,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: onRemove,
                      borderRadius: BorderRadius.circular(18),
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: isDark
                              ? AppColors.textSecondary
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
                if (item.variantName != null &&
                    item.variantName!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.variantName!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textSecondary
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
                if (item.modifiers.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.modifiers.map((m) {
                      final name = m.name.toTitleCase();
                      if (name.contains('×') || name.contains('(x')) {
                        return name;
                      }
                      return '$name (${m.quantity}×)';
                    }).join(', '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textSecondary
                          : AppColors.textSecondaryLight,
                      height: 1.35,
                    ),
                  ),
                ],
                if (item.instructions != null &&
                    item.instructions!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Note: ${item.instructions}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textMuted
                          : AppColors.textMutedLight,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '€${item.lineTotal.toStringAsFixed(2)}',
                            style: AppTextStyles.titleSmall.copyWith(
                              color: AppColors.primaryGoldDark,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (item.quantity > 1)
                            Padding(
                              padding: const EdgeInsets.only(top: 1),
                              child: Text(
                                '${item.quantity} items',
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
                    _QuantityControl(
                      isDark: isDark,
                      quantity: item.quantity,
                      reachedMaximum: reachedMaximum,
                      onDecrease: onDecrease,
                      onIncrease: onIncrease,
                    ),
                  ],
                ),
                if (reachedMaximum) ...[
                  const SizedBox(height: 5),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Maximum stock selected',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  const _QuantityControl({
    required this.isDark,
    required this.quantity,
    required this.reachedMaximum,
    required this.onDecrease,
    required this.onIncrease,
  });

  final bool isDark;
  final int quantity;
  final bool reachedMaximum;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.inputDark
            : AppColors.primaryGold.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.primaryGold.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QuantityButton(
            icon: quantity == 1
                ? Icons.delete_outline_rounded
                : Icons.remove_rounded,
            onPressed: onDecrease,
            color: quantity == 1 ? AppColors.error : AppColors.primaryGoldDark,
          ),
          SizedBox(
            width: 32,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color:
                    isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _QuantityButton(
            icon: Icons.add_rounded,
            onPressed: reachedMaximum ? null : onIncrease,
            color: AppColors.primaryGoldDark,
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.icon,
    required this.onPressed,
    required this.color,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(9),
      child: SizedBox(
        width: 32,
        height: 32,
        child: Icon(
          icon,
          size: 18,
          color: onPressed == null ? Colors.grey : color,
        ),
      ),
    );
  }
}

class _GoCoinsCard extends StatelessWidget {
  const _GoCoinsCard({
    required this.isDark,
    required this.balance,
    required this.coinsUsed,
    required this.appliedEurValue,
    required this.minRedeemCoins,
    required this.canRedeem,
    required this.useGoCoins,
    required this.onChanged,
  });

  final bool isDark;
  final int balance;
  final int coinsUsed;
  final double appliedEurValue;
  final int minRedeemCoins;
  final bool canRedeem;
  final bool useGoCoins;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final isSelected = useGoCoins && canRedeem;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppColors.primaryGold
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
          width: isSelected ? 1.5 : 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryGold.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              AssetPaths.iconGoCoin,
              width: 32,
              height: 32,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Redeem GoCoins',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textPrimary
                        : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Balance: $balance Coins',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.textSecondary
                        : AppColors.textSecondaryLight,
                  ),
                ),
                if (!canRedeem && balance > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Min $minRedeemCoins coins required to redeem',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else if (appliedEurValue > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Save €${appliedEurValue.toStringAsFixed(2)} with $coinsUsed coins',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primaryGold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Transform.scale(
            scale: 0.9,
            child: Switch.adaptive(
              value: isSelected,
              activeTrackColor: AppColors.primaryGold,
              inactiveTrackColor:
                  Theme.of(context).dividerTheme.color ?? AppColors.borderDark,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceSummaryCard extends StatelessWidget {
  const _PriceSummaryCard({
    required this.isDark,
    required this.cart,
    required this.goCoinsDiscount,
  });

  final bool isDark;
  final FoodGroceryCartState cart;
  final double goCoinsDiscount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PRICE SUMMARY',
            style: AppTextStyles.labelSmall.copyWith(
              color: isDark
                  ? AppColors.textSecondary
                  : AppColors.textSecondaryLight,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 13),
          _PriceRow(
            isDark: isDark,
            label: 'Items Subtotal',
            value: '€${cart.subtotal.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 9),
          _PriceRow(
            isDark: isDark,
            label: 'Delivery Fee',
            value: cart.deliveryFee <= 0
                ? 'Calculated later'
                : '€${cart.deliveryFee.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 9),
          _PriceRow(
            isDark: isDark,
            label: 'VAT (10% Platform)',
            value: '€${cart.vat.toStringAsFixed(2)}',
          ),
          if (goCoinsDiscount > 0) ...[
            const SizedBox(height: 9),
            _PriceRow(
              isDark: isDark,
              label: 'GoCoins Discount',
              value: '-€${goCoinsDiscount.toStringAsFixed(2)}',
              valueColor: AppColors.primaryGold,
            ),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Divider(
              height: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          _PriceRow(
            isDark: isDark,
            label: 'Total',
            value:
                '€${(cart.subtotal + cart.deliveryFee + cart.vat - goCoinsDiscount).clamp(0, double.infinity).toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.isDark,
    required this.label,
    required this.value,
    this.valueColor,
    this.isTotal = false,
  });

  final bool isDark;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final style = isTotal ? AppTextStyles.titleSmall : AppTextStyles.bodySmall;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: style.copyWith(
              color: isDark
                  ? AppColors.textSecondary
                  : AppColors.textSecondaryLight,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: style.copyWith(
            color: valueColor ??
                (isTotal
                    ? AppColors.primaryGoldDark
                    : isDark
                        ? AppColors.textPrimary
                        : AppColors.textPrimaryLight),
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
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
        border: Border.all(
          color: AppColors.info.withValues(alpha: 0.30),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.scale_outlined,
            size: 19,
            color: AppColors.info,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'The final amount for weighted grocery products may change slightly after preparation.',
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

class _EmptyCart extends StatelessWidget {
  const _EmptyCart({
    required this.isDark,
  });

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withValues(
                  alpha: 0.14,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                size: 42,
                color: AppColors.primaryGoldDark,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Your cart is empty',
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium.copyWith(
                color:
                    isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Add food or grocery products to see them here.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.textSecondary
                    : AppColors.textSecondaryLight,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => Navigator.maybePop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryGoldDark,
                side: const BorderSide(
                  color: AppColors.primaryGold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
              ),
              icon: const Icon(
                Icons.arrow_back_rounded,
                size: 19,
              ),
              label: Text(
                'CONTINUE SHOPPING',
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
