import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/gozolt_button.dart';

import '../widgets/bike_rental_header.dart';
import '../../domain/models/bike_model.dart';
import '../providers/bike_rental_search_provider.dart';
import '../../../../core/utils/geo_utils.dart';

class BikeRentalPackagesScreen extends ConsumerStatefulWidget {
  final BikeModel? bike;
  const BikeRentalPackagesScreen({super.key, this.bike});

  @override
  ConsumerState<BikeRentalPackagesScreen> createState() => _BikeRentalPackagesScreenState();
}

class _BikeRentalPackagesScreenState extends ConsumerState<BikeRentalPackagesScreen> {
  String _selectedPackage = '';

  @override
  void initState() {
    super.initState();
    if (widget.bike != null) {
      if (widget.bike!.protectionPackages.isNotEmpty) {
        _selectedPackage = widget.bike!.protectionPackages.last.valueIdentifier;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final searchState = ref.watch(bikeRentalSearchProvider);
    final isFlexible = searchState.isFlexible;
    
    int days = 1;
    if (searchState.pickupDate != null && searchState.dropoffDate != null) {
      final minutes = searchState.dropoffDate!.difference(searchState.pickupDate!).inMinutes;
      if (minutes > 0) {
        days = (minutes / 1440).ceil();
      }
    }

    // Calculate total price based on selected package
    double basePrice = (widget.bike?.pricePerDay ?? 0.0) * days;
    double packagePrice = 0.0;
    String deductibleString = 'up to €1,200.00 financial responsibility';

    if (widget.bike != null && widget.bike!.protectionPackages.isNotEmpty) {
      try {
        final pkg = widget.bike!.protectionPackages.firstWhere((p) => p.valueIdentifier == _selectedPackage);
        packagePrice = pkg.pricePerDay * days;
        
        if (pkg.deductibleText.toLowerCase().contains('no')) {
          deductibleString = 'with no financial responsibility';
        } else {
          deductibleString = '${pkg.deductibleText.toLowerCase().replaceAll('deductible: ', '')} financial responsibility';
        }
      } catch (_) {}
    }

    final double flexiblePrice = isFlexible ? (15.0 * days) : 0.0;
    
    double pickupFee = 0.0;
    double dropoffFee = 0.0;
    double pickupDistance = 0.0;
    double dropoffDistance = 0.0;
    final supLat = widget.bike?.supplierLatitude;
    final supLng = widget.bike?.supplierLongitude;
    
    if (supLat != null && supLng != null) {
      if (searchState.pickupLat != null && searchState.pickupLng != null) {
        if (searchState.deliveryType == 'SELF_PICKUP') {
          pickupDistance = 0.0;
        } else {
          pickupDistance = haversineDistanceKm(supLat, supLng, searchState.pickupLat!, searchState.pickupLng!);
        }
        pickupFee = pickupDistance * (widget.bike?.deliveryCharge ?? 0.0);
      }
      if (searchState.dropoffLat != null && searchState.dropoffLng != null) {
        if (searchState.deliveryType == 'SELF_PICKUP' && 
            searchState.dropoffLat == searchState.pickupLat && 
            searchState.dropoffLng == searchState.pickupLng) {
          dropoffDistance = 0.0;
        } else {
          dropoffDistance = haversineDistanceKm(supLat, supLng, searchState.dropoffLat!, searchState.dropoffLng!);
        }
        dropoffFee = dropoffDistance * (widget.bike?.deliveryCharge ?? 0.0);
      }
    }
    
    final double deliveryFee = pickupFee + dropoffFee;
    double totalPrice = basePrice + flexiblePrice + packagePrice + deliveryFee;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const BikeRentalHeader(title: 'Which protection package do you need?'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  
                  if (widget.bike?.protectionPackages.isEmpty ?? true)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('No protection packages available for this bike.'),
                    )
                  else
                    ...widget.bike!.protectionPackages.map((package) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildProtectionCard(
                          title: package.title,
                          stars: package.stars,
                          deductibleText: package.deductibleText,
                          deductibleColor: package.deductibleColorHex != null
                              ? Color(int.parse(package.deductibleColorHex!.replaceAll('#', '0xFF')))
                              : (isDark ? AppColors.textPrimary : AppColors.textPrimaryLight),
                          priceText: package.pricePerDay == 0 ? 'Included' : '€${package.pricePerDay.toStringAsFixed(2)} / day',
                          originalPriceText: package.originalPricePerDay != null ? '€${package.originalPricePerDay!.toStringAsFixed(2)} / day' : null,
                          discountText: package.discountText,
                          features: package.features.map((key, value) => MapEntry(key, value == true)),
                          value: package.valueIdentifier,
                          groupValue: _selectedPackage,
                          onChanged: (val) => setState(() => _selectedPackage = val!),
                          isDark: isDark,
                        ),
                      );
                    }).toList(),
                  const SizedBox(height: 32),


                  
                  // Booking Overview
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your booking overview', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        _buildOverviewItem('Third party insurance', isDark),
                        _buildOverviewItem('Loss Damage Waiver (including theft protection) $deductibleString', isDark),
                        _buildOverviewItem('Unlimited kilometers', isDark),
                        _buildOverviewItem('Booking option: Best price - Free cancellation and rebooking within 24h.', isDark),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          boxShadow: [
            BoxShadow(color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    _showPriceBreakdown(context, basePrice, flexiblePrice, packagePrice, pickupFee, pickupDistance, dropoffFee, dropoffDistance, _selectedPackage, days);
                  },child: Row(
                    children: [
                      Text('€${totalPrice.toStringAsFixed(2)}', style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      Text('total', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
                      Icon(Icons.keyboard_arrow_up, color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight),
                    ],
                  ),
                ),
              ),
              GozoltButton(
                label: 'Continue',
                width: 160,
                icon: Icons.arrow_forward,
                onPressed: () {
                  final updatedBike = widget.bike?.copyWith(
                    selectedProtectionPackageId: _selectedPackage,
                  );
                  context.pushNamed(RouteNames.bikeRentalReview, extra: updatedBike);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProtectionCard({
    required String title,
    required int stars,
    required String deductibleText,
    required Color deductibleColor,
    required String priceText,
    String? originalPriceText,
    String? discountText,
    Map<String, bool>? features,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
    required bool isDark,
  }) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryGold : (isDark ? AppColors.borderDark : Colors.grey.shade300),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: AppColors.primaryGold,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(title, style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold))),
                      Row(
                        children: List.generate(3, (index) => Icon(
                          index < stars ? Icons.star : Icons.star_border,
                          size: 16,
                          color: isDark ? Colors.white : Colors.black,
                        )),
                      ),
                      const SizedBox(width: 8),
                      Icon(isSelected ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 20, color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(deductibleText, style: AppTextStyles.bodyMedium.copyWith(color: deductibleColor, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(priceText, style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                      if (originalPriceText != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          originalPriceText,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (discountText != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.deepOrange),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(discountText, style: const TextStyle(color: Colors.deepOrange, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                  if (isSelected && features != null) ...[
                    const SizedBox(height: 16),
                    ...features.entries.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            entry.value ? Icons.check : Icons.close, 
                            size: 18, 
                            color: isDark ? Colors.white54 : Colors.black54
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(
                            entry.key, 
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: entry.value 
                                  ? (isDark ? AppColors.textPrimary : AppColors.textPrimaryLight) 
                                  : Colors.grey,
                            ),
                          )),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.info_outline, 
                            size: 18, 
                            color: isDark ? Colors.white54 : Colors.black54
                          ),
                        ],
                      ),
                    )).toList(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildOverviewItem(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check, size: 18, color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
          const SizedBox(width: 12),
          Icon(Icons.info_outline, size: 18, color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight),
        ],
      ),
    );
  }

  void _showPriceBreakdown(BuildContext context, double basePrice, double flexiblePrice, double packagePrice, double pickupFee, double pickupDistance, double dropoffFee, double dropoffDistance, String packageIdentifier, int days) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    double totalPrice = basePrice + flexiblePrice + packagePrice + pickupFee + dropoffFee;
    
    // Find selected package name
    String packageName = 'Protection Package';
    if (widget.bike != null && widget.bike!.protectionPackages.isNotEmpty) {
      try {
        packageName = widget.bike!.protectionPackages.firstWhere((p) => p.valueIdentifier == _selectedPackage).title;
      } catch (_) {}
    }
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Price Breakdown', style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Rental ($days ${days == 1 ? 'Day' : 'Days'})', style: AppTextStyles.bodyLarge),
                  Text('€${basePrice.toStringAsFixed(2)}', style: AppTextStyles.titleMedium),
                ],
              ),
              if (flexiblePrice > 0) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Stay Flexible ($days ${days == 1 ? 'Day' : 'Days'})', style: AppTextStyles.bodyLarge),
                    Text('€${flexiblePrice.toStringAsFixed(2)}', style: AppTextStyles.titleMedium),
                  ],
                ),
              ],
              if (pickupFee > 0) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Pickup Fee (${pickupDistance.toStringAsFixed(1)} km)', style: AppTextStyles.bodyLarge),
                    Text('€${pickupFee.toStringAsFixed(2)}', style: AppTextStyles.titleMedium),
                  ],
                ),
              ],
              if (dropoffFee > 0) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Dropoff Fee (${dropoffDistance.toStringAsFixed(1)} km)', style: AppTextStyles.bodyLarge),
                    Text('€${dropoffFee.toStringAsFixed(2)}', style: AppTextStyles.titleMedium),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(packageName, style: AppTextStyles.bodyLarge),
                  Text('€${packagePrice.toStringAsFixed(2)}', style: AppTextStyles.titleMedium),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Amount', style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold)),
                  Text('€${totalPrice.toStringAsFixed(2)}', style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryGold)),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
          ),
        ),
      ),
    );
  }
}
