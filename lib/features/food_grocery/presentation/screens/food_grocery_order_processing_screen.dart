import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../../ride/data/models/saved_payment_method.dart';
import '../providers/food_grocery_cart_provider.dart';
import '../providers/food_grocery_delivery_provider.dart';
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
      final uri = GoRouterState.of(context).uri;
      final status = uri.queryParameters['status'];
      final orderId = uri.queryParameters['orderId'] ?? uri.queryParameters['bookingId'];

      if (status == 'success' && orderId != null && orderId.isNotEmpty) {
        _started = true;
        ref.read(foodGroceryOrderProvider.notifier).handlePaymentSuccess(orderId);
        return;
      } else if (status == 'failed') {
        _started = true;
        final errorMsg = uri.queryParameters['errorMessage'];
        ref.read(foodGroceryOrderProvider.notifier).handlePaymentFailed(orderId ?? '', errorMsg);
        return;
      }

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

    final delivery = ref.read(
      foodGroceryDeliveryProvider,
    );

    ref.read(foodGroceryOrderProvider.notifier).reset();

    final goCoinsToUse =
        cart.discount > 0 ? (cart.discount / 0.01).round() : 0;

    await ref.read(foodGroceryOrderProvider.notifier).placeOrder(
          cart: cart,
          paymentMethodType: payment.isCash
              ? PaymentMethodType.cash
              : PaymentMethodType.card,
          deliveryAddressId: delivery.selectedAddress?.id,
          deliveryAddressSnapshot: delivery.selectedAddress?.toJson(
            leaveAtDoor: delivery.leaveAtDoor,
            instructions: delivery.deliveryInstructions,
          ),
          leaveAtDoor: delivery.leaveAtDoor,
          deliveryInstructions: delivery.deliveryInstructions,
          goCoinsToUse: goCoinsToUse,
          stripePaymentMethodId: payment.isCash || payment.isOnline ? null : payment.cardId,
          stripePaymentIntentId: payment.isCash || !payment.isOnline ? null : payment.cardId,
        );
  }

  Future<void> _retry() async {
    _started = false;
    await _startOrderPlacement();
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
                          vendorTypeLabel: orderState.vendorTypeLabel,
                          checkoutUrl: orderState.orderData?['checkoutUrl']?.toString(),
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
                                  vendorTypeLabel: orderState.vendorTypeLabel,
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
    this.vendorTypeLabel = 'restaurant',
    this.checkoutUrl,
  });

  final bool isDark;
  final String vendorTypeLabel;
  final String? checkoutUrl;

  @override
  Widget build(BuildContext context) {
    final isAwaitingStripe = checkoutUrl != null && checkoutUrl!.isNotEmpty;
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
              isAwaitingStripe ? 'Completing payment' : 'Placing your order',
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineSmall.copyWith(
                color:
                    isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isAwaitingStripe
                  ? 'Please complete your payment in the browser. Your order will be confirmed automatically once payment is received.'
                  : 'Please wait while we securely prepare your order and payment information.',
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
              title: isAwaitingStripe
                  ? 'Awaiting Stripe payment'
                  : 'Confirming payment method',
              active: true,
            ),
            const SizedBox(height: 10),
            _StatusStep(
              isDark: isDark,
              icon: Icons.storefront_outlined,
              title: 'Sending order to $vendorTypeLabel',
              active: false,
            ),
            if (isAwaitingStripe) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(checkoutUrl!);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text(
                  'Reopen Payment Page',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryGoldDark,
                  side: const BorderSide(color: AppColors.primaryGold, width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
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
            'Your order has been sent to the ${orderState.vendorTypeLabel} '
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
          _AwaitingAcceptanceCard(
            isDark: isDark,
            vendorTypeLabel: orderState.vendorTypeLabel,
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
    final orderItems = (orderState.orderData?['items'] as List?) ?? [];

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailRow(
            isDark: isDark,
            label: 'Order ID',
            value: orderState.displayBookingId.isNotEmpty
                ? orderState.displayBookingId
                : (orderState.orderId ?? 'Pending'),
            emphasize: true,
          ),
          const SizedBox(height: 11),
          _DetailRow(
            isDark: isDark,
            label: orderState.vendorTypeLabel == 'store' ? 'Store' : 'Restaurant',
            value: orderState.vendorDisplayName,
          ),
          if (orderItems.isNotEmpty) ...[
            const SizedBox(height: 14),
            Divider(
              height: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
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
            for (int i = 0; i < orderItems.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _ProcessingOrderItemRow(
                isDark: isDark,
                item: Map<String, dynamic>.from(orderItems[i] as Map),
              ),
            ],
          ],
          const SizedBox(height: 14),
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          const SizedBox(height: 12),
          _DetailRow(
            isDark: isDark,
            label: 'Payment Method',
            value: orderState.paymentMethodLabel,
          ),
          const SizedBox(height: 11),
          _DetailRow(
            isDark: isDark,
            label: 'Payment Status',
            value: orderState.paymentMethodType == PaymentMethodType.cash
                ? 'Payment due on delivery'
                : 'Paid successfully',
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          const SizedBox(height: 12),
          _DetailRow(
            isDark: isDark,
            label: 'Order Total',
            value: '€${orderState.total.toStringAsFixed(2)}',
            emphasize: true,
          ),
        ],
      ),
    );
  }
}

class _ProcessingOrderItemRow extends StatelessWidget {
  const _ProcessingOrderItemRow({
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primaryGold.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(7),
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
                  ),
                ),
              ],
              if (modifierNames.isNotEmpty) ...[
                const SizedBox(height: 3),
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

class _AwaitingAcceptanceCard extends StatelessWidget {
  const _AwaitingAcceptanceCard({
    required this.isDark,
    required this.vendorTypeLabel,
  });

  final bool isDark;
  final String vendorTypeLabel;

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
                  'Awaiting ${vendorTypeLabel.toLowerCase() == 'store' ? 'Store' : 'Restaurant'} Acceptance',
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
                  '${vendorTypeLabel.toLowerCase()} accepts your order.',
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
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: AppColors.primaryGold,
                    width: 1.2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(
                  Icons.payment_rounded,
                  size: 18,
                  color: AppColors.primaryGold,
                ),
                label: Text(
                  'CHANGE PAYMENT METHOD',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.primaryGold,
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
