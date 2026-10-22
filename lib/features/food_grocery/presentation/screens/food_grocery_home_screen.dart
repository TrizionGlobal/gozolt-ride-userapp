import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../../ride/data/models/location_data.dart';
import '../../../ride/presentation/screens/map_pin_selection_screen.dart';
import '../widgets/food_grocery_header.dart';

class FoodGroceryHomeScreen extends StatefulWidget {
  const FoodGroceryHomeScreen({super.key});

  @override
  State<FoodGroceryHomeScreen> createState() => _FoodGroceryHomeScreenState();
}

class _FoodGroceryHomeScreenState extends State<FoodGroceryHomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _deliveryLocation = 'Detecting your location...';
  bool _isDetectingLocation = false;

  // Temporary until connected to the active-order API.
  bool _hasActiveOrder = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _detectCurrentLocation();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _detectCurrentLocation() async {
    if (_isDetectingLocation) return;

    setState(() {
      _isDetectingLocation = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;

        setState(() {
          _deliveryLocation = 'Turn on location services';
        });
        return;
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (!mounted) return;

        setState(() {
          _deliveryLocation = 'Select your delivery location';
        });
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;

        setState(() {
          _deliveryLocation = 'Enable location permission';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Location permission is disabled. Enable it from app settings.',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white,
              ),
            ),
            behavior: SnackBarBehavior.floating,
            action: const SnackBarAction(
              label: 'SETTINGS',
              onPressed: Geolocator.openAppSettings,
            ),
          ),
        );

        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      final placemarks = await geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      String address = 'Current location';

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        final addressParts = <String>[
          if ((place.street ?? '').trim().isNotEmpty) place.street!.trim(),
          if ((place.locality ?? '').trim().isNotEmpty) place.locality!.trim(),
          if ((place.country ?? '').trim().isNotEmpty) place.country!.trim(),
        ];

        if (addressParts.isNotEmpty) {
          address = addressParts.join(', ');
        }
      }

      setState(() {
        _deliveryLocation = address;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _deliveryLocation = 'Select your delivery location';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isDetectingLocation = false;
        });
      }
    }
  }

  Future<void> _changeLocation() async {
    final selectedLocation = await Navigator.of(context).push<LocationData>(
      MaterialPageRoute<LocationData>(
        builder: (context) {
          return const MapPinSelectionScreen();
        },
      ),
    );

    if (!mounted || selectedLocation == null) return;

    setState(() {
      _deliveryLocation = selectedLocation.address;
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

  void _searchFoodAndGroceries(String value) {
    final query = value.trim().toLowerCase();

    if (query.isEmpty) return;

    const groceryKeywords = <String>[
      'grocery',
      'groceries',
      'milk',
      'bread',
      'eggs',
      'fruit',
      'vegetable',
      'detergent',
      'store',
      'market',
    ];

    final isGrocerySearch = groceryKeywords.any(
      query.contains,
    );

    if (isGrocerySearch) {
      _openGrocery();
    } else {
      _openFood();
    }
  }

  void _openTracking() {
    context.pushNamed(
      RouteNames.foodGroceryLiveTracking,
    );
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
            onBack: () {
              context.goNamed(RouteNames.home);
            },
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
                    onSubmitted: _searchFoodAndGroceries,
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
                          onTap: _openFood,
                        ),
                        const SizedBox(width: 12),
                        _OfferCard(
                          title: 'Free delivery',
                          subtitle: 'On selected grocery stores',
                          icon: Icons.delivery_dining_rounded,
                          startColor: const Color(0xFF134E5E),
                          endColor: const Color(0xFF71B280),
                          textColor: Colors.white,
                          onTap: _openGrocery,
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
                            context.pushNamed(
                              RouteNames.rewards,
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
                          onTap: _openFood,
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
                          onTap: _openGrocery,
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
                    onReorder: _openFood,
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
  });

  final String title;
  final String subtitle;
  final bool isDark;

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
