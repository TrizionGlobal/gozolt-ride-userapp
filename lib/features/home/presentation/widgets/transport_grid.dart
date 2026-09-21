import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/asset_paths.dart';
import '../../../../core/router/route_names.dart';

class TransportGrid extends StatelessWidget {
  const TransportGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent, width: 0.5),
      ),
      child: Column(
        children: [
          Text(
            'Features',
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _TransportTile(
                  iconPath: 'assets/images/updated_userapp_images/transport.png',
                  label: 'Transport',
                  isActive: true,
                  onTap: () => _showTransportModal(context),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _TransportTile(
                  iconPath: 'assets/images/updated_userapp_images/quick_services.png',
                  label: 'Quick Services',
                  isActive: true,
                  onTap: () {
                    context.pushNamed(RouteNames.quickServicesList);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _TransportTile(
                  iconPath: 'assets/images/updated_userapp_images/groceries.png',
                  label: 'Groceries',
                  isActive: true,
                  onTap: () => _showComingSoon(context),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }

  void _showTransportModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Transport Services',
                style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _TransportTile(
                      iconPath: 'assets/images/updated_userapp_images/cab_booking.png',
                      label: 'Ride',
                      isActive: true,
                      onTap: () {
                        Navigator.pop(ctx);
                        context.pushNamed(RouteNames.searchDestination);
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _TransportTile(
                      iconPath: 'assets/images/updated_userapp_images/car_rental.png',
                      label: 'Car Rental',
                      isActive: true,
                      onTap: () {
                        Navigator.pop(ctx);
                        context.pushNamed(RouteNames.carRentalSearch);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _TransportTile(
                      iconPath: 'assets/images/updated_userapp_images/bike_rental.png',
                      label: 'Bike Rental',
                      isActive: true,
                      onTap: () {
                        Navigator.pop(ctx);
                        context.pushNamed(RouteNames.bikeRentalSearch);
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _TransportTile(
                      iconPath: 'assets/images/updated_userapp_images/airport_transport.png',
                      label: 'Airport Transfer',
                      isActive: false,
                      onTap: () {
                        Navigator.pop(ctx);
                        _showComingSoon(context);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showComingSoon(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.construction_rounded,
                size: 48,
                color: AppColors.primaryGold,
              ),
              const SizedBox(height: 16),
              Text(
                'Coming Soon!',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "We're working on bringing you this feature.",
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 100,
                height: 36,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK', style: TextStyle(fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransportTile extends StatelessWidget {
  final String? iconPath;
  final IconData? iconData;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TransportTile({
    this.iconPath,
    this.iconData,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Opacity(
        opacity: isActive ? 1.0 : 0.55,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: isActive
                ? Border.all(
                    color: AppColors.primaryGold,
                    width: 1.5,
                  )
                : Border.all(
                    color: Colors.transparent,
                    width: 1,
                  ),
          ),
          child: Column(
            children: [
              if (iconPath != null)
                Image.asset(
                  iconPath!,
                  width: 96,
                  height: 68,
                  fit: BoxFit.contain,
                )
              else if (iconData != null)
                SizedBox(
                  width: 96,
                  height: 68,
                  child: Center(
                    child: Icon(
                      iconData,
                      size: 48,
                      color: AppColors.primaryGold,
                    ),
                  ),
                ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTextStyles.titleSmall.copyWith(
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
