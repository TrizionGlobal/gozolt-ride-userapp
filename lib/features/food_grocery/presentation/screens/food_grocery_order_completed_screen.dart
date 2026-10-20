import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../providers/food_grocery_cart_provider.dart';
import '../providers/food_grocery_delivery_provider.dart';
import '../providers/food_grocery_delivery_verification_provider.dart';
import '../providers/food_grocery_order_provider.dart';
import '../widgets/food_grocery_header.dart';

class FoodGroceryOrderCompletedScreen extends ConsumerWidget {
  const FoodGroceryOrderCompletedScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final order = ref.watch(
      foodGroceryOrderProvider,
    );

    final cart = ref.watch(
      foodGroceryCartProvider,
    );

    final delivery = ref.watch(
      foodGroceryDeliveryProvider,
    );

    final verification = ref.watch(
      foodGroceryDeliveryVerificationProvider,
    );

    final orderReference = verification.orderId.trim().isNotEmpty
        ? verification.orderId
        : order.orderId ?? 'Pending';

    final supplierName = cart.supplierName ?? 'Selected supplier';

    final deliveryAddress =
        delivery.selectedAddress?.fullAddress ?? 'Selected delivery address';

    final total = verification.amount > 0 ? verification.amount : order.total;

    final String paymentMethod;
    final String paymentStatus;
    final Color paymentStatusColor;

