import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../../food_grocery/presentation/providers/food_grocery_order_provider.dart';

class ActiveFoodGroceryBanner extends ConsumerWidget {
  const ActiveFoodGroceryBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(foodGroceryOrderProvider);

    if (!order.hasActiveOrder) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isStore = order.vendorTypeLabel == 'store';

    final vendorName = order.vendorDisplayName;
    final total = order.total;

    final subtitleParts = <String>[];
    if (vendorName.isNotEmpty) subtitleParts.add(vendorName);
    if (total > 0) subtitleParts.add('€${total.toStringAsFixed(2)}');
    final subtitle = subtitleParts.join(' \u2022 ');

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (order.isSupplierAccepted) {
          context.pushNamed(RouteNames.foodGroceryLiveTracking);
        } else {
          context.pushNamed(RouteNames.foodGroceryAwaitingSupplier);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerTheme.color ?? AppColors.borderLight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon Container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGold.withValues(alpha: 0.15),
              ),
              child: Center(
                child: Icon(
                  isStore
                      ? Icons.shopping_basket_rounded
                      : Icons.restaurant_rounded,
                  color: AppColors.primaryGold,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryGold,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          order.trackingTitle,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.primaryGold,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textSecondary
                          : AppColors.textSecondaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to view order status',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textMuted
                          : AppColors.textMutedLight,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppColors.primaryGold,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                color: Theme.of(context).scaffoldBackgroundColor,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
