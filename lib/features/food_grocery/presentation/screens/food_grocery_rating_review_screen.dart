import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../data/models/food_grocery_cart.dart';
import '../providers/food_grocery_cart_provider.dart';
import '../providers/food_grocery_order_provider.dart';
import '../providers/food_grocery_rating_provider.dart';
import '../widgets/food_grocery_header.dart';

class FoodGroceryRatingReviewScreen extends ConsumerStatefulWidget {
  const FoodGroceryRatingReviewScreen({
    super.key,
  });

  @override
  ConsumerState<FoodGroceryRatingReviewScreen> createState() =>
      _FoodGroceryRatingReviewScreenState();
}

class _FoodGroceryRatingReviewScreenState
    extends ConsumerState<FoodGroceryRatingReviewScreen> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview({
    required String orderId,
    required String supplierName,
  }) async {
    FocusScope.of(context).unfocus();

    final submitted =
        await ref.read(foodGroceryRatingProvider.notifier).submitReview(
              orderId: orderId,
              supplierName: supplierName,
            );

    if (!mounted || !submitted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark ? AppColors.cardDark : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.fromLTRB(
            22,
            24,
            22,
            20,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(
                    alpha: 0.14,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 38,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                'Thank you!',
                style: AppTextStyles.titleMedium.copyWith(
                  color: isDark
                      ? AppColors.textPrimary
                      : AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Your rating and review have been submitted successfully.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.textSecondary
                      : AppColors.textSecondaryLight,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    foregroundColor: AppColors.backgroundDark,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: Text(
                    'DONE',
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) return;

    ref.read(foodGroceryRatingProvider.notifier).reset();
    context.goNamed(
      RouteNames.foodGroceryHome,
    );
  }

  void _skipReview() {
    ref.read(foodGroceryRatingProvider.notifier).reset();
    context.goNamed(
      RouteNames.foodGroceryHome,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cart = ref.watch(foodGroceryCartProvider);
    final order = ref.watch(foodGroceryOrderProvider);
    final rating = ref.watch(foodGroceryRatingProvider);

    final isGrocery = cart.cartType == FoodGroceryCartType.grocery;

    final supplierName = cart.supplierName ??
        (isGrocery ? 'Selected grocery store' : 'Selected restaurant');

    final supplierType = isGrocery ? 'Grocery store' : 'Restaurant';

    final qualityTitle = isGrocery ? 'Product quality' : 'Food quality';

    final orderId = order.orderId ?? 'Pending';

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Column(
        children: [
          const FoodGroceryHeader(
            title: 'Rating & Review',
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  28,
                ),
                children: [
                  _OrderRatingSummary(
                    isDark: isDark,
                    supplierName: supplierName,
                    supplierType: supplierType,
                    orderId: orderId,
                  ),
                  const SizedBox(height: 13),
                  _RatingSection(
                    isDark: isDark,
                    icon: Icons.shopping_bag_outlined,
                    title: 'Overall experience',
                    subtitle: 'How was your complete GOZOLT order?',
                    rating: rating.overallRating,
                    onChanged: ref
                        .read(
                          foodGroceryRatingProvider.notifier,
                        )
                        .setOverallRating,
                  ),
                  const SizedBox(height: 13),
                  _RatingSection(
                    isDark: isDark,
                    icon: isGrocery
                        ? Icons.local_grocery_store_outlined
                        : Icons.restaurant_outlined,
                    title: qualityTitle,
                    subtitle: isGrocery
                        ? 'Rate the products and packaging'
                        : 'Rate the food and packaging',
                    rating: rating.supplierRating,
                    onChanged: ref
                        .read(
                          foodGroceryRatingProvider.notifier,
                        )
                        .setSupplierRating,
                  ),
                  const SizedBox(height: 13),
                  _RatingSection(
                    isDark: isDark,
                    icon: Icons.delivery_dining_outlined,
                    title: 'Delivery experience',
                    subtitle: 'Rate the delivery partner and service',
                    rating: rating.deliveryRating,
                    onChanged: ref
                        .read(
                          foodGroceryRatingProvider.notifier,
                        )
                        .setDeliveryRating,
                  ),
                  const SizedBox(height: 13),
                  _CommentCard(
                    isDark: isDark,
                    controller: _commentController,
                    onChanged: ref
                        .read(
                          foodGroceryRatingProvider.notifier,
                        )
                        .setComment,
                  ),
                  if (rating.errorMessage != null) ...[
                    const SizedBox(height: 11),
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(
                          alpha: 0.10,
                        ),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: AppColors.error.withValues(
                            alpha: 0.25,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              rating.errorMessage!,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
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
                  onPressed: rating.isSubmitting
                      ? null
                      : () {
                          _submitReview(
                            orderId: orderId,
                            supplierName: supplierName,
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    disabledBackgroundColor: AppColors.primaryGold.withValues(
                      alpha: 0.55,
                    ),
                    foregroundColor: AppColors.backgroundDark,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: rating.isSubmitting
                      ? const SizedBox(
                          width: 21,
                          height: 21,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.3,
                            color: AppColors.backgroundDark,
                          ),
                        )
                      : Text(
                          'SUBMIT REVIEW',
                          style: AppTextStyles.labelLarge.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 5),
              TextButton(
                onPressed: rating.isSubmitting ? null : _skipReview,
                child: Text(
                  'SKIP FOR NOW',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: isDark
                        ? AppColors.textSecondary
                        : AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w600,
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

class _OrderRatingSummary extends StatelessWidget {
  const _OrderRatingSummary({
    required this.isDark,
    required this.supplierName,
    required this.supplierType,
    required this.orderId,
  });

  final bool isDark;
  final String supplierName;
  final String supplierType;
  final String orderId;

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
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: AppColors.primaryGold.withValues(
                alpha: 0.14,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: AppColors.primaryGoldDark,
              size: 23,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  supplierName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.textPrimary
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$supplierType • Order $orderId',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
    );
  }
}

class _RatingSection extends StatelessWidget {
  const _RatingSection({
    required this.isDark,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.rating,
    required this.onChanged,
  });

  final bool isDark;
  final IconData icon;
  final String title;
  final String subtitle;
  final int rating;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: AppColors.primaryGoldDark,
                size: 21,
              ),
              const SizedBox(width: 9),
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
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (index) {
                final starValue = index + 1;
                final selected = starValue <= rating;

                return IconButton(
                  onPressed: () => onChanged(starValue),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 43,
                    minHeight: 43,
                  ),
                  icon: Icon(
                    selected ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 34,
                    color: selected
                        ? AppColors.primaryGold
                        : (isDark
                            ? AppColors.textSecondary
                            : AppColors.borderLight),
                  ),
                );
              },
            ),
          ),
          if (rating > 0) ...[
            const SizedBox(height: 4),
            Text(
              _ratingText(rating),
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primaryGoldDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _ratingText(int value) {
    switch (value) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({
    required this.isDark,
    required this.controller,
    required this.onChanged,
  });

  final bool isDark;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
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
            'SHARE MORE DETAILS',
            style: AppTextStyles.labelSmall.copyWith(
              color: isDark
                  ? AppColors.textSecondary
                  : AppColors.textSecondaryLight,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Your comments help us improve the GOZOLT experience.',
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppColors.textSecondary
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 11),
          TextField(
            controller: controller,
            onChanged: onChanged,
            minLines: 3,
            maxLines: 5,
            maxLength: 300,
            style: AppTextStyles.bodyMedium.copyWith(
              color:
                  isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
            ),
            decoration: InputDecoration(
              hintText: 'Write an optional review...',
              hintStyle: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? AppColors.textSecondary
                    : AppColors.textSecondaryLight,
              ),
              filled: true,
              fillColor:
                  isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
              contentPadding: const EdgeInsets.all(13),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primaryGold,
                  width: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
