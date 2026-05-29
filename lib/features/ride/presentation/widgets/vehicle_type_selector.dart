import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/asset_paths.dart';
import '../../data/models/fare_estimate.dart';
import '../../data/models/vehicle_type.dart';

class VehicleTypeSelector extends StatelessWidget {
  final VehicleType selected;
  final FareEstimate? estimate;
  final ValueChanged<VehicleType> onSelect;

  /// Set of vehicle types that have nearby drivers available.
  /// If null, all types are shown as available (no availability data yet).
  final Set<VehicleType>? availableTypes;

  const VehicleTypeSelector({
    super.key,
    required this.selected,
    this.estimate,
    required this.onSelect,
    this.availableTypes,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 182,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: VehicleType.values.length,
        separatorBuilder: (context, error) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final type = VehicleType.values[index];
          final isSelected = type == selected;
          final price = _estimatedPrice(type);
          // If we have availability data, check if this type has drivers
          final isAvailable = availableTypes == null || availableTypes!.contains(type);

          return GestureDetector(
            onTap: () {
              if (isAvailable) {
                onSelect(type);
              }
            },
            child: Opacity(
              opacity: (isAvailable || isSelected) ? 1.0 : 0.5,
              child: Container(
                width: 110,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).cardTheme.color : Theme.of(context).cardTheme.color?.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryGold
                        : isAvailable
                            ? (Theme.of(context).dividerTheme.color ?? AppColors.borderDark)
                            : (Theme.of(context).dividerTheme.color ?? AppColors.borderDark).withOpacity(0.3),
                    width: isSelected ? 2 : 0.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      type.iconPath,
                      width: 76,
                      height: 46,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.directions_car,
                        size: 36,
                        color: isSelected
                            ? AppColors.primaryGold
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      type.displayName,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: isSelected
                            ? (Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : AppColors.textPrimaryLight)
                            : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '€ ${price.toStringAsFixed(2)}',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: isSelected
                            ? AppColors.primaryGold
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Capacity row — always shown
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person,
                          size: 10,
                          color: isSelected
                              ? AppColors.primaryGold
                              : AppColors.textMuted,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${type.maxPassengers}',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? AppColors.primaryGold
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    if (!isAvailable)
                      // Unavailable label
                      Text(
                        'No drivers',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: isSelected 
                              ? AppColors.textSecondary 
                              : AppColors.textMuted.withOpacity(0.7),
                        ),
                      )
                    else ...[

                      // ETA
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 11,
                            color: isSelected
                                ? (Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : AppColors.textPrimaryLight)
                                : AppColors.textMuted,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${_etaForType(type)} min',
                            style: TextStyle(
                              fontSize: 9,
                              color: isSelected
                                  ? (Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : AppColors.textPrimaryLight)
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  int _goCoinsEarned(double price) => (price * 2).round();

  int _etaForType(VehicleType type) {
    final baseEta = estimate?.etaMinutes ?? 5;
    return switch (type) {
      VehicleType.go => baseEta,
      VehicleType.standard => baseEta + 1,
      VehicleType.comfort => baseEta + 2,
      VehicleType.green => baseEta + 2,
      VehicleType.prime => baseEta + 3,
      VehicleType.premiumXl => baseEta + 4,
      VehicleType.van => baseEta + 5,
      VehicleType.chauffeur => baseEta + 6,
    };
  }

  double _estimatedPrice(VehicleType type) {
    if (estimate == null) {
      // Placeholder prices
      return switch (type) {
        VehicleType.go => 8.50,
        VehicleType.standard => 12.50,
        VehicleType.comfort => 15.00,
        VehicleType.green => 14.00,
        VehicleType.prime => 18.00,
        VehicleType.premiumXl => 20.00,
        VehicleType.van => 25.00,
        VehicleType.chauffeur => 30.00,
      };
    }
    // The actual estimate is for the selected type; for others, apply a multiplier
    if (type == selected) return estimate!.estimatedFare;
    final multiplier = switch (type) {
      VehicleType.go => 0.8,
      VehicleType.standard => 1.0,
      VehicleType.comfort => 1.2,
      VehicleType.green => 1.1,
      VehicleType.prime => 1.4,
      VehicleType.premiumXl => 1.6,
      VehicleType.van => 2.0,
      VehicleType.chauffeur => 2.5,
    };
    final baseStandard = estimate!.estimatedFare /
        (switch (selected) {
          VehicleType.go => 0.8,
          VehicleType.standard => 1.0,
          VehicleType.comfort => 1.2,
          VehicleType.green => 1.1,
          VehicleType.prime => 1.4,
          VehicleType.premiumXl => 1.6,
          VehicleType.van => 2.0,
          VehicleType.chauffeur => 2.5,
        });
    return baseStandard * multiplier;
  }
}
