import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/string_extensions.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../food_grocery/data/datasources/food_grocery_remote_datasource.dart';

class FoodGroceryHistoryState {
  final List<Map<String, dynamic>> orders;
  final bool isLoading;
  final String? error;

  const FoodGroceryHistoryState({
    this.orders = const [],
    this.isLoading = false,
    this.error,
  });

  FoodGroceryHistoryState copyWith({
    List<Map<String, dynamic>>? orders,
    bool? isLoading,
    String? error,
  }) {
    return FoodGroceryHistoryState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class FoodGroceryHistoryNotifier
    extends StateNotifier<FoodGroceryHistoryState> {
  final FoodGroceryRemoteDatasource _ds;

  FoodGroceryHistoryNotifier(this._ds)
      : super(const FoodGroceryHistoryState()) {
    Future.microtask(() => load());
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await _ds.getOrderHistory();
      if (mounted) {
        state = FoodGroceryHistoryState(
          orders: items,
          isLoading: false,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: 'Unable to load food & grocery orders',
        );
      }
    }
  }
}

final foodGroceryHistoryProvider = StateNotifierProvider.autoDispose<
    FoodGroceryHistoryNotifier, FoodGroceryHistoryState>((ref) {
  final ds = ref.watch(foodGroceryRemoteDatasourceProvider);
  return FoodGroceryHistoryNotifier(ds);
});

class FoodGroceryHistoryView extends ConsumerStatefulWidget {
  const FoodGroceryHistoryView({super.key});

  @override
  ConsumerState<FoodGroceryHistoryView> createState() =>
      _FoodGroceryHistoryViewState();
}

class _FoodGroceryHistoryViewState
    extends ConsumerState<FoodGroceryHistoryView> {
  String _selectedFilter = 'All';
  static const List<String> _filters = ['All', 'Active', 'Completed', 'Cancelled'];

  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> orders) {
    if (_selectedFilter == 'All') return orders;
    return orders.where((order) {
      final status = (order['status'] ?? '').toString().toUpperCase();
      if (_selectedFilter == 'Completed') return status == 'COMPLETED';
      if (_selectedFilter == 'Cancelled') {
        return status == 'CANCELLED' || status == 'REFUNDED';
      }
      // Active
      return status != 'COMPLETED' &&
          status != 'CANCELLED' &&
          status != 'REFUNDED';
    }).toList();
  }

