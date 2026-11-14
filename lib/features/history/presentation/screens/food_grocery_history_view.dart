import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
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

class FoodGroceryHistoryView extends ConsumerWidget {
  const FoodGroceryHistoryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              height: 120,
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
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

    return RefreshIndicator(
      onRefresh: () => ref.read(foodGroceryHistoryProvider.notifier).load(),
      color: AppColors.primaryGold,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
        itemCount: state.orders.length,
        itemBuilder: (context, index) {
          final order = state.orders[index];
          final refCode = order['formattedBookingId']?.toString() ??
              order['orderReference']?.toString() ??
              order['id']?.toString() ??
              '';
          final business = order['business'] as Map<String, dynamic>?;
          final businessName = business?['name']?.toString() ??
              order['businessName']?.toString() ??
              'Gozolt Partner';
          final status = order['status']?.toString().toUpperCase() ?? 'COMPLETED';
          final total = (order['totalAmount'] as num?)?.toDouble() ?? 0.0;
          final createdAtStr = order['createdAt']?.toString();
          String formattedDate = '';
          if (createdAtStr != null) {
            try {
              final dt = DateTime.parse(createdAtStr).toLocal();
              formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(dt);
            } catch (_) {
              formattedDate = createdAtStr;
            }
          }

          final isCompleted = status == 'COMPLETED';
          final isCancelled = status == 'CANCELLED';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
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
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppColors.success.withValues(alpha: 0.15)
                            : isCancelled
                                ? AppColors.error.withValues(alpha: 0.15)
                                : AppColors.primaryGold.withValues(alpha: 0.15),
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
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      'Order ID: $refCode',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.textSecondary
                            : AppColors.textSecondaryLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (formattedDate.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textSecondary
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formattedDate,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.textSecondary
                              : AppColors.textSecondaryLight,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
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
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.textSecondary
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    Text(
                      '€${total.toStringAsFixed(2)}',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.primaryGold,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
