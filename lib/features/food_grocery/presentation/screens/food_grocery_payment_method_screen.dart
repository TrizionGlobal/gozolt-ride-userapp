import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../../ride/data/models/saved_payment_method.dart';
import '../../../ride/presentation/widgets/payment_brand_icon.dart';
import '../providers/food_grocery_cart_provider.dart';
import '../providers/food_grocery_delivery_provider.dart';
import '../providers/food_grocery_order_provider.dart';
import '../providers/food_grocery_payment_provider.dart';
import '../widgets/food_grocery_header.dart';
import '../widgets/food_grocery_payment_sheet.dart';

class FoodGroceryPaymentMethodScreen extends ConsumerStatefulWidget {
  const FoodGroceryPaymentMethodScreen({super.key});

  @override
  ConsumerState<FoodGroceryPaymentMethodScreen> createState() =>
      _FoodGroceryPaymentMethodScreenState();
}

class _FoodGroceryPaymentMethodScreenState
    extends ConsumerState<FoodGroceryPaymentMethodScreen> {
  bool? _isCashSelected;
  bool _isLaunchingCheckout = false;

  @override
  void initState() {
    super.initState();
    // Do not pre-select any payment method by default
    _isCashSelected = null;
  }

  Future<void> _launchOnlineCheckout() async {
    final cart = ref.read(foodGroceryCartProvider);
    if (cart.isEmpty) {
      _showMessage('Your cart is empty', isError: true);
      return;
    }

    final delivery = ref.read(foodGroceryDeliveryProvider);
    final goCoinsToUse =
        cart.discount > 0 ? (cart.discount / 0.01).round() : 0;

    setState(() {
      _isLaunchingCheckout = true;
    });

    try {
      ref.read(foodGroceryOrderProvider.notifier).reset();

      await ref.read(foodGroceryOrderProvider.notifier).placeOrder(
            cart: cart,
            paymentMethodType: PaymentMethodType.card,
            deliveryAddressId: delivery.selectedAddress?.id,
            deliveryAddressSnapshot: delivery.selectedAddress?.toJson(
              leaveAtDoor: delivery.leaveAtDoor,
              instructions: delivery.deliveryInstructions,
            ),
            leaveAtDoor: delivery.leaveAtDoor,
            deliveryInstructions: delivery.deliveryInstructions,
            goCoinsToUse: goCoinsToUse,
            stripePaymentMethodId: null,
            stripePaymentIntentId: null,
          );

      if (!mounted) return;

      final orderState = ref.read(foodGroceryOrderProvider);
      setState(() {
        _isLaunchingCheckout = false;
      });

      if (orderState.hasFailed) {
        _showMessage(
          orderState.errorMessage ??
              'Unable to initialize online checkout. Please try again.',
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLaunchingCheckout = false;
      });
      _showMessage('Failed to open payment gateway: $e', isError: true);
    }
  }

  Future<void> _showPaymentMethods() async {
    final paymentState = ref.read(foodGroceryPaymentProvider);
    final cart = ref.read(foodGroceryCartProvider);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return FoodGroceryPaymentSheet(
          amount: cart.total,
          currentType: paymentState.paymentMethodType,
          currentCardId: paymentState.cardId,
          isOnline: paymentState.isOnline,
          onConfirm: (
            type, {
            cardId,
            cardDisplayName,
            cardBrand,
            isOnline = false,
          }) async {
            // Update payment provider with the selected card or online payment details
            ref.read(foodGroceryPaymentProvider.notifier).selectPaymentMethod(
                  type,
                  cardId: cardId,
                  cardDisplayName: cardDisplayName,
                  cardBrand: cardBrand,
                  isOnline: isOnline,
                );

            if (mounted) {
              setState(() {
                _isCashSelected = false;
              });
            }

            if (isOnline) {
              // Online payment: Launch Stripe checkout directly.
              // DO NOT navigate to order processing yet.
              // The Order Placement screen will show AFTER payment completes.
              await _launchOnlineCheckout();
              return true;
            } else {
              // Saved card: navigate to order processing to charge card and place order
              if (context.mounted) {
                context.pushNamed(RouteNames.foodGroceryOrderProcessing);
              }
              return true;
            }
          },
        );
      },
    );
  }

  void _placeCashOrder() {
    final cart = ref.read(foodGroceryCartProvider);

    if (cart.isEmpty) {
      _showMessage('Your cart is empty', isError: true);
      return;
    }

    ref.read(foodGroceryPaymentProvider.notifier).selectPaymentMethod(
          PaymentMethodType.cash,
        );

    if (context.mounted) {
      context.pushNamed(RouteNames.foodGroceryOrderProcessing);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white,
            ),
          ),
          backgroundColor: isError ? AppColors.error : AppColors.success,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cart = ref.watch(foodGroceryCartProvider);
    final paymentState = ref.watch(foodGroceryPaymentProvider);
    final orderState = ref.watch(foodGroceryOrderProvider);
    final total = cart.total;

    // Listen for Stripe payment success to navigate to Order Placement screen AFTER payment
    ref.listen<FoodGroceryOrderState>(foodGroceryOrderProvider, (previous, next) {
      if (next.isPlaced && next.orderId != null && !next.isProcessing) {
        context.pushReplacementNamed(
          RouteNames.foodGroceryOrderProcessing,
          queryParameters: {
            'status': 'success',
            'orderId': next.orderId!,
          },
        );
      } else if (next.hasFailed && next.errorMessage != null && !next.isProcessing) {
        _showMessage(next.errorMessage!, isError: true);
      }
    });

    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final cardColor = isDark ? AppColors.cardDark : Colors.white;

    final String buttonText;
    if (_isLaunchingCheckout) {
      buttonText = 'OPENING STRIPE CHECKOUT...';
    } else if (_isCashSelected == null) {
      buttonText = 'SELECT PAYMENT METHOD';
    } else if (_isCashSelected == true) {
      buttonText = 'PLACE ORDER';
    } else {
      buttonText = paymentState.isOnline ? 'PAY VIA STRIPE' : 'PAY WITH CARD';
    }

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Column(
        children: [
          const FoodGroceryHeader(
            title: 'Payment Method',
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  _SectionCard(
                    isDark: isDark,
                    title: 'CHOOSE PAYMENT METHOD',
                    icon: Icons.account_balance_wallet_outlined,
                    child: Column(
                      children: [
                        // Card 1: Cash on Delivery
                        _PaymentOptionCard(
                          isDark: isDark,
                          isSelected: _isCashSelected == true,
                          cardColor: cardColor,
                          borderColor: borderColor,
                          icon: Icons.payments_outlined,
                          title: 'Cash on Delivery',
                          subtitle:
                              'Pay the delivery partner when your order arrives.',
                          trailing: _radioCircle(_isCashSelected == true),
                          onTap: () {
                            setState(() {
                              _isCashSelected = true;
                            });
                            ref
                                .read(foodGroceryPaymentProvider.notifier)
                                .selectPaymentMethod(PaymentMethodType.cash);
                          },
                        ),
                        const SizedBox(height: 12),

                        // Card 2: Other payments
                        _PaymentOptionCard(
                          isDark: isDark,
                          isSelected: _isCashSelected == false,
                          cardColor: cardColor,
                          borderColor: borderColor,
                          iconWidget: !paymentState.isCash &&
                                  paymentState.cardBrand != null
                              ? PaymentBrandIcon(
                                  brand: paymentState.cardBrand!,
                                )
                              : null,
                          icon: Icons.credit_card_rounded,
                          title: 'Other Payments',
                          subtitle: !paymentState.isCash &&
                                  paymentState.cardDisplayName != null
                              ? paymentState.cardDisplayName!
                              : 'Credit / Debit Card or Online Payment via Stripe',
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            size: 22,
                            color: AppColors.primaryGold,
                          ),
                          onTap: () {
                            _showPaymentMethods();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  _SectionCard(
                    isDark: isDark,
                    title: 'PRICE DETAILS',
                    icon: Icons.receipt_long_outlined,
                    child: Column(
                      children: [
                        _PaymentRow(
                          isDark: isDark,
                          label: 'Items Subtotal',
                          value: '€${cart.subtotal.toStringAsFixed(2)}',
                        ),
                        const SizedBox(height: 10),
                        _PaymentRow(
                          isDark: isDark,
                          label: 'Delivery Fee',
                          value: cart.deliveryFee <= 0
                              ? 'FREE'
                              : '€${cart.deliveryFee.toStringAsFixed(2)}',
                          valueColor: cart.deliveryFee <= 0
                              ? AppColors.success
                              : null,
                        ),
                        if (cart.serviceFee > 0) ...[
                          const SizedBox(height: 10),
                          _PaymentRow(
                            isDark: isDark,
                            label: 'Service Fee',
                            value: '€${cart.serviceFee.toStringAsFixed(2)}',
                          ),
                        ],
                        if (cart.vat > 0) ...[
                          const SizedBox(height: 10),
                          _PaymentRow(
                            isDark: isDark,
                            label: 'VAT (10%)',
                            value: '€${cart.vat.toStringAsFixed(2)}',
                          ),
                        ],
                        if (cart.discount > 0) ...[
                          const SizedBox(height: 10),
                          _PaymentRow(
                            isDark: isDark,
                            label: 'Discount',
                            value: '-€${cart.discount.toStringAsFixed(2)}',
                            valueColor: AppColors.success,
                          ),
                        ],
                        const SizedBox(height: 12),
                        Divider(
                          height: 1,
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                        const SizedBox(height: 12),
                        _PaymentRow(
                          isDark: isDark,
                          label: 'Total Amount',
                          value: '€${total.toStringAsFixed(2)}',
                          emphasize: true,
                        ),
                      ],
                    ),
                  ),
                  if (orderState.isProcessing &&
                      orderState.orderData?['checkoutUrl'] != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primaryGold.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.primaryGold,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Waiting for Stripe payment...',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: isDark
                                        ? AppColors.textPrimary
                                        : AppColors.textPrimaryLight,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please complete your payment on the Stripe checkout page. Your order will be confirmed automatically once payment is received.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.textSecondary
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () async {
                                    final url = orderState
                                        .orderData!['checkoutUrl']
                                        .toString();
                                    final uri = Uri.parse(url);
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri,
                                          mode:
                                              LaunchMode.externalApplication);
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                        color: AppColors.primaryGold),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    'Reopen Stripe Checkout',
                                    style: AppTextStyles.labelLarge.copyWith(
                                      color: AppColors.primaryGold,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () {
                                  ref
                                      .read(foodGroceryOrderProvider.notifier)
                                      .reset();
                                },
                                child: Text(
                                  'Cancel',
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  ),
                ),
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLaunchingCheckout
                        ? null
                        : () {
                            if (_isCashSelected == null) {
                              _showMessage(
                                'Please select a payment method to proceed',
                                isError: true,
                              );
                              return;
                            }
                            if (_isCashSelected == true) {
                              _placeCashOrder();
                              return;
                            }
                            // Other payments selected
                            if (paymentState.isOnline) {
                              _launchOnlineCheckout();
                            } else if (paymentState.cardId != null) {
                              context.pushNamed(RouteNames.foodGroceryOrderProcessing);
                            } else {
                              _showPaymentMethods();
                            }
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
                        if (_isLaunchingCheckout) ...[
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.backgroundDark,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Text(
                          buttonText,
                          style: AppTextStyles.labelLarge.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (!_isLaunchingCheckout) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 20,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _radioCircle(bool selected) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.primaryGold : Colors.grey,
          width: 2,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryGold,
                ),
              ),
            )
          : null,
    );
  }
}

class _PaymentOptionCard extends StatelessWidget {
  const _PaymentOptionCard({
    required this.isDark,
    required this.isSelected,
    required this.cardColor,
    required this.borderColor,
    required this.icon,
    this.iconWidget,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  final bool isDark;
  final bool isSelected;
  final Color cardColor;
  final Color borderColor;
  final IconData icon;
  final Widget? iconWidget;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: isSelected ? AppColors.primaryGold : borderColor,
            width: isSelected ? 1.5 : 0.8,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: iconWidget ??
                  Icon(
                    icon,
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
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.textPrimary
                          : AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textSecondary
                          : AppColors.textSecondaryLight,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.isDark,
    required this.title,
    required this.icon,
    required this.child,
  });

  final bool isDark;
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
                size: 18,
                color: AppColors.primaryGold,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.labelSmall.copyWith(
                  color: isDark
                      ? AppColors.textPrimary
                      : AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.isDark,
    required this.label,
    required this.value,
    this.valueColor,
    this.emphasize = false,
  });

  final bool isDark;
  final String label;
  final String value;
  final Color? valueColor;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: (emphasize
                  ? AppTextStyles.titleSmall
                  : AppTextStyles.bodyMedium)
              .copyWith(
            color: isDark
                ? (emphasize
                    ? AppColors.textPrimary
                    : AppColors.textSecondary)
                : (emphasize
                    ? AppColors.textPrimaryLight
                    : AppColors.textSecondaryLight),
            fontWeight: emphasize ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: (emphasize
                  ? AppTextStyles.titleMedium
                  : AppTextStyles.bodyMedium)
              .copyWith(
            color: valueColor ??
                (emphasize
                    ? AppColors.primaryGold
                    : (isDark
                        ? AppColors.textPrimary
                        : AppColors.textPrimaryLight)),
            fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
