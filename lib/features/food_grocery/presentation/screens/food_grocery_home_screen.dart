import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../widgets/food_grocery_header.dart';

class FoodGroceryHomeScreen extends StatefulWidget {
  const FoodGroceryHomeScreen({super.key});

  @override
  State<FoodGroceryHomeScreen> createState() => _FoodGroceryHomeScreenState();
}

class _FoodGroceryHomeScreenState extends State<FoodGroceryHomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Temporary values. These will later come from providers and APIs.
  String _deliveryLocation = 'Valletta, Malta';
  bool _hasActiveOrder = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showTemporaryMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white,
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _changeLocation() {
    // TODO(FOOD_GROCERY_API):
    // Replace with the saved-address/location-selection screen.
    setState(() {
      _deliveryLocation = _deliveryLocation == 'Valletta, Malta'
          ? 'Sliema, Malta'
          : 'Valletta, Malta';
    });
  }

  void _openFood() {
    context.pushNamed(
      RouteNames.foodGroceryRestaurants,
    );
  }

  void _openGrocery() {
    context.pushNamed(
      RouteNames.foodGroceryStores,
    );
  }

  void _openTracking() {
    // Screen 14 route will be connected later.
    _showTemporaryMessage('Live Order Tracking will open here');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          FoodGroceryHeader(
            title: 'Food & Groceries',
            deliveryLocation: _deliveryLocation,
            onChangeLocation: _changeLocation,
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  _SearchField(
                    controller: _searchController,
                    isDark: isDark,
                    onSubmitted: (value) {
                      if (value.trim().isEmpty) return;

                      _showTemporaryMessage(
                        'Searching for ${value.trim()}',
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  _SectionHeading(
                    title: 'What are you looking for?',
                    subtitle: 'Fresh meals and daily essentials',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ServiceCard(
                          title: 'Food',
                          subtitle: 'Restaurants & meals',
                          icon: Icons.restaurant_rounded,
                          isDark: isDark,
                          onTap: _openFood,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ServiceCard(
                          title: 'Groceries',
                          subtitle: 'Stores & essentials',
                          icon: Icons.local_grocery_store_rounded,
                          isDark: isDark,
                          onTap: _openGrocery,
                        ),
                      ),
                    ],
                  ),
                  if (_hasActiveOrder) ...[
                    const SizedBox(height: 20),
                    _ActiveOrderCard(
                      isDark: isDark,
                      onTrackOrder: _openTracking,
                      onDismiss: () {
                        setState(() {
                          _hasActiveOrder = false;
                        });
                      },
                    ),
                  ],
                  const SizedBox(height: 20),
                  _SectionHeading(
                    title: 'Offers for you',
                    subtitle: 'Save more on your next order',
                    isDark: isDark,
                    actionText: 'View all',
                    onActionPressed: () {
                      _showTemporaryMessage(
                        'All Food & Grocery offers will open here',
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 126,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _OfferCard(
                          title: '20% OFF',
                          subtitle: 'Selected restaurants',
                          icon: Icons.restaurant_menu_rounded,
                          startColor: AppColors.primaryGoldDark,
                          endColor: AppColors.primaryGold,
                          textColor: AppColors.backgroundDark,
                          onTap: () {
                            _showTemporaryMessage(
                              'Restaurant offer selected',
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        _OfferCard(
                          title: 'Free delivery',
                          subtitle: 'On selected grocery stores',
                          icon: Icons.delivery_dining_rounded,
                          startColor: const Color(0xFF134E5E),
                          endColor: const Color(0xFF71B280),
                          textColor: Colors.white,
                          onTap: () {
                            _showTemporaryMessage(
                              'Free-delivery offer selected',
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        _OfferCard(
                          title: 'Use GO Coins',
                          subtitle: 'Save on eligible orders',
                          icon: Icons.toll_rounded,
                          startColor: const Color(0xFF313860),
                          endColor: const Color(0xFF5863A8),
                          textColor: Colors.white,
                          onTap: () {
                            _showTemporaryMessage(
                              'GO Coins offer selected',
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SectionHeading(
                    title: 'Recommended near you',
                    subtitle: 'Popular choices around $_deliveryLocation',
                    isDark: isDark,
                    actionText: 'See all',
                    onActionPressed: () {
                      _showTemporaryMessage(
                        'Recommended suppliers will open here',
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 188,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _SupplierCard(
                          name: 'Harbour Kitchen',
                          category: 'Mediterranean • Food',
                          rating: '4.8',
                          deliveryTime: '25–35 min',
                          deliveryFee: '€1.50 delivery',
                          icon: Icons.lunch_dining_rounded,
                          isDark: isDark,
                          onTap: () {
                            _showTemporaryMessage(
                              'Harbour Kitchen selected',
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        _SupplierCard(
                          name: 'Fresh Market',
                          category: 'Groceries • Daily essentials',
                          rating: '4.7',
                          deliveryTime: '30–40 min',
                          deliveryFee: '€2.00 delivery',
                          icon: Icons.shopping_basket_rounded,
                          isDark: isDark,
                          onTap: () {
                            _showTemporaryMessage(
                              'Fresh Market selected',
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SectionHeading(
                    title: 'Order again',
                    subtitle: 'Your recent favourites',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _ReorderCard(
                    supplierName: 'Valletta Pizza House',
                    itemSummary: 'Margherita Pizza • Garlic Bread',
                    previousTotal: '€18.50',
                    isDark: isDark,
                    onReorder: () {
                      // Backend must revalidate price, stock and availability.
                      _showTemporaryMessage(
                        'Checking availability and latest price',
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.isDark,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool isDark;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onSubmitted: onSubmitted,
      style: AppTextStyles.bodyMedium.copyWith(
        color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
      ),
      decoration: InputDecoration(
        hintText: 'Search food, restaurants, groceries or products',
        hintStyle: AppTextStyles.bodySmall.copyWith(
          color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 21,
          color:
              isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
        ),
        suffixIcon: IconButton(
          tooltip: 'Search',
          onPressed: () => onSubmitted(controller.text),
          icon: const Icon(
            Icons.arrow_forward_rounded,
            size: 19,
          ),
          color: AppColors.primaryGoldDark,
        ),
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.primaryGold,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.subtitle,
    required this.isDark,
    this.actionText,
    this.onActionPressed,
  });

  final String title;
  final String subtitle;
  final bool isDark;
  final String? actionText;
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.titleMedium.copyWith(
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
                ),
              ),
            ],
          ),
        ),
        if (actionText != null && onActionPressed != null)
          TextButton(
            onPressed: onActionPressed,
            child: Text(
              actionText!,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primaryGoldDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 132),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 23,
                  color: AppColors.primaryGoldDark,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: AppTextStyles.titleSmall.copyWith(
                  color: isDark
                      ? AppColors.textPrimary
                      : AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
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
      ),
    );
  }
}

class _ActiveOrderCard extends StatelessWidget {
  const _ActiveOrderCard({
    required this.isDark,
    required this.onTrackOrder,
    required this.onDismiss,
  });

  final bool isDark;
  final VoidCallback onTrackOrder;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryGold.withValues(alpha: 0.65),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primaryGold.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.delivery_dining_rounded,
              size: 23,
              color: AppColors.primaryGoldDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your order is being prepared',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.textPrimary
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Estimated arrival: 25–35 min',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondary
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onTrackOrder,
            child: Text(
              'Track',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primaryGoldDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.startColor,
    required this.endColor,
    required this.textColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color startColor;
  final Color endColor;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 230,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [startColor, endColor],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: textColor.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                icon,
                size: 36,
                color: textColor.withValues(alpha: 0.90),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupplierCard extends StatelessWidget {
  const _SupplierCard({
    required this.name,
    required this.category,
    required this.rating,
    required this.deliveryTime,
    required this.deliveryFee,
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  final String name;
  final String category;
  final String rating;
  final String deliveryTime;
  final String deliveryFee;
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 248,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 72,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 38,
                  color: AppColors.primaryGoldDark,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleSmall.copyWith(
                  color: isDark
                      ? AppColors.textPrimary
                      : AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.textSecondary
                      : AppColors.textSecondaryLight,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 17,
                    color: AppColors.primaryGoldDark,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    rating,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isDark
                          ? AppColors.textPrimary
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$deliveryTime • $deliveryFee',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isDark
                            ? AppColors.textSecondary
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReorderCard extends StatelessWidget {
  const _ReorderCard({
    required this.supplierName,
    required this.itemSummary,
    required this.previousTotal,
    required this.isDark,
    required this.onReorder,
  });

  final String supplierName;
  final String itemSummary;
  final String previousTotal;
  final bool isDark;
  final VoidCallback onReorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primaryGold.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.history_rounded,
              color: AppColors.primaryGoldDark,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  itemSummary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondary
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Previous total: $previousTotal',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondary
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onReorder,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.backgroundDark,
              backgroundColor: AppColors.primaryGold,
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 9,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Reorder',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.backgroundDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
