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
            'Transport',
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _TransportTile(
                  iconPath: AssetPaths.iconRide,
                  label: 'Ride',
                  isActive: true,
                  onTap: () {
                    context.pushNamed(RouteNames.searchDestination);
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _TransportTile(
                  iconPath: AssetPaths.iconCarRental,
                  label: 'Car Rental',
                  isActive: false,
                  onTap: () => _showComingSoon(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _TransportTile(
                  iconPath: Theme.of(context).brightness == Brightness.dark 
                      ? AssetPaths.iconBikeRentalDarkTheme 
                      : AssetPaths.iconBikeRental,
                  label: 'Bike Rental',
                  isActive: false,
                  onTap: () => _showComingSoon(context),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _TransportTile(
                  iconPath: AssetPaths.iconAirportTransfer,
                  label: 'Airport Transfer',
                  isActive: false,
                  onTap: () => _showComingSoon(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
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
              width: 160,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('OK'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _TransportTile extends StatelessWidget {
  final String iconPath;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TransportTile({
    required this.iconPath,
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
              Image.asset(
                iconPath,
                width: 96,
                height: 68,
                fit: BoxFit.contain,
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
