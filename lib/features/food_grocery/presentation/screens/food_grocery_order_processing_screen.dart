import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../providers/food_grocery_cart_provider.dart';
import '../providers/food_grocery_order_provider.dart';
import '../providers/food_grocery_payment_provider.dart';
import '../widgets/food_grocery_header.dart';

class FoodGroceryOrderProcessingScreen extends ConsumerStatefulWidget {
  const FoodGroceryOrderProcessingScreen({
    super.key,
  });

  @override
  ConsumerState<FoodGroceryOrderProcessingScreen> createState() =>
      _FoodGroceryOrderProcessingScreenState();
}

class _FoodGroceryOrderProcessingScreenState
    extends ConsumerState<FoodGroceryOrderProcessingScreen> {
  bool _started = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startOrderPlacement();
    });
  }

  Future<void> _startOrderPlacement() async {
    if (_started || !mounted) {
      return;
    }

    _started = true;

    final cart = ref.read(
      foodGroceryCartProvider,
    );

    final payment = ref.read(
      foodGroceryPaymentProvider,
    );

    ref.read(foodGroceryOrderProvider.notifier).reset();

    await ref.read(foodGroceryOrderProvider.notifier).placeTemporaryOrder(
          paymentMethodType: payment.paymentMethodType,
          total: cart.total,
        );
  }

  Future<void> _retry() async {
    await ref.read(foodGroceryOrderProvider.notifier).retry();
  }

  void _continueToOrderStatus() {
    final order = ref.read(
      foodGroceryOrderProvider,
    );

    if (!order.isPlaced || order.orderId == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Please wait until your order is placed',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
              ),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      return;
    }

    context.pushReplacementNamed(
      RouteNames.foodGroceryAwaitingSupplier,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final orderState = ref.watch(
      foodGroceryOrderProvider,
    );

    return PopScope(
      canPop: !orderState.isProcessing,
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: Column(
          children: [
            const FoodGroceryHeader(
              title: 'Order Placement',
            ),
            Expanded(
              child: SafeArea(
                top: false,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: orderState.isProcessing
                      ? _ProcessingView(
                          key: const ValueKey(
                            'processing',
                          ),
                          isDark: isDark,
                        )
                      : orderState.isPlaced
                          ? _OrderPlacedView(
                              key: const ValueKey(
                                'placed',
                              ),
                              isDark: isDark,
                              orderState: orderState,
                            )
                          : orderState.hasFailed
                              ? _OrderFailedView(
                                  key: const ValueKey(
                                    'failed',
                                  ),
                                  isDark: isDark,
                                  message: orderState.errorMessage ??
                                      'Unable to place your order.',
                                  onRetry: _retry,
                                )
                              : _ProcessingView(
                                  key: const ValueKey(
                                    'initial',
                                  ),
                                  isDark: isDark,
                                ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: orderState.isPlaced
            ? SafeArea(
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
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                    ),
                  ),
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _continueToOrderStatus,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(
                          double.infinity,
                          50,
                        ),
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'VIEW ORDER STATUS',
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
              )
            : null,
      ),
    );
  }
}

class _ProcessingView extends StatelessWidget {
  const _ProcessingView({
    super.key,
    required this.isDark,
  });

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          24,
          30,
          24,
          30,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 112,
              height: 112,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(
                color: AppColors.primaryGold,
                strokeWidth: 5,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Placing your order',
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineSmall.copyWith(
                color:
                    isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Please wait while we securely prepare '
              'your order and payment information.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.textSecondary
                    : AppColors.textSecondaryLight,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 26),
            _StatusStep(
              isDark: isDark,
              icon: Icons.shopping_bag_outlined,
              title: 'Checking your order',
              active: true,
            ),
            const SizedBox(height: 10),
            _StatusStep(
              isDark: isDark,
              icon: Icons.payment_outlined,
              title: 'Confirming payment method',
              active: true,
            ),
            const SizedBox(height: 10),
            _StatusStep(
              isDark: isDark,
              icon: Icons.storefront_outlined,
              title: 'Sending order to supplier',
              active: false,
            ),
            const SizedBox(height: 24),
            Text(
              'Please do not close this screen.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? AppColors.textSecondary
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderPlacedView extends StatelessWidget {
  const _OrderPlacedView({
    super.key,
    required this.isDark,
    required this.orderState,
  });

  final bool isDark;
  final FoodGroceryOrderState orderState;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        16,
        24,
        16,
        28,
      ),
      child: Column(
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.13),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              size: 58,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Order placed successfully',
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineSmall.copyWith(
              color:
                  isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your order has been sent to the supplier '
            'for acceptance.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.textSecondary
                  : AppColors.textSecondaryLight,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          _OrderDetailsCard(
            isDark: isDark,
            orderState: orderState,
          ),
          const SizedBox(height: 12),
          _AwaitingSupplierCard(
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _OrderDetailsCard extends StatelessWidget {
  const _OrderDetailsCard({
    required this.isDark,
    required this.orderState,
  });

  final bool isDark;
  final FoodGroceryOrderState orderState;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          _DetailRow(
            isDark: isDark,
            label: 'Order reference',
            value: orderState.orderId ?? 'Pending',
            emphasize: true,
          ),
          const SizedBox(height: 11),
          _DetailRow(
            isDark: isDark,
            label: 'Payment method',
            value: orderState.paymentMethodLabel,
          ),
          const SizedBox(height: 11),
          _DetailRow(
            isDark: isDark,
            label: 'Payment status',
            value: orderState.paymentStatusLabel,
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          const SizedBox(height: 12),
          _DetailRow(
            isDark: isDark,
            label: 'Order total',
            value: '€${orderState.total.toStringAsFixed(2)}',
            emphasize: true,
          ),
        ],
      ),
    );
  }
}

class _AwaitingSupplierCard extends StatelessWidget {
  const _AwaitingSupplierCard({
    required this.isDark,
  });

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryGold.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primaryGold.withValues(alpha: 0.40),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryGold.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.schedule_rounded,
              size: 21,
              color: AppColors.primaryGold,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Awaiting supplier acceptance',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.textPrimary
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'We will notify you as soon as the '
                  'supplier accepts your order.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondary
                        : AppColors.textSecondaryLight,
                    height: 1.4,
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

class _OrderFailedView extends StatelessWidget {
  const _OrderFailedView({
    super.key,
    required this.isDark,
    required this.message,
    required this.onRetry,
  });

  final bool isDark;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 50,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Order could not be placed',
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineSmall.copyWith(
                color:
                    isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.textSecondary
                    : AppColors.textSecondaryLight,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: AppColors.backgroundDark,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: 20,
                ),
                label: Text(
                  'TRY AGAIN',
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusStep extends StatelessWidget {
  const _StatusStep({
    required this.isDark,
    required this.icon,
    required this.title,
    required this.active,
  });

  final bool isDark;
  final IconData icon;
  final String title;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: active
              ? AppColors.primaryGold.withValues(alpha: 0.60)
              : isDark
                  ? AppColors.borderDark
                  : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: active
                ? AppColors.primaryGold
                : isDark
                    ? AppColors.textSecondary
                    : AppColors.textSecondaryLight,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.bodySmall.copyWith(
                color:
                    isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          if (active)
            const SizedBox(
              width: 17,
              height: 17,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryGold,
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.isDark,
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final bool isDark;
  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTextStyles.bodySmall.copyWith(
              color: emphasize
                  ? AppColors.primaryGold
                  : isDark
                      ? AppColors.textPrimary
                      : AppColors.textPrimaryLight,
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
