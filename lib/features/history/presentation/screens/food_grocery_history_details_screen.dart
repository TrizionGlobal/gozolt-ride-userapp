import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/socket_service.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/app_date_utils.dart';
import '../../../../core/utils/string_extensions.dart';
import '../../../food_grocery/data/datasources/food_grocery_remote_datasource.dart';
import '../../../food_grocery/presentation/providers/food_grocery_order_provider.dart';
import '../widgets/supplier_rating_modal.dart';
import 'food_grocery_history_view.dart';

final foodGroceryOrderDetailsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, orderId) async {
  final datasource = ref.read(foodGroceryRemoteDatasourceProvider);
  final socketService = ref.read(socketServiceProvider);

  final sub = socketService.onFoodGroceryOrderStatus.listen((event) {
    final eventOrderId = event['orderId']?.toString() ?? event['id']?.toString();
    if (eventOrderId == null || eventOrderId == orderId) {
      ref.invalidateSelf();
    }
  });

  ref.onDispose(() {
    sub.cancel();
  });

  return datasource.getOrderDetails(orderId);
});

class FoodGroceryHistoryDetailsScreen extends ConsumerStatefulWidget {
  final String orderId;

  const FoodGroceryHistoryDetailsScreen({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<FoodGroceryHistoryDetailsScreen> createState() =>
      _FoodGroceryHistoryDetailsScreenState();
}

class _FoodGroceryHistoryDetailsScreenState
    extends ConsumerState<FoodGroceryHistoryDetailsScreen> {
  void _openRatingModal(Map<String, dynamic> order) {
    final business = order['business'] as Map<String, dynamic>?;
    final storeName = business?['name']?.toString() ??
        order['businessName']?.toString() ??
        'Gozolt Partner';
    final serviceType = order['serviceType']?.toString().toUpperCase() ?? '';
    final isGrocery = serviceType.contains('GROCERY');
    final refCode = order['formattedBookingId']?.toString() ??
        order['orderReference']?.toString() ??
        '';

    SupplierRatingModal.show(
      context,
      supplierName: storeName,
      serviceTitle: isGrocery ? 'Grocery Delivery' : 'Food Delivery',
      bookingReference: refCode.isNotEmpty ? 'Order ID: $refCode' : null,
      onSubmitRating: (rating, review) async {
        final ds = ref.read(foodGroceryRemoteDatasourceProvider);
        await ds.rateOrder(
          orderId: widget.orderId,
          overallRating: rating,
          supplierRating: rating,
          deliveryRating: rating,
          tags: const [],
          comment: review,
        );
        ref.invalidate(foodGroceryOrderDetailsProvider(widget.orderId));
        ref.invalidate(foodGroceryHistoryProvider);
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'SUPPLIER_ACCEPTED':
      case 'ACCEPTED':
      case 'PREPARING':
        return Colors.blue;
      case 'READY_FOR_PICKUP':
      case 'PICKED_UP':
        return Colors.orange;
      case 'ON_THE_WAY':
      case 'ARRIVING_SOON':
      case 'ARRIVED_AT_CUSTOMER':
        return Colors.purple;
      case 'COMPLETED':
        return AppColors.success;
      case 'CANCELLED':
      case 'REFUNDED':
        return AppColors.error;
      case 'ORDER_PLACED':
      case 'PENDING':
      default:
        return AppColors.primaryGold;
    }
  }

  int _getStatusStepIndex(String status) {
    switch (status) {
      case 'ORDER_PLACED':
      case 'PENDING':
        return 0;
      case 'SUPPLIER_ACCEPTED':
      case 'ACCEPTED':
        return 1;
      case 'PREPARING':
      case 'PICKING_ITEMS':
      case 'PACKING':
      case 'READY_FOR_PICKUP':
        return 2;
      case 'PICKED_UP':
        return 3;
      case 'ON_THE_WAY':
      case 'ARRIVING_SOON':
      case 'ARRIVED_AT_CUSTOMER':
        return 4;
      case 'COMPLETED':
        return 5;
      default:
        return 0;
    }
  }

  String _formatStatusLabel(String status) {
    return status.replaceAll('_', ' ');
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone.trim());
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncDetails =
        ref.watch(foodGroceryOrderDetailsProvider(widget.orderId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.primaryGold,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: AppColors.backgroundDark,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Order Details',
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.backgroundDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: asyncDetails.when(
              skipLoadingOnReload: true,
              data: (order) => _buildContent(context, order, isDark),
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primaryGold),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load order details',
                        style: AppTextStyles.titleSmall,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref.refresh(
                          foodGroceryOrderDetailsProvider(widget.orderId),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGold,
                          foregroundColor: AppColors.backgroundDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    Map<String, dynamic> order,
    bool isDark,
  ) {
    final refCode = order['formattedBookingId']?.toString() ??
        order['orderReference']?.toString() ??
        order['id']?.toString() ??
        '';
    final status =
        (order['status'] ?? 'ORDER_PLACED').toString().trim().toUpperCase();
    final statusColor = _getStatusColor(status);
    final isCompleted = status == 'COMPLETED';
    final isCancelled = status == 'CANCELLED' || status == 'REFUNDED';
    final isActive = !isCompleted && !isCancelled;

    final serviceType = order['serviceType']?.toString().toUpperCase() ?? '';
    final isGrocery = serviceType.contains('GROCERY');

    final business = order['business'] as Map<String, dynamic>?;
    final storeName = (business?['name']?.toString() ??
            order['businessName']?.toString() ??
            'Gozolt Partner')
        .toTitleCase();
    final storeAddress =
        (business?['address']?.toString() ?? '').toTitleCase();

    final driver = order['driver'] as Map<String, dynamic>?;
    final items = (order['items'] as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];

    final rawAddress = order['deliveryAddress'];
    String addressLabel = '';
    String deliveryAddress = '';
    String recipientLine = '';
    bool leaveAtDoor = order['leaveAtDoor'] == true;
    if (rawAddress is Map) {
      final addrMap = Map<String, dynamic>.from(rawAddress);
      addressLabel = addrMap['label']?.toString().trim() ?? '';
      final full = addrMap['fullAddress']?.toString().trim() ?? '';
      final fallbackParts = [
        addrMap['addressLine'],
        addrMap['locality'],
        addrMap['city'],
        addrMap['postalCode'],
      ]
          .where((v) => v != null && v.toString().trim().isNotEmpty)
          .map((v) => v.toString().trim())
          .join(', ');
      deliveryAddress = full.isNotEmpty ? full : fallbackParts;
      final apt = addrMap['apartmentDetails']?.toString().trim() ?? '';
      if (apt.isNotEmpty && !deliveryAddress.contains(apt)) {
        deliveryAddress =
            deliveryAddress.isNotEmpty ? '$apt, $deliveryAddress' : apt;
      }
      final recipient = addrMap['recipientName']?.toString().trim() ?? '';
      final phone = addrMap['phoneNumber']?.toString().trim() ?? '';
      if (recipient.isNotEmpty || phone.isNotEmpty) {
        recipientLine =
            [recipient, phone].where((s) => s.isNotEmpty).join(' • ');
      }
      if (addrMap['leaveAtDoor'] == true) {
        leaveAtDoor = true;
      }
    } else if (rawAddress != null) {
      deliveryAddress = rawAddress.toString().trim();
    }
    final deliveryInstructions =
        order['deliveryInstructions']?.toString().trim() ?? '';
    final deliveryPin = order['deliveryPin']?.toString() ?? '';

    final subtotal = (order['subtotal'] as num?)?.toDouble() ?? 0.0;
    final deliveryFee = (order['deliveryFee'] as num?)?.toDouble() ?? 0.0;
    final serviceFee = (order['serviceFee'] as num?)?.toDouble() ?? 0.0;
    final vatAmount = (order['vatAmount'] as num?)?.toDouble() ?? 0.0;
    final goCoinsDiscount =
        (order['goCoinsDiscount'] as num?)?.toDouble() ?? 0.0;
    final totalAmount = (order['totalAmount'] as num?)?.toDouble() ?? 0.0;

    final paymentMethod =
        (order['paymentMethod'] ?? 'CASH').toString().toUpperCase();
    final paymentStatus =
        (order['paymentStatus'] ?? 'PENDING').toString().toUpperCase();
    final rating = order['rating'] as Map<String, dynamic>?;

    final createdAtFormatted = AppDateUtils.formatDateTime(order['createdAt']);

    return RefreshIndicator(
      color: AppColors.primaryGold,
      onRefresh: () =>
          ref.refresh(foodGroceryOrderDetailsProvider(widget.orderId).future),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // 1. Status & Reference Card
          _sectionCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _formatStatusLabel(status),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isGrocery ? 'Grocery' : 'Food',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primaryGold,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (refCode.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: refCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Order ID copied'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              refCode,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: isDark
                                    ? AppColors.textSecondary
                                    : AppColors.textSecondaryLight,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.copy_rounded,
                              size: 14,
                              color: isDark
                                  ? AppColors.textSecondary
                                  : AppColors.textSecondaryLight,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (createdAtFormatted.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: isDark
                            ? AppColors.textSecondary
                            : AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Placed on $createdAtFormatted',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.textSecondary
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ],
                if (isActive && deliveryPin.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primaryGold.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Delivery Handover PIN',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textPrimary
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        Text(
                          deliveryPin,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.primaryGold,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 2. Order Progress Stepper
          if (!isCancelled) ...[
            const SizedBox(height: 14),
            _sectionCard(
              isDark: isDark,
              child: _buildProgressStepper(status, isDark),
            ),
          ],

          // 3. Store / Restaurant Info
          const SizedBox(height: 14),
          _sectionCard(
            isDark: isDark,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isGrocery
                        ? Icons.local_grocery_store_rounded
                        : Icons.restaurant_rounded,
                    color: AppColors.primaryGold,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        storeName,
                        style: AppTextStyles.titleSmall.copyWith(
                          color: isDark
                              ? AppColors.textPrimary
                              : AppColors.textPrimaryLight,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (storeAddress.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          storeAddress,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.textSecondary
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 4. Items Ordered
          const SizedBox(height: 14),
          _sectionCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Items Ordered (${items.length})',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: isDark
                        ? AppColors.textPrimary
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  Text(
                    'No item details available.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textSecondary
                          : AppColors.textSecondaryLight,
                    ),
                  )
                else
                  ...items.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    final qty = (item['quantity'] as num?)?.toInt() ?? 1;
                    final name =
                        (item['name']?.toString() ?? 'Item').toTitleCase();
                    final variant = item['variantName']?.toString() ?? '';
                    final lineTotal =
                        (item['lineTotal'] as num?)?.toDouble() ??
                            ((item['unitPrice'] as num?)?.toDouble() ?? 0.0) *
                                qty;
                    final modifiers = (item['modifiers'] as List<dynamic>?)
                            ?.map((m) => m is Map ? m['name']?.toString() : m.toString())
                            .where((s) => s != null && s.isNotEmpty)
                            .join(', ') ??
                        '';

                    return Column(
                      children: [
                        if (idx > 0) ...[
                          const SizedBox(height: 10),
                          Divider(
                            height: 1,
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                          ),
                          const SizedBox(height: 10),
                        ],
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGold
                                    .withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${qty}x',
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
                                  if (variant.isNotEmpty)
                                    Text(
                                      variant,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: isDark
                                            ? AppColors.textSecondary
                                            : AppColors.textSecondaryLight,
                                      ),
                                    ),
                                  if (modifiers.isNotEmpty)
                                    Text(
                                      modifiers,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: isDark
                                            ? AppColors.textSecondary
                                            : AppColors.textSecondaryLight,
                                      ),
                                    ),
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
                        ),
                      ],
                    );
                  }),
              ],
            ),
          ),

          // 5. Delivery Address
          if (deliveryAddress.isNotEmpty) ...[
            const SizedBox(height: 14),
            _sectionCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.primaryGold,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        addressLabel.isNotEmpty
                            ? 'Delivery Address ($addressLabel)'
                            : 'Delivery Address',
                        style: AppTextStyles.titleSmall.copyWith(
                          color: isDark
                              ? AppColors.textPrimary
                              : AppColors.textPrimaryLight,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (leaveAtDoor) ...[
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Leave at door',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.blue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    deliveryAddress,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.textSecondary
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  if (recipientLine.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      recipientLine,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.textSecondary
                            : AppColors.textSecondaryLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (deliveryInstructions.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Note: $deliveryInstructions',
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
          ],

          // 6. Courier Details (if assigned)
          if (driver != null) ...[
            const SizedBox(height: 14),
            _sectionCard(
              isDark: isDark,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor:
                        AppColors.primaryGold.withValues(alpha: 0.18),
                    child: Text(
                      (driver['name']?.toString().isNotEmpty == true
                              ? driver['name'].toString()[0]
                              : 'C')
                          .toUpperCase(),
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.primaryGold,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driver['name']?.toString() ?? 'Courier',
                          style: AppTextStyles.titleSmall.copyWith(
                            color: isDark
                                ? AppColors.textPrimary
                                : AppColors.textPrimaryLight,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            driver['vehicleMake'],
                            driver['vehicleModel'],
                            driver['vehiclePlate'],
                          ]
                              .where((v) => v != null && v.toString().isNotEmpty)
                              .join(' • '),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.textSecondary
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isActive &&
                      driver['phone'] != null &&
                      driver['phone'].toString().isNotEmpty)
                    IconButton(
                      onPressed: () => _callPhone(driver['phone'].toString()),
                      icon: const Icon(
                        Icons.call_rounded,
                        color: AppColors.success,
                      ),
                      tooltip: 'Call Courier',
                    ),
                ],
              ),
            ),
          ],

          // 7. Payment Summary
          const SizedBox(height: 14),
          _sectionCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Payment Summary',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: isDark
                            ? AppColors.textPrimary
                            : AppColors.textPrimaryLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: (paymentStatus == 'PAID'
                                ? AppColors.success
                                : AppColors.primaryGold)
                            .withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$paymentMethod • $paymentStatus',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: paymentStatus == 'PAID'
                              ? AppColors.success
                              : AppColors.primaryGold,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _priceRow('Subtotal', subtotal, isDark),
                const SizedBox(height: 6),
                _priceRow('Delivery Fee', deliveryFee, isDark),
                if (serviceFee > 0) ...[
                  const SizedBox(height: 6),
                  _priceRow('Service Fee', serviceFee, isDark),
                ],
                if (vatAmount > 0) ...[
                  const SizedBox(height: 6),
                  _priceRow('VAT', vatAmount, isDark),
                ],
                if (goCoinsDiscount > 0) ...[
                  const SizedBox(height: 6),
                  _priceRow('GoCoins Discount', -goCoinsDiscount, isDark,
                      valueColor: AppColors.success),
                ],
                const SizedBox(height: 10),
                Divider(
                  height: 1,
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Amount',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: isDark
                            ? AppColors.textPrimary
                            : AppColors.textPrimaryLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '€${totalAmount.toStringAsFixed(2)}',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.primaryGold,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 8. Existing Rating Card (if already rated)
          if (rating != null) ...[
            const SizedBox(height: 14),
            _sectionCard(
              isDark: isDark,
              child: Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: AppColors.primaryGold,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Rating: ${rating['overallRating'] ?? rating['supplierRating'] ?? 5} / 5',
                          style: AppTextStyles.titleSmall.copyWith(
                            color: isDark
                                ? AppColors.textPrimary
                                : AppColors.textPrimaryLight,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (rating['comment'] != null &&
                            rating['comment'].toString().isNotEmpty)
                          Text(
                            '"${rating['comment']}"',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.textSecondary
                                  : AppColors.textSecondaryLight,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 9. Primary Action Buttons
          if (isActive) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  ref
                      .read(foodGroceryOrderProvider.notifier)
                      .pollOrderStatus(widget.orderId);
                  context.pushNamed(RouteNames.foodGroceryLiveTracking);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: AppColors.backgroundDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.delivery_dining_rounded),
                label: const Text(
                  'Track Live Order',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ] else if (isCompleted && rating == null) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => _openRatingModal(order),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: AppColors.backgroundDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.star_outline_rounded),
                label: const Text(
                  'Rate Order',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressStepper(String status, bool isDark) {
    final currentStep = _getStatusStepIndex(status);
    const steps = ['Placed', 'Accepted', 'Preparing', 'Picked Up', 'On Way', 'Delivered'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Progress',
          style: AppTextStyles.titleSmall.copyWith(
            color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: List.generate(steps.length * 2 - 1, (index) {
            if (index.isOdd) {
              final lineStep = index ~/ 2;
              final isDone = lineStep < currentStep;
              return Expanded(
                child: Container(
                  height: 2.5,
                  color: isDone
                      ? AppColors.primaryGold
                      : (isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
              );
            }
            final stepIdx = index ~/ 2;
            final isDone = stepIdx <= currentStep;
            return Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone
                    ? AppColors.primaryGold
                    : (isDark ? AppColors.cardDark : Colors.grey.shade200),
                border: Border.all(
                  color: isDone
                      ? AppColors.primaryGold
                      : (isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
              ),
              child: isDone
                  ? const Icon(
                      Icons.check,
                      size: 13,
                      color: AppColors.backgroundDark,
                    )
                  : null,
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(steps.length * 2 - 1, (index) {
            if (index.isOdd) {
              return const Expanded(child: SizedBox.shrink());
            }
            final stepIdx = index ~/ 2;
            return Text(
              steps[stepIdx],
              style: AppTextStyles.labelSmall.copyWith(
                fontSize: 9.5,
                color: stepIdx <= currentStep
                    ? (isDark
                        ? AppColors.textPrimary
                        : AppColors.textPrimaryLight)
                    : (isDark
                        ? AppColors.textSecondary
                        : AppColors.textSecondaryLight),
                fontWeight:
                    stepIdx <= currentStep ? FontWeight.w600 : FontWeight.w400,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _sectionCard({required bool isDark, required Widget child}) {
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
      child: child,
    );
  }

  Widget _priceRow(
    String label,
    double amount,
    bool isDark, {
    Color? valueColor,
  }) {
    final formatted = amount < 0
        ? '-€${amount.abs().toStringAsFixed(2)}'
        : '€${amount.toStringAsFixed(2)}';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isDark
                ? AppColors.textSecondary
                : AppColors.textSecondaryLight,
          ),
        ),
        Text(
          formatted,
          style: AppTextStyles.bodySmall.copyWith(
            color: valueColor ??
                (isDark ? AppColors.textPrimary : AppColors.textPrimaryLight),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
