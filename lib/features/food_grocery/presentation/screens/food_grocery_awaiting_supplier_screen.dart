import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../data/datasources/food_grocery_remote_datasource.dart';
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
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final activeOrder = await ref.read(foodGroceryOrderProvider.notifier).getActiveOrder();
      if (!mounted) return;
      if (activeOrder != null) {
        final backendStatus = activeOrder['status']?.toString().toUpperCase();
        final isAccepted = backendStatus != null &&
            backendStatus != 'AWAITING_SUPPLIER' &&
            backendStatus != 'PENDING';
        if (isAccepted) {
          _pollTimer?.cancel();
          context.pushReplacementNamed(RouteNames.foodGroceryLiveTracking);
          return;
        }
      }
      _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        if (mounted) {
          ref.read(foodGroceryOrderProvider.notifier).getActiveOrder();
        }
      });
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshStatus() async {
    if (_isRefreshing) {
      return;
    }

    setState(() {
      _isRefreshing = true;
    });

    await ref
        .read(foodGroceryOrderProvider.notifier)
        .getActiveOrder();

    if (!mounted) {
      return;
    }

    setState(() {
      _isRefreshing = false;
    });
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
              'Please wait for ${order.vendorTypeLabel} acceptance',
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

    ref.listen<FoodGroceryOrderState>(foodGroceryOrderProvider, (_, next) {
      if (next.isSupplierAccepted && mounted) {
        _pollTimer?.cancel();
        context.pushReplacementNamed(
          RouteNames.foodGroceryLiveTracking,
        );
      }
    });

    final order = ref.watch(
      foodGroceryOrderProvider,
    );

    final cart = ref.watch(
      foodGroceryCartProvider,
    );

    final delivery = ref.watch(
      foodGroceryDeliveryProvider,
    );

    final resolvedSupplierName = order.vendorDisplayName.isNotEmpty
        ? order.vendorDisplayName
        : (cart.supplierName ?? (order.vendorTypeLabel == 'store' ? 'Selected store' : 'Selected restaurant'));

    final structuredOrderId = order.displayBookingId.isNotEmpty
        ? order.displayBookingId
        : 'GZ-FG-PENDING';

    final address = delivery.selectedAddress;
    final orderItems = (order.orderData?['items'] as List?) ??
        (order.orderData?['orderItems'] as List?) ??
        [];
    final deliveryAddressData = order.orderData?['deliveryAddress'];
    final resolvedAddress = address ??
        (deliveryAddressData is Map
            ? FoodGroceryRemoteDatasource.parseAddress(
                Map<String, dynamic>.from(deliveryAddressData),
              )
            : null);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: Column(
          children: [
            FoodGroceryHeader(
              title: 'Order Status',
              deliveryLocation: resolvedAddress != null
                  ? (resolvedAddress.addressLine.isNotEmpty
                      ? resolvedAddress.addressLine
                      : resolvedAddress.fullAddress)
                  : null,
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
                                    vendorTypeLabel: order.vendorTypeLabel,
                                    vendorName: resolvedSupplierName,
                                  )
                                : _AwaitingStatusCard(
                                    key: const ValueKey(
                                      'awaiting',
                                    ),
                                    isDark: isDark,
                                    vendorTypeLabel: order.vendorTypeLabel,
                                    vendorName: resolvedSupplierName,
                                  ),
                          ),
                          const SizedBox(height: 12),
                          _InformationCard(
                            isDark: isDark,
                            title: 'ORDER DETAILS',
                            icon: Icons.receipt_long_outlined,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _DetailRow(
                                  isDark: isDark,
                                  label: 'Order ID',
                                  value: structuredOrderId,
                                  emphasize: true,
                                ),
                                const SizedBox(height: 11),
                                _DetailRow(
                                  isDark: isDark,
                                  label: order.vendorTypeLabel == 'store'
                                      ? 'Store'
                                      : 'Restaurant',
                                  value: resolvedSupplierName,
                                ),
                                const SizedBox(height: 14),
                                Divider(
                                  height: 1,
                                  color: isDark
                                      ? AppColors.borderDark
                                      : AppColors.borderLight,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'ORDERED ITEMS',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: isDark
                                        ? AppColors.textSecondary
                                        : AppColors.textSecondaryLight,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                if (orderItems.isEmpty) ...[
                                  Text(
                                    '1 item ordered',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: isDark
                                          ? AppColors.textSecondary
                                          : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ] else ...[
                                  for (int i = 0; i < orderItems.length; i++) ...[
                                    if (i > 0) const SizedBox(height: 12),
                                    _AwaitingOrderItemRow(
                                      isDark: isDark,
                                      item: Map<String, dynamic>.from(orderItems[i] as Map),
                                    ),
                                  ],
                                ],
                                const SizedBox(height: 14),
                                Divider(
                                  height: 1,
                                  color: isDark
                                      ? AppColors.borderDark
                                      : AppColors.borderLight,
                                ),
                                const SizedBox(height: 12),
                                _DetailRow(
                                  isDark: isDark,
                                  label: 'Order Total',
                                  value: '€${order.total.toStringAsFixed(2)}',
                                  emphasize: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _InformationCard(
                            isDark: isDark,
                            title: 'PAYMENT INFORMATION',
                            icon: Icons.payment_outlined,
                            child: Column(
                              children: [
                                _DetailRow(
                                  isDark: isDark,
                                  label: 'Payment Method',
                                  value: order.paymentMethodLabel,
                                ),
                                const SizedBox(height: 11),
                                _DetailRow(
                                  isDark: isDark,
                                  label: 'Payment Status',
                                  value: order.paymentStatusLabel,
                                ),
                                const SizedBox(height: 11),
                                _DetailRow(
                                  isDark: isDark,
                                  label: 'Amount Payable',
                                  value: '€${order.total.toStringAsFixed(2)}',
                                  emphasize: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _InformationCard(
                            isDark: isDark,
                            title: 'DELIVERY ADDRESS',
                            icon: Icons.location_on_outlined,
                            child: resolvedAddress == null
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
                                        resolvedAddress.label,
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
                                        resolvedAddress.fullAddress,
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
                            vendorTypeLabel: order.vendorTypeLabel,
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
    required this.vendorTypeLabel,
    required this.vendorName,
  });

  final bool isDark;
  final String vendorTypeLabel;
  final String vendorName;

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
      title: 'Awaiting ${vendorTypeLabel == 'store' ? 'Store' : 'Restaurant'} Acceptance',
      message: 'Your order has been sent to $vendorName. '
          'We will notify you as soon as it is accepted.',
      showProgress: true,
    );
  }
}

class _AcceptedStatusCard extends StatelessWidget {
  const _AcceptedStatusCard({
    super.key,
    required this.isDark,
    required this.vendorTypeLabel,
    required this.vendorName,
  });

  final bool isDark;
  final String vendorTypeLabel;
  final String vendorName;

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
      title: 'Order Accepted',
      message: '$vendorName accepted your order and '
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
    this.vendorTypeLabel = 'restaurant',
  });

  final bool isDark;
  final bool accepted;
  final String vendorTypeLabel;

  @override
  Widget build(BuildContext context) {
    final vendorName = vendorTypeLabel == 'store' ? 'Store' : 'Restaurant';
    return _InformationCard(
      isDark: isDark,
      title: 'WHAT HAPPENS NEXT',
      icon: Icons.route_outlined,
      child: Column(
        children: [
          _NextStep(
            isDark: isDark,
            number: '1',
            title: accepted ? 'Order accepted' : '$vendorName accepts your order',
            completed: accepted,
          ),
          const SizedBox(height: 11),
          _NextStep(
            isDark: isDark,
            number: '2',
            title: '$vendorName prepares your order',
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

class _AwaitingOrderItemRow extends StatelessWidget {
  const _AwaitingOrderItemRow({
    required this.isDark,
    required this.item,
  });

  final bool isDark;
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
    final name = item['name']?.toString() ?? 'Item';
    final lineTotal = (item['lineTotal'] as num?)?.toDouble() ??
        (((item['unitPrice'] as num?)?.toDouble() ?? 0.0) * quantity);
    final variantName = item['variantName']?.toString();
    final rawModifiers = (item['modifiers'] as List?) ??
        (item['addOns'] as List?) ??
        (item['options'] as List?) ??
        [];

    final modifierNames = <String>[];
    for (final m in rawModifiers) {
      if (m is Map) {
        final rawName = m['name']?.toString() ?? m['title']?.toString() ?? '';
        final mPrice = (m['price'] as num?)?.toDouble() ??
            (m['priceAdjustment'] as num?)?.toDouble() ??
            0.0;
        final mQty = (m['quantity'] as num?)?.toInt() ??
            (m['count'] as num?)?.toInt() ??
            1;
        if (rawName.isNotEmpty) {
          String cleanName = rawName.replaceAll(RegExp(r'\s*\(\+?€[0-9.]+\)'), '').trim();
          if (mQty > 1 && !cleanName.contains('×') && !cleanName.contains('x')) {
            cleanName = '$cleanName ($mQty×)';
          }
          final priceStr = mPrice > 0 ? ' (+€${(mPrice * mQty).toStringAsFixed(2)})' : '';
          modifierNames.add('$cleanName$priceStr');
        }
      } else if (m is String && m.isNotEmpty) {
        modifierNames.add(m);
      }
    }

    final instructions = item['instructions']?.toString();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primaryGold.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$quantity×',
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
                name,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.textPrimary
                      : AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (variantName != null && variantName.trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  variantName.trim(),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondary
                        : AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (modifierNames.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.primaryGold.withValues(alpha: 0.10)
                        : const Color(0xFFFFF9E6),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.primaryGold.withValues(alpha: 0.35),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    'Add-ons: ${modifierNames.join(', ')}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isDark
                          ? AppColors.primaryGold
                          : AppColors.primaryGoldDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
              if (instructions != null && instructions.trim().isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  'Note: "${instructions.trim()}"',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontStyle: FontStyle.italic,
                    color: isDark
                        ? AppColors.textSecondary
                        : AppColors.textSecondaryLight,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '€${lineTotal.toStringAsFixed(2)}',
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDark
                ? AppColors.textPrimary
                : AppColors.textPrimaryLight,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isDark
                ? AppColors.textSecondary
                : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
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