    switch (verification.paymentStatus) {
      case FoodGroceryDeliveryPaymentStatus.paidOnline:
        paymentMethod = 'Card';
        paymentStatus = 'Paid online';
        paymentStatusColor = AppColors.success;

      case FoodGroceryDeliveryPaymentStatus.cashDue:
        paymentMethod = 'Cash';
        paymentStatus = 'Payment pending';
        paymentStatusColor = AppColors.error;

      case FoodGroceryDeliveryPaymentStatus.cashCollected:
        paymentMethod = 'Cash';
        paymentStatus = 'Cash payment completed';
        paymentStatusColor = AppColors.success;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const FoodGroceryHeader(
            title: 'Order Completed',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                16,
                18,
                16,
                28,
              ),
              children: [
                _SuccessCard(
                  isDark: isDark,
                  orderReference: orderReference,
                ),
                const SizedBox(height: 14),
                _OrderSummaryCard(
                  isDark: isDark,
                  supplierName: supplierName,
                  deliveryAddress: deliveryAddress,
                  total: total,
                ),
                const SizedBox(height: 14),
                _PaymentSummaryCard(
                  isDark: isDark,
                  paymentMethod: paymentMethod,
                  paymentStatus: paymentStatus,
                  paymentStatusColor: paymentStatusColor,
                ),
                const SizedBox(height: 14),
                _GoCoinsCard(
                  isDark: isDark,
                  orderTotal: total,
                ),
                const SizedBox(height: 14),
                _HelpCard(
                  isDark: isDark,
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
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    context.pushNamed(
                      RouteNames.foodGroceryRatingReview,
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
                  child: Text(
                    'RATE YOUR ORDER',
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 9),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton(
                  onPressed: () {
                    context.goNamed(
                      RouteNames.foodGroceryHome,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark
                        ? AppColors.textPrimary
                        : AppColors.textPrimaryLight,
                    side: BorderSide(
                      color:
                          isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'BACK TO FOOD & GROCERIES',
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
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

class _SuccessCard extends StatelessWidget {
  const _SuccessCard({
    required this.isDark,
    required this.orderReference,
  });

  final bool isDark;
  final String orderReference;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(
          alpha: isDark ? 0.14 : 0.10,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.success.withValues(
            alpha: 0.35,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(
                alpha: 0.15,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              size: 42,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            'Order delivered successfully',
            textAlign: TextAlign.center,
            style: AppTextStyles.titleLarge.copyWith(
              color:
                  isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Thank you for ordering with GOZOLT.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppColors.textSecondary
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.backgroundDark : Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  'ORDER REFERENCE',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primaryGoldDark,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  orderReference,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.textPrimary
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w700,
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

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({
    required this.isDark,
    required this.supplierName,
    required this.deliveryAddress,
    required this.total,
  });

  final bool isDark;
  final String supplierName;
  final String deliveryAddress;
  final double total;

  @override
  Widget build(BuildContext context) {
    return _CompletedSectionCard(
      isDark: isDark,
      title: 'ORDER SUMMARY',
      icon: Icons.receipt_long_outlined,
      children: [
        _CompletedRow(
          isDark: isDark,
          label: 'Supplier',
          value: supplierName,
        ),
        const SizedBox(height: 11),
        _CompletedRow(
          isDark: isDark,
          label: 'Delivered to',
          value: deliveryAddress,
          maxLines: 2,
        ),
        const SizedBox(height: 11),
        _CompletedRow(
          isDark: isDark,
          label: 'Final total',
          value: '€${total.toStringAsFixed(2)}',
          emphasize: true,
        ),
      ],
    );
  }
}

class _PaymentSummaryCard extends StatelessWidget {
  const _PaymentSummaryCard({
    required this.isDark,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.paymentStatusColor,
  });

  final bool isDark;
  final String paymentMethod;
  final String paymentStatus;
  final Color paymentStatusColor;

  @override
  Widget build(BuildContext context) {
    return _CompletedSectionCard(
      isDark: isDark,
      title: 'PAYMENT',
      icon: Icons.account_balance_wallet_outlined,
      children: [
        _CompletedRow(
          isDark: isDark,
          label: 'Payment method',
          value: paymentMethod,
        ),
        const SizedBox(height: 11),
        _CompletedRow(
          isDark: isDark,
          label: 'Payment status',
          value: paymentStatus,
          valueColor: paymentStatusColor,
          emphasize: true,
        ),
      ],
    );
  }
}

class _GoCoinsCard extends StatelessWidget {
  const _GoCoinsCard({
    required this.isDark,
    required this.orderTotal,
  });

  final bool isDark;
  final double orderTotal;

  @override
  Widget build(BuildContext context) {
    final estimatedReward = orderTotal * 0.01;
    final coinsCollected = orderTotal;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryGold.withValues(
          alpha: isDark ? 0.14 : 0.10,
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppColors.primaryGold.withValues(
            alpha: 0.38,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: const BoxDecoration(
              color: AppColors.primaryGold,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.monetization_on_outlined,
              size: 23,
              color: AppColors.backgroundDark,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GO Coins reward',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.textPrimary
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${coinsCollected.toStringAsFixed(2)} GO Coins collected • '
                  'Value €${estimatedReward.toStringAsFixed(2)}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondary
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '1%',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.primaryGoldDark,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  const _HelpCard({
    required this.isDark,
  });

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.support_agent_rounded,
            size: 21,
            color: AppColors.primaryGoldDark,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Something wrong with your delivery? Open Order Details to contact GOZOLT Support.',
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

class _CompletedSectionCard extends StatelessWidget {
  const _CompletedSectionCard({
    required this.isDark,
    required this.title,
    required this.icon,
    required this.children,
  });

  final bool isDark;
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
                size: 20,
                color: AppColors.primaryGoldDark,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.labelSmall.copyWith(
                  color: isDark
                      ? AppColors.textPrimary
                      : AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          ...children,
        ],
      ),
    );
  }
}

class _CompletedRow extends StatelessWidget {
  const _CompletedRow({
    required this.isDark,
    required this.label,
    required this.value,
    this.valueColor,
    this.maxLines = 1,
    this.emphasize = false,
  });

  final bool isDark;
  final String label;
  final String value;
  final Color? valueColor;
  final int maxLines;
  final bool emphasize;

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
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 6,
          child: Text(
            value,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: AppTextStyles.bodySmall.copyWith(
              color: valueColor ??
                  (isDark ? AppColors.textPrimary : AppColors.textPrimaryLight),
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
