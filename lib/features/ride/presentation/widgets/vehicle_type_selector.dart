import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/asset_paths.dart';
import '../../data/models/fare_estimate.dart';
import '../../data/models/vehicle_type.dart';

class VehicleTypeSelector extends StatelessWidget {
  final VehicleType selected;
  final Map<VehicleType, FareEstimate>? allEstimates;
  final ValueChanged<VehicleType> onSelect;

  /// Set of vehicle types that have nearby drivers available.
  /// If null, all types are shown as available (no availability data yet).
  final Set<VehicleType>? availableTypes;

  const VehicleTypeSelector({
    super.key,
    required this.selected,
    this.allEstimates,
    required this.onSelect,
    this.availableTypes,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 182,
      child: ListView.separated(
        key: const PageStorageKey('vehicle_selector_list'),
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

          return Builder(
            builder: (itemContext) => GestureDetector(
              onTap: () {
                if (isAvailable) {
                  onSelect(type);
                  Scrollable.ensureVisible(
                    itemContext,
                    alignment: 0.5,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
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
                      price != null ? '€ ${price.toStringAsFixed(2)}' : '---',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: isSelected
                            ? AppColors.primaryGold
                            : AppColors.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person,
                          size: 12,
                          color: isSelected
                              ? (Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : AppColors.textPrimaryLight)
                              : AppColors.textMuted,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${type.maxPassengers}',
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected
                                ? (Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : AppColors.textPrimaryLight)
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    if (allEstimates?[type] != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.monetization_on,
                            size: 10,
                            color: AppColors.primaryGold,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            _goCoinsEarned(type) != null ? '+${_goCoinsEarned(type)}' : '---',
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.primaryGold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.access_time,
                            size: 10,
                            color: isSelected
                                ? (Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : AppColors.textPrimaryLight)
                                : AppColors.textMuted,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            _etaForType(type) != null ? '${_etaForType(type)} min' : '---',
                            style: TextStyle(
                              fontSize: 9,
                              color: isSelected
                                  ? (Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : AppColors.textPrimaryLight)
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ] else if (!isAvailable)
                      Text(
                        'No drivers',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: isSelected 
                              ? AppColors.textSecondary 
                              : AppColors.textMuted.withOpacity(0.7),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ));
        },
      ),
    );
  }

  int? _goCoinsEarned(VehicleType type) => allEstimates?[type]?.goCoinsEarned;

  int? _etaForType(VehicleType type) => allEstimates?[type]?.etaMinutes;

  double? _estimatedPrice(VehicleType type) => allEstimates?[type]?.estimatedFare;
}
