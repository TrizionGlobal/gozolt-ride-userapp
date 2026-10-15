import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../data/models/food_grocery_cart.dart';
import '../providers/food_grocery_cart_provider.dart';
import '../providers/food_grocery_delivery_provider.dart';
import '../widgets/food_grocery_header.dart';

class FoodGroceryReviewOrderScreen extends ConsumerStatefulWidget {
  const FoodGroceryReviewOrderScreen({
    super.key,
  });

  @override
  ConsumerState<FoodGroceryReviewOrderScreen> createState() =>
      _FoodGroceryReviewOrderScreenState();
}

class _FoodGroceryReviewOrderScreenState
    extends ConsumerState<FoodGroceryReviewOrderScreen> {
  bool _acceptTerms = false;
  bool _acceptPrivacy = false;
  bool _showAgreementError = false;

  void _continueToPayment() {
    final cart = ref.read(foodGroceryCartProvider);
    final delivery = ref.read(
      foodGroceryDeliveryProvider,
    );

    if (cart.isEmpty) {
      _showMessage('Your cart is empty');
      return;
    }

    if (delivery.selectedAddress == null) {
      _showMessage('Please select a delivery address');
      return;
    }

    if (!_acceptTerms || !_acceptPrivacy) {
      setState(() {
        _showAgreementError = true;
      });
      return;
    }

    setState(() {
      _showAgreementError = false;
    });

    // Temporary action.
    // Replace this with navigation to FG-UA-11
    // after the Payment Method screen is created.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Order reviewed successfully',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cart = ref.watch(
      foodGroceryCartProvider,
    );

    final delivery = ref.watch(
      foodGroceryDeliveryProvider,
    );

    final address = delivery.selectedAddress;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Column(
        children: [
          const FoodGroceryHeader(
            title: 'Review Order',
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  26,
                ),
                children: [
                  _ReviewCard(
                    isDark: isDark,
                    title: 'YOUR ORDER',
                    icon: cart.cartType == FoodGroceryCartType.grocery
                        ? Icons.shopping_basket_outlined
                        : Icons.restaurant_outlined,
                    child: Column(
                      children: [
                        _SupplierRow(
                          isDark: isDark,
                          supplierName:
                              cart.supplierName ?? 'Selected supplier',
                          itemCount: cart.itemCount,
                        ),
                        const SizedBox(height: 12),
                        Divider(
                          height: 1,
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                        const SizedBox(height: 12),
                        ...cart.items.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: 12,
                            ),
                            child: _OrderItemRow(
                              item: item,
                              isDark: isDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ReviewCard(
                    isDark: isDark,
                    title: 'DELIVERY ADDRESS',
                    icon: Icons.location_on_outlined,
                    trailing: TextButton(
                      onPressed: () {
                        context.pop();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryGold,
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'CHANGE',
                        style: AppTextStyles.labelSmall.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    child: address == null
                        ? Text(
                            'No delivery address selected',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.error,
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                address.label,
                                style: AppTextStyles.titleSmall.copyWith(
                                  color: isDark
                                      ? AppColors.textPrimary
                                      : AppColors.textPrimaryLight,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                address.fullAddress,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: isDark
                                      ? AppColors.textSecondary
                                      : AppColors.textSecondaryLight,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                '${address.recipientName} • '
                                '${address.phoneNumber}',
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
                  const SizedBox(height: 12),
                  _ReviewCard(
                    isDark: isDark,
                    title: 'DELIVERY PREFERENCE',
                    icon: Icons.delivery_dining_outlined,
                    child: Column(
                      children: [
                        _DetailRow(
                          isDark: isDark,
                          label: 'Hand-off',
                          value: delivery.leaveAtDoor
                              ? 'Leave at the door'
                              : 'Meet at the door',
                        ),
                        if (delivery.deliveryInstructions
                            .trim()
                            .isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _DetailRow(
                            isDark: isDark,
                            label: 'Instructions',
                            value: delivery.deliveryInstructions.trim(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (cart.discount > 0) ...[
                    _AppliedGoCoinsCard(
                      isDark: isDark,
                      discount: cart.discount,
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 12),
                  _PriceSummaryCard(
                    isDark: isDark,
                    cart: cart,
                  ),
                  if (cart.items.any(
                    (item) => item.isEstimatedWeight,
                  )) ...[
                    const SizedBox(height: 12),
                    _EstimatedWeightNotice(
                      isDark: isDark,
                    ),
                  ],
                  const SizedBox(height: 12),
                  _ReviewCard(
                    isDark: isDark,
                    title: 'ORDER TERMS',
                    icon: Icons.verified_user_outlined,
                    child: Column(
                      children: [
                        _AgreementRow(
                          isDark: isDark,
                          value: _acceptTerms,
                          leadingText: 'I accept the ',
                          linkText: 'Terms & Conditions',
                          onChanged: (value) {
                            setState(() {
                              _acceptTerms = value ?? false;

                              if (_acceptTerms && _acceptPrivacy) {
                                _showAgreementError = false;
                              }
                            });
                          },
                          onLinkPressed: () {
                            context.pushNamed(
                              RouteNames.terms,
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        _AgreementRow(
                          isDark: isDark,
                          value: _acceptPrivacy,
                          leadingText: 'I accept the ',
                          linkText: 'Privacy Policy',
                          onChanged: (value) {
                            setState(() {
                              _acceptPrivacy = value ?? false;

                              if (_acceptTerms && _acceptPrivacy) {
                                _showAgreementError = false;
                              }
                            });
                          },
                          onLinkPressed: () {
                            context.pushNamed(
                              RouteNames.privacyPolicy,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
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
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: cart.isEmpty || address == null
                      ? null
                      : _continueToPayment,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: AppColors.primaryGold,
                    foregroundColor: AppColors.backgroundDark,
                    disabledBackgroundColor:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'CONTINUE TO PAYMENT',
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
              if (_showAgreementError) ...[
                const SizedBox(height: 7),
                Text(
                  'Accept the Terms & Conditions and '
                  'Privacy Policy to continue',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AppliedGoCoinsCard extends StatelessWidget {
  const _AppliedGoCoinsCard({
    required this.isDark,
    required this.discount,
  });

  final bool isDark;
  final double discount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.cardDark
            : AppColors.primaryGold.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primaryGold.withValues(
            alpha: isDark ? 0.45 : 0.55,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryGold.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.stars_rounded,
              size: 21,
              color: AppColors.primaryGold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GO Coins applied',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.textPrimary
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your reward has been deducted from this order.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondary
                        : AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '-€${discount.toStringAsFixed(2)}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primaryGold,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.isDark,
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final bool isDark;
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
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
                icon,
                size: 19,
                color: AppColors.primaryGold,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: isDark
                        ? AppColors.textPrimary
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }
}

class _SupplierRow extends StatelessWidget {
  const _SupplierRow({
    required this.isDark,
    required this.supplierName,
    required this.itemCount,
  });

  final bool isDark;
  final String supplierName;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryGold.withValues(
              alpha: 0.14,
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.storefront_outlined,
            size: 20,
            color: AppColors.primaryGold,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                supplierName,
                style: AppTextStyles.titleSmall.copyWith(
                  color: isDark
                      ? AppColors.textPrimary
                      : AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
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
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({
    required this.item,
    required this.isDark,
  });

  final FoodGroceryCartItem item;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final details = <String>[
      if (item.variantName != null && item.variantName!.trim().isNotEmpty)
        item.variantName!.trim(),
      ...item.modifiers.map((modifier) => modifier.name),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primaryGold.withValues(
              alpha: 0.14,
            ),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            '${item.quantity}×',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.primaryGold,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.textPrimary
                      : AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (details.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  details.join(' • '),
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
                const SizedBox(height: 3),
                Text(
                  'Note: ${item.instructions!.trim()}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondary
                        : AppColors.textSecondaryLight,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '€${item.lineTotal.toStringAsFixed(2)}',
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.isDark,
    required this.label,
    required this.value,
  });

  final bool isDark;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
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
        const SizedBox(width: 10),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTextStyles.bodySmall.copyWith(
              color:
                  isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _PriceSummaryCard extends StatelessWidget {
  const _PriceSummaryCard({
    required this.isDark,
    required this.cart,
  });

  final bool isDark;
  final FoodGroceryCartState cart;

  @override
  Widget build(BuildContext context) {
    return _ReviewCard(
      isDark: isDark,
      title: 'PRICE SUMMARY',
      icon: Icons.receipt_long_outlined,
      child: Column(
        children: [
          _PriceRow(
            isDark: isDark,
            label: 'Item subtotal',
            value: '€${cart.subtotal.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 9),
          _PriceRow(
            isDark: isDark,
            label: 'Delivery fee',
            value: cart.deliveryFee <= 0
                ? 'Free'
                : '€${cart.deliveryFee.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 9),
          _PriceRow(
            isDark: isDark,
            label: 'Service fee',
            value: cart.serviceFee <= 0
                ? '€0.00'
                : '€${cart.serviceFee.toStringAsFixed(2)}',
          ),
          if (cart.discount > 0) ...[
            const SizedBox(height: 9),
            _PriceRow(
              isDark: isDark,
              label: 'GO Coins',
              value: '-€${cart.discount.toStringAsFixed(2)}',
              valueColor: AppColors.success,
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
            label: 'Final total',
            value: '€${cart.total.toStringAsFixed(2)}',
            isTotal: true,
          ),
          const SizedBox(height: 7),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Taxes & VAT included where applicable',
              style: AppTextStyles.labelSmall.copyWith(
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
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: isTotal
                ? AppTextStyles.titleSmall.copyWith(
                    color: isDark
                        ? AppColors.textPrimary
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w700,
                  )
                : AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondary
                        : AppColors.textSecondaryLight,
                  ),
          ),
        ),
        Text(
          value,
          style: isTotal
              ? AppTextStyles.titleMedium.copyWith(
                  color: AppColors.primaryGold,
                  fontWeight: FontWeight.w800,
                )
              : AppTextStyles.bodyMedium.copyWith(
                  color: valueColor ??
                      (isDark
                          ? AppColors.textPrimary
                          : AppColors.textPrimaryLight),
                  fontWeight: FontWeight.w600,
                ),
        ),
      ],
    );
  }
}

class _AgreementRow extends StatelessWidget {
  const _AgreementRow({
    required this.isDark,
    required this.value,
    required this.leadingText,
    required this.linkText,
    required this.onChanged,
    required this.onLinkPressed,
  });

  final bool isDark;
  final bool value;
  final String leadingText;
  final String linkText;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onLinkPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 34,
          height: 34,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primaryGold,
            checkColor: AppColors.backgroundDark,
            side: BorderSide(
              color: isDark
                  ? AppColors.textSecondary
                  : AppColors.textSecondaryLight,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 7),
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.textSecondary
                      : AppColors.textSecondaryLight,
                  height: 1.35,
                ),
                children: [
                  TextSpan(text: leadingText),
                  TextSpan(
                    text: linkText,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primaryGold,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.primaryGold,
                    ),
                    recognizer: TapGestureRecognizer()..onTap = onLinkPressed,
                  ),
                ],
              ),
            ),
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
        color: AppColors.primaryGold.withValues(
          alpha: 0.10,
        ),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.scale_outlined,
            size: 19,
            color: AppColors.primaryGold,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'The final price of weighted grocery items '
              'may change slightly after preparation.',
              style: AppTextStyles.bodySmall.copyWith(
                color:
                    isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