  String _formatDeliverySummary(dynamic rawAddress) {
    if (rawAddress == null) return '';
    if (rawAddress is Map) {
      final map = Map<String, dynamic>.from(rawAddress);
      final label = map['label']?.toString().trim() ?? '';
      final full = map['fullAddress']?.toString().trim() ?? '';
      final city = map['city']?.toString().trim() ?? '';
      final text = full.isNotEmpty ? full : city;
      if (label.isNotEmpty && text.isNotEmpty) return '$label • $text';
      return label.isNotEmpty ? label : text;
    }
    return rawAddress.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(foodGroceryHistoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (state.isLoading && state.orders.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ShimmerWrap(
            child: Container(
              height: 136,
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      );
    }

    if (state.error != null && state.orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.textMuted, size: 48),
            const SizedBox(height: 12),
            Text(
              state.error!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.read(foodGroceryHistoryProvider.notifier).load(),
              child: const Text('Retry', style: TextStyle(color: AppColors.primaryGold)),
            ),
          ],
        ),
      );
    }

    if (state.orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => ref.read(foodGroceryHistoryProvider.notifier).load(),
        color: AppColors.primaryGold,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.15),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.fastfood_outlined,
                    size: 56,
                    color: isDark
                        ? AppColors.textSecondary
                        : AppColors.textSecondaryLight,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'No food or grocery orders yet',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: isDark
                          ? AppColors.textPrimary
                          : AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Order delicious meals and fresh groceries delivered to your door.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textSecondary
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => context.pushNamed(RouteNames.foodGroceryHome),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: AppColors.backgroundDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Browse Stores'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final filteredOrders = _applyFilter(state.orders);

    return RefreshIndicator(
      onRefresh: () => ref.read(foodGroceryHistoryProvider.notifier).load(),
      color: AppColors.primaryGold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: _filters.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedFilter = filter);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryGold
                            : Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryGold
                              : (Theme.of(context).dividerTheme.color ??
                                  AppColors.borderDark),
                        ),
                      ),
                      child: Text(
                        filter,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: isSelected
                              ? Theme.of(context).scaffoldBackgroundColor
                              : (isDark
                                  ? AppColors.textSecondary
                                  : AppColors.textSecondaryLight),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: filteredOrders.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.14),
                      Center(
                        child: Text(
                          'No ${_selectedFilter.toLowerCase()} orders',
                          style: AppTextStyles.titleSmall.copyWith(
                            color: isDark
                                ? AppColors.textSecondary
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      final orderId = order['id']?.toString() ?? '';
                      final refCode = order['formattedBookingId']?.toString() ??
                          order['orderReference']?.toString() ??
                          orderId;
                      final business = order['business'] as Map<String, dynamic>?;
                      final rawBusinessName = business?['name']?.toString() ??
                          order['businessName']?.toString() ??
                          'Gozolt Partner';
                      final businessName = rawBusinessName.toTitleCase();
                      final serviceType =
                          order['serviceType']?.toString().toUpperCase() ?? '';
                      final isGrocery = serviceType.contains('GROCERY');
                      final status =
                          order['status']?.toString().toUpperCase() ?? 'COMPLETED';
                      final total = (order['totalAmount'] as num?)?.toDouble() ?? 0.0;
                      final items = (order['items'] as List<dynamic>?) ?? const [];

                      String itemsSummary = '';
                      if (items.isNotEmpty) {
                        final first = Map<String, dynamic>.from(items.first as Map);
                        final qty = (first['quantity'] as num?)?.toInt() ?? 1;
                        final name =
                            (first['name']?.toString() ?? 'Item').toTitleCase();
                        itemsSummary = items.length > 1
                            ? '${qty}x $name + ${items.length - 1} more'
                            : '${qty}x $name';
                      }

                      final deliverySummary =
                          _formatDeliverySummary(order['deliveryAddress']);

                      final createdAtStr = order['createdAt']?.toString();
                      String formattedDate = '';
                      if (createdAtStr != null) {
                        try {
                          final dt = DateTime.parse(createdAtStr).toLocal();
                          formattedDate =
                              DateFormat('dd MMM yyyy, HH:mm').format(dt);
                        } catch (_) {
                          formattedDate = createdAtStr;
                        }
                      }

                      final isCompleted = status == 'COMPLETED';
                      final isCancelled =
                          status == 'CANCELLED' || status == 'REFUNDED';

                      return GestureDetector(
                        onTap: orderId.isNotEmpty
                            ? () => context.pushNamed(
                                  RouteNames.foodGroceryHistoryDetails,
                                  extra: orderId,
                                )
                            : null,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.cardDark : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryGold
                                          .withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      isGrocery
                                          ? Icons.local_grocery_store_rounded
                                          : Icons.restaurant_rounded,
                                      color: AppColors.primaryGold,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          businessName,
                                          style: AppTextStyles.titleSmall.copyWith(
                                            color: isDark
                                                ? AppColors.textPrimary
                                                : AppColors.textPrimaryLight,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          formattedDate.isNotEmpty
                                              ? '$refCode • $formattedDate'
                                              : refCode,
                                          style: AppTextStyles.bodySmall.copyWith(
                                            color: isDark
                                                ? AppColors.textSecondary
                                                : AppColors.textSecondaryLight,
                                            fontSize: 11,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isCompleted
                                          ? AppColors.success.withValues(alpha: 0.15)
                                          : isCancelled
                                              ? AppColors.error
                                                  .withValues(alpha: 0.15)
                                              : AppColors.primaryGold
                                                  .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      status.replaceAll('_', ' '),
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: isCompleted
                                            ? AppColors.success
                                            : isCancelled
                                                ? AppColors.error
                                                : AppColors.primaryGold,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (itemsSummary.isNotEmpty ||
                                  deliverySummary.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                if (itemsSummary.isNotEmpty)
                                  Text(
                                    itemsSummary,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: isDark
                                          ? AppColors.textPrimary
                                          : AppColors.textPrimaryLight,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                if (deliverySummary.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        size: 13,
                                        color: isDark
                                            ? AppColors.textSecondary
                                            : AppColors.textSecondaryLight,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          deliverySummary,
                                          style: AppTextStyles.bodySmall.copyWith(
                                            color: isDark
                                                ? AppColors.textSecondary
                                                : AppColors.textSecondaryLight,
                                            fontSize: 11,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                              const SizedBox(height: 10),
                              Divider(
                                height: 1,
                                color: isDark
                                    ? AppColors.borderDark
                                    : AppColors.borderLight,
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Total: ',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: isDark
                                              ? AppColors.textSecondary
                                              : AppColors.textSecondaryLight,
                                        ),
                                      ),
                                      Text(
                                        '€${total.toStringAsFixed(2)}',
                                        style: AppTextStyles.titleSmall.copyWith(
                                          color: AppColors.primaryGold,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        'View Details',
                                        style: AppTextStyles.labelSmall.copyWith(
                                          color: isDark
                                              ? AppColors.textSecondary
                                              : AppColors.textSecondaryLight,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        size: 16,
                                        color: isDark
                                            ? AppColors.textSecondary
                                            : AppColors.textSecondaryLight,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
