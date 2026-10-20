import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../providers/food_grocery_cart_provider.dart';
import '../providers/food_grocery_delivery_provider.dart';
import '../providers/food_grocery_order_provider.dart';
import '../widgets/food_grocery_header.dart';

class FoodGroceryAwaitingSupplierScreen extends ConsumerStatefulWidget {
  const FoodGroceryAwaitingSupplierScreen({
    super.key,
  });

  @override
  ConsumerState<FoodGroceryAwaitingSupplierScreen> createState() =>
      _FoodGroceryAwaitingSupplierScreenState();
}

class _FoodGroceryAwaitingSupplierScreenState
    extends ConsumerState<FoodGroceryAwaitingSupplierScreen> {
  bool _isRefreshing = false;

  Future<void> _refreshStatus() async {
    if (_isRefreshing) {
      return;
    }

    setState(() {
      _isRefreshing = true;
    });

    await ref
        .read(foodGroceryOrderProvider.notifier)
        .simulateSupplierAcceptance();

    if (!mounted) {
      return;
    }

    setState(() {
      _isRefreshing = false;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Supplier accepted your order',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white,
            ),
          ),
          backgroundColor: AppColors.success,
        ),
      );
  }

  void _continueToTracking() {
    final order = ref.read(
      foodGroceryOrderProvider,
    );

    if (!order.isSupplierAccepted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Please wait for supplier acceptance',
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
      RouteNames.foodGroceryLiveTracking,
    );
  }

  @override
  Widget build(BuildContext context) {
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

    final supplierName = cart.supplierName ?? 'Selected supplier';

    final address = delivery.selectedAddress;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: Column(
          children: [
            const FoodGroceryHeader(
              title: 'Order Status',
            ),
            Expanded(
              child: SafeArea(
                top: false,
                child: order.isPlaced
                    ? ListView(
                        padding: const EdgeInsets.fromLTRB(
                          16,
                          18,
                          16,
                          28,
                        ),
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(
                              milliseconds: 250,
                            ),
                            child: order.isSupplierAccepted
                                ? _AcceptedStatusCard(
                                    key: const ValueKey(
                                      'accepted',
                                    ),
                                    isDark: isDark,
                                  )
                                : _AwaitingStatusCard(
                                    key: const ValueKey(
                                      'awaiting',
                                    ),
                                    isDark: isDark,
                                  ),
                          ),
                          const SizedBox(height: 12),
                          _InformationCard(
                            isDark: isDark,
                            title: 'ORDER DETAILS',
                            icon: Icons.receipt_long_outlined,
                            child: Column(
                              children: [
                                _DetailRow(
                                  isDark: isDark,
                                  label: 'Order reference',
                                  value: order.orderId ?? 'Pending',
                                  emphasize: true,
                                ),
                                const SizedBox(height: 11),
                                _DetailRow(
                                  isDark: isDark,
                                  label: 'Supplier',
                                  value: supplierName,
                                ),
                                const SizedBox(height: 11),
                                _DetailRow(
                                  isDark: isDark,
                                  label: 'Items',
                                  value: '${cart.itemCount}',
                                ),
                                const SizedBox(height: 11),
                                _DetailRow(
                                  isDark: isDark,
                                  label: 'Order total',
                                  value: '€${order.total.toStringAsFixed(2)}',
                                  emphasize: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _InformationCard(
                            isDark: isDark,
                            title: 'PAYMENT',
                            icon: Icons.payment_outlined,
                            child: Column(
                              children: [
                                _DetailRow(
                                  isDark: isDark,
                                  label: 'Payment method',
                                  value: order.paymentMethodLabel,
                                ),
                                const SizedBox(height: 11),
                                _DetailRow(
                                  isDark: isDark,
                                  label: 'Payment status',
                                  value: order.paymentStatusLabel,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _InformationCard(
                            isDark: isDark,
                            title: 'DELIVERY ADDRESS',
                            icon: Icons.location_on_outlined,
                            child: address == null
                                ? Text(
                                    'No delivery address selected',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.error,
                                    ),
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        address.label,
                                        style:
                                            AppTextStyles.bodyMedium.copyWith(
                                          color: isDark
                                              ? AppColors.textPrimary
                                              : AppColors.textPrimaryLight,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 5,
                                      ),
                                      Text(
                                        address.fullAddress,
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
                          const SizedBox(height: 12),
                          _WhatHappensNextCard(
                            isDark: isDark,
                            accepted: order.isSupplierAccepted,
                          ),
                        ],
                      )
                    : _MissingOrderView(
                        isDark: isDark,
                      ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: order.isPlaced
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
                    child: order.isSupplierAccepted
                        ? ElevatedButton(
                            onPressed: _continueToTracking,
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
                                  'TRACK ORDER',
                                  style: AppTextStyles.labelLarge.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(
                                  width: 8,
                                ),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 20,
                                ),
                              ],
                            ),
                          )
                        : OutlinedButton(
                            onPressed: _isRefreshing ? null : _refreshStatus,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(
                                double.infinity,
                                50,
                              ),
                              foregroundColor: AppColors.primaryGold,
                              side: const BorderSide(
                                color: AppColors.primaryGold,
                                width: 1.4,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  15,
                                ),
                              ),
                            ),
                            child: _isRefreshing
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primaryGold,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.refresh_rounded,
                                        size: 20,
                                      ),
                                      const SizedBox(
                                        width: 8,
                                      ),
                                      Text(
                                        'REFRESH ORDER STATUS',
                                        style:
                                            AppTextStyles.labelLarge.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
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

class _AwaitingStatusCard extends StatelessWidget {
  const _AwaitingStatusCard({
    super.key,
    required this.isDark,
  });

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return _StatusCard(
      isDark: isDark,
      icon: Icons.schedule_rounded,
      iconColor: AppColors.primaryGold,
      backgroundColor: AppColors.primaryGold.withValues(
        alpha: 0.11,
      ),
      borderColor: AppColors.primaryGold.withValues(
        alpha: 0.45,
      ),
      title: 'Awaiting supplier acceptance',
      message: 'Your order has been sent to the supplier. '
          'We will notify you as soon as it is accepted.',
      showProgress: true,
    );
  }
}

class _AcceptedStatusCard extends StatelessWidget {
  const _AcceptedStatusCard({
    super.key,
    required this.isDark,
  });

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return _StatusCard(
      isDark: isDark,
      icon: Icons.check_circle_rounded,
      iconColor: AppColors.success,
      backgroundColor: AppColors.success.withValues(
        alpha: 0.10,
      ),
      borderColor: AppColors.success.withValues(
        alpha: 0.40,
      ),
      title: 'Order accepted',
      message: 'The supplier accepted your order and '
          'will begin preparing it shortly.',
      showProgress: false,
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.isDark,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.title,
    required this.message,
    required this.showProgress,
  });

  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;
  final String title;
  final String message;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: iconColor.withValues(
                alpha: 0.14,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 36,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.titleMedium.copyWith(
              color:
                  isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppColors.textSecondary
                  : AppColors.textSecondaryLight,
              height: 1.45,
            ),
          ),
          if (showProgress) ...[
            const SizedBox(height: 15),
            const LinearProgressIndicator(
              minHeight: 4,
              color: AppColors.primaryGold,
              backgroundColor: AppColors.borderLight,
              borderRadius: BorderRadius.all(
                Radius.circular(4),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InformationCard extends StatelessWidget {
  const _InformationCard({
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
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
              Icon(
                icon,
                size: 19,
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
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }
}

class _WhatHappensNextCard extends StatelessWidget {
  const _WhatHappensNextCard({
    required this.isDark,
    required this.accepted,
  });

  final bool isDark;
  final bool accepted;

  @override
  Widget build(BuildContext context) {
    return _InformationCard(
      isDark: isDark,
      title: 'WHAT HAPPENS NEXT',
      icon: Icons.route_outlined,
      child: Column(
        children: [
          _NextStep(
            isDark: isDark,
            number: '1',
            title: accepted ? 'Order accepted' : 'Supplier accepts your order',
            completed: accepted,
          ),
          const SizedBox(height: 11),
          _NextStep(
            isDark: isDark,
            number: '2',
            title: 'Supplier prepares your order',
            completed: false,
          ),
          const SizedBox(height: 11),
          _NextStep(
            isDark: isDark,
            number: '3',
            title: 'Delivery partner collects it',
            completed: false,
          ),
          const SizedBox(height: 11),
          _NextStep(
            isDark: isDark,
            number: '4',
            title: 'Track delivery to your address',
            completed: false,
          ),
        ],
      ),
    );
  }
}

class _NextStep extends StatelessWidget {
  const _NextStep({
    required this.isDark,
    required this.number,
    required this.title,
    required this.completed,
  });

  final bool isDark;
  final String number;
  final String title;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: completed
                ? AppColors.success
                : AppColors.primaryGold.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: completed
              ? const Icon(
                  Icons.check_rounded,
                  size: 17,
                  color: Colors.white,
                )
              : Text(
                  number,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primaryGold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(
              color:
                  isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
              fontWeight: completed ? FontWeight.w600 : FontWeight.w400,
            ),
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

class _MissingOrderView extends StatelessWidget {
  const _MissingOrderView({
    required this.isDark,
  });

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 52,
              color: isDark
                  ? AppColors.textSecondary
                  : AppColors.textSecondaryLight,
            ),
            const SizedBox(height: 14),
            Text(
              'No active order found',
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium.copyWith(
                color:
                    isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Place an order to view its status.',
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
