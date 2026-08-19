import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/gozolt_button.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/gozolt_button.dart';
import '../widgets/car_rental_header.dart';
import '../../domain/models/car_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/car_rental_search_provider.dart';

class CarRentalAddonsScreen extends ConsumerStatefulWidget {
  final CarModel? car;
  const CarRentalAddonsScreen({super.key, this.car});

  @override
  ConsumerState<CarRentalAddonsScreen> createState() => _CarRentalAddonsScreenState();
}

class _CarRentalAddonsScreenState extends ConsumerState<CarRentalAddonsScreen> {
  final Map<String, int> _addonQuantities = {};

  // Additional Driver Details
  final TextEditingController _driverNameController = TextEditingController();
  String? _dlFileName;
  String? _idFileName;

  @override
  void initState() {
    super.initState();
    if (widget.car?.addons != null) {
      for (final addon in widget.car!.addons) {
        _addonQuantities[addon.id] = (widget.car?.selectedAddonIds?.contains(addon.id) ?? false) ? 1 : 0;
      }
    }
  }

  @override
  void dispose() {
    _driverNameController.dispose();
    super.dispose();
  }

  IconData _getIconForIdentifier(String identifier) {
    switch (identifier) {
      case 'navigation': return Icons.navigation;
      case 'child_care': return Icons.child_care;
      case 'baby_changing_station': return Icons.baby_changing_station;
      case 'event_seat': return Icons.event_seat;
      case 'phone_android': return Icons.phone_android;
      case 'wifi': return Icons.wifi;
      case 'group_add': return Icons.group_add;
      case 'ac_unit': return Icons.ac_unit;
      case 'downhill_skiing': return Icons.downhill_skiing;
      default: return Icons.add_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Calculate total price
    double basePrice = (widget.car?.pricePerDay ?? 0.0) * 3; // Base price mock calculation
    final searchState = ref.watch(carRentalSearchProvider);
    final isFlexible = searchState.isFlexible;
    final double flexiblePrice = isFlexible ? (15.0 * 3) : 0.0;
    
    double packagePrice = 0.0;
    String packageName = 'Protection Package';

    if (widget.car?.selectedProtectionPackageId != null) {
      try {
        final pkg = widget.car!.protectionPackages.firstWhere((p) => p.valueIdentifier == widget.car!.selectedProtectionPackageId);
        packagePrice = (pkg.pricePerDay * 3);
        packageName = pkg.title;
      } catch (_) {}
    }

    double addonsPrice = 0.0;
    
    if (widget.car?.addons != null) {
      for (final addon in widget.car!.addons) {
        final qty = _addonQuantities[addon.id] ?? 0;
        if (qty > 0) {
          addonsPrice += (addon.pricePerDay * 3 * qty); 
        }
      }
    }
    double totalPrice = basePrice + flexiblePrice + packagePrice + addonsPrice;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const CarRentalHeader(title: 'Which add-ons do you need?'),
          Expanded(
            child: widget.car?.addons.isEmpty ?? true
                ? const Center(child: Text('No add-ons available for this vehicle.'))
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: widget.car!.addons.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final addon = widget.car!.addons[index];
                      final qty = _addonQuantities[addon.id] ?? 0;
                      final isSelected = qty > 0;
                      final price = addon.pricePerDay;
                      final icon = _getIconForIdentifier(addon.iconIdentifier);

                      return Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _addonQuantities[addon.id] = (qty == 0) ? 1 : 0;
                              });
                            },
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
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isSelected 
                                          ? AppColors.primaryGold.withOpacity(0.1) 
                                          : (isDark ? AppColors.inputDark : Colors.grey.shade100),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(icon, color: isSelected ? AppColors.primaryGold : (isDark ? Colors.white70 : Colors.black54)),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(addon.name, style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text('+€${price.toStringAsFixed(2)} / day', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected ? AppColors.primaryGold : Colors.transparent,
                                      border: Border.all(
                                        color: isSelected ? AppColors.primaryGold : Colors.grey,
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected 
                                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (addon.name.toLowerCase().contains('additional driver') && isSelected)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: _buildAdditionalDriverForm(isDark),
                            ),
                        ],
                      );
              },
            ),
          ),
          

          const SizedBox(height: 80),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _showPriceDetailsBottomSheet(context, basePrice, flexiblePrice, packagePrice, packageName, addonsPrice, totalPrice),
                  child: Row(
                    children: [
                      Text('€${totalPrice.toStringAsFixed(2)}', style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      Text('total', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
                      const Icon(Icons.keyboard_arrow_up, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              GozoltButton(
                label: 'Continue',
                width: 140,
                onPressed: () {
                  final selectedIds = _addonQuantities.entries
                      .where((entry) => entry.value > 0)
                      .map((entry) => entry.key)
                      .toList();
                  final updatedCar = widget.car?.copyWith(
                    selectedAddonIds: selectedIds,
                  );
                  context.pushNamed(RouteNames.carRentalReview, extra: updatedCar);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdditionalDriverForm(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryGold.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Additional Driver Details', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _driverNameController,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Full Name',
              hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.black38),
              filled: true,
              fillColor: isDark ? AppColors.inputDark : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8), 
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GozoltButton(
                  label: _dlFileName ?? 'Upload DL',
                  isOutlined: true,
                  onPressed: () {
                    setState(() {
                      _dlFileName = 'driver_license.pdf';
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GozoltButton(
                  label: _idFileName ?? 'Upload ID',
                  isOutlined: true,
                  onPressed: () {
                    setState(() {
                      _idFileName = 'national_id.pdf';
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPriceDetailsBottomSheet(BuildContext context, double basePrice, double flexiblePrice, double packagePrice, String packageName, double addonsPrice, double totalPrice) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Calculate individual addons
    final Map<String, double> selectedAddonPrices = {};
    if (widget.car?.addons != null) {
      for (final addon in widget.car!.addons) {
        final qty = _addonQuantities[addon.id] ?? 0;
        if (qty > 0) {
          selectedAddonPrices[addon.name] = addon.pricePerDay * 3 * qty;
        }
      }
    }
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Price Breakdown', style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Rental (3 Days)', style: AppTextStyles.bodyLarge),
                  Text('€${basePrice.toStringAsFixed(2)}', style: AppTextStyles.titleMedium),
                ],
              ),
              if (flexiblePrice > 0) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Stay Flexible (3 Days)', style: AppTextStyles.bodyLarge),
                    Text('€${flexiblePrice.toStringAsFixed(2)}', style: AppTextStyles.titleMedium),
                  ],
                ),
              ],
              if (packagePrice > 0) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(packageName, style: AppTextStyles.bodyLarge),
                    Text('€${packagePrice.toStringAsFixed(2)}', style: AppTextStyles.titleMedium),
                  ],
                ),
              ],
              if (selectedAddonPrices.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(),
                ),
                ...selectedAddonPrices.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key, style: AppTextStyles.bodyLarge),
                      Text('€${entry.value.toStringAsFixed(2)}', style: AppTextStyles.titleMedium),
                    ],
                  ),
                )),
              ],
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
    );
  }
}
