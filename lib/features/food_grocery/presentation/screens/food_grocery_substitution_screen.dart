import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../providers/food_grocery_substitution_provider.dart';
import '../widgets/food_grocery_header.dart';

class FoodGrocerySubstitutionScreen extends ConsumerWidget {
  const FoodGrocerySubstitutionScreen({
    super.key,
  });

  Future<void> _submitDecisions(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final state = ref.read(
      foodGrocerySubstitutionProvider,
    );

    final allItemsSelected = state.items.every(
      (item) => item.choice != GrocerySubstitutionChoice.undecided,
    );

    if (!allItemsSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select a replacement or refund for every unavailable item.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white,
            ),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    await ref.read(foodGrocerySubstitutionProvider.notifier).submitDecisions();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Your substitution preference was submitted.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.success,
      ),
    );

    context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final substitutionState = ref.watch(
      foodGrocerySubstitutionProvider,
    );

    final allItemsSelected = substitutionState.items.every(
      (item) => item.choice != GrocerySubstitutionChoice.undecided,
    );

    final priceDifference = substitutionState.items.fold<double>(
      0,
      (total, item) {
        switch (item.choice) {
          case GrocerySubstitutionChoice.replacement:
            return total +
                (item.suggestedPrice * item.quantity - item.originalTotal);

          case GrocerySubstitutionChoice.refund:
            return total - item.originalTotal;

          case GrocerySubstitutionChoice.undecided:
            return total;
        }
      },
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const FoodGroceryHeader(
            title: 'Item Unavailable',
          ),
          Expanded(
            child: substitutionState.items.isEmpty
                ? _EmptySubstitutionState(
                    isDark: isDark,
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      18,
                      16,
                      28,
                    ),
                    children: [
                      _InformationCard(
                        isDark: isDark,
                      ),
                      const SizedBox(height: 14),
                      ...substitutionState.items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _UnavailableItemCard(
                            item: item,
                            isDark: isDark,
                            onReplacementSelected: () {
                              ref
                                  .read(
                                    foodGrocerySubstitutionProvider.notifier,
                                  )
                                  .selectChoice(
                                    item.id,
                                    GrocerySubstitutionChoice.replacement,
                                  );
                            },
                            onRefundSelected: () {
                              ref
                                  .read(
                                    foodGrocerySubstitutionProvider.notifier,
                                  )
                                  .selectChoice(
                                    item.id,
                                    GrocerySubstitutionChoice.refund,
                                  );
                            },
                          ),
                        ),
                      ),
                      _PriceDifferenceCard(
                        isDark: isDark,
                        difference: priceDifference,
                      ),
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: substitutionState.items.isEmpty
          ? null
          : SafeArea(
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
                      color:
                          isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                ),
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed:
                        substitutionState.isSubmitting || !allItemsSelected
                            ? null
                            : () => _submitDecisions(
                                  context,
                                  ref,
                                ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: AppColors.backgroundDark,
                      disabledBackgroundColor:
                          isDark ? AppColors.surfaceDark : Colors.grey.shade300,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: substitutionState.isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: AppColors.backgroundDark,
                            ),
                          )
                        : Text(
                            'CONFIRM SELECTION',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: allItemsSelected
                                  ? AppColors.backgroundDark
                                  : AppColors.textSecondaryLight,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _InformationCard extends StatelessWidget {
  const _InformationCard({
    required this.isDark,
  });

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.primaryGold.withValues(
          alpha: isDark ? 0.14 : 0.11,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primaryGold.withValues(
            alpha: 0.35,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: AppColors.primaryGoldDark,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'A grocery item is currently unavailable. '
              'Choose the suggested replacement or request a refund.',
              style: AppTextStyles.bodySmall.copyWith(
                color:
                    isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnavailableItemCard extends StatelessWidget {
  const _UnavailableItemCard({
    required this.item,
    required this.isDark,
    required this.onReplacementSelected,
    required this.onRefundSelected,
  });

  final GroceryUnavailableItem item;
  final bool isDark;
  final VoidCallback onReplacementSelected;
  final VoidCallback onRefundSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(
            'UNAVAILABLE ITEM',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _ProductIcon(
                isDark: isDark,
                icon: Icons.inventory_2_outlined,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.textPrimary
                            : AppColors.textPrimaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${item.quantity} × €${item.originalPrice.toStringAsFixed(2)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.textSecondary
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          const SizedBox(height: 14),
          Text(
            'Choose an option',
            style: AppTextStyles.bodyMedium.copyWith(
              color:
                  isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          _ChoiceTile(
            isDark: isDark,
            selected: item.choice == GrocerySubstitutionChoice.replacement,
            title: 'Accept replacement',
            subtitle: item.suggestedName,
            trailing: '€${item.suggestedPrice.toStringAsFixed(2)}',
            icon: Icons.swap_horiz_rounded,
            onTap: onReplacementSelected,
          ),
          const SizedBox(height: 9),
          _ChoiceTile(
            isDark: isDark,
            selected: item.choice == GrocerySubstitutionChoice.refund,
            title: 'Refund this item',
            subtitle: 'Remove the unavailable item from my order',
            trailing: '€${item.originalTotal.toStringAsFixed(2)}',
            icon: Icons.currency_exchange_rounded,
            onTap: onRefundSelected,
          ),
        ],
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.isDark,
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.icon,
    required this.onTap,
  });

  final bool isDark;
  final bool selected;
  final String title;
  final String subtitle;
  final String trailing;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryGold.withValues(alpha: 0.10)
              : isDark
                  ? AppColors.surfaceDark
                  : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: selected
                ? AppColors.primaryGold
                : isDark
                    ? AppColors.borderDark
                    : AppColors.borderLight,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primaryGold
                    : AppColors.primaryGold.withValues(
                        alpha: 0.13,
                      ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 19,
                color: selected
                    ? AppColors.backgroundDark
                    : AppColors.primaryGoldDark,
              ),
            ),
            const SizedBox(width: 11),
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
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textSecondary
                          : AppColors.textSecondaryLight,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  trailing,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textPrimary
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  size: 20,
                  color: selected
                      ? AppColors.primaryGoldDark
                      : isDark
                          ? AppColors.textSecondary
                          : AppColors.textSecondaryLight,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceDifferenceCard extends StatelessWidget {
  const _PriceDifferenceCard({
    required this.isDark,
    required this.difference,
  });

  final bool isDark;
  final double difference;

  @override
  Widget build(BuildContext context) {
    final differenceText = difference == 0
        ? 'No price change'
        : difference > 0
            ? '+€${difference.toStringAsFixed(2)}'
            : '-€${difference.abs().toStringAsFixed(2)}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 21,
            color: AppColors.primaryGoldDark,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Estimated price difference',
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? AppColors.textSecondary
                    : AppColors.textSecondaryLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            differenceText,
            style: AppTextStyles.bodyMedium.copyWith(
              color: difference > 0
                  ? AppColors.error
                  : difference < 0
                      ? AppColors.success
                      : isDark
                          ? AppColors.textPrimary
                          : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductIcon extends StatelessWidget {
  const _ProductIcon({
    required this.isDark,
    required this.icon,
  });

  final bool isDark;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.primaryGold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(
        icon,
        size: 25,
        color: AppColors.primaryGoldDark,
      ),
    );
  }
}

class _EmptySubstitutionState extends StatelessWidget {
  const _EmptySubstitutionState({
    required this.isDark,
  });

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(
                  alpha: 0.12,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                size: 34,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'No unavailable items',
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium.copyWith(
                color:
                    isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your grocery order does not currently require any substitutions.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? AppColors.textSecondary
                    : AppColors.textSecondaryLight,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: () => context.pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryGoldDark,
                side: const BorderSide(
                  color: AppColors.primaryGold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              child: Text(
                'RETURN TO TRACKING',
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
