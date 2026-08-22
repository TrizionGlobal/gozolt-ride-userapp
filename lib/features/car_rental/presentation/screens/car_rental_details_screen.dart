import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/car_rental_search_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/gozolt_button.dart';
import '../../domain/models/car_model.dart';

class CarRentalDetailsScreen extends ConsumerStatefulWidget {
  final CarModel? car;
  const CarRentalDetailsScreen({super.key, this.car});

  @override
  ConsumerState<CarRentalDetailsScreen> createState() => _CarRentalDetailsScreenState();
}

class _CarRentalDetailsScreenState extends ConsumerState<CarRentalDetailsScreen> {
  String? _paymentOption = 'best_price';
  String? _selectedMileagePackage = 'unlimited';
  
  double get _basePrice => widget.car?.pricePerDay ?? 45.0;
  
  int get _daysInt {
    final searchState = ref.read(carRentalSearchProvider);
    if (searchState.pickupDate != null && searchState.dropoffDate != null) {
      final hours = searchState.dropoffDate!.difference(searchState.pickupDate!).inHours;
      if (hours <= 0) return 1;
      int days = (hours / 24).ceil();
      return days < 1 ? 1 : days;
    }
    return 1;
  }
  
  double get _days => _daysInt.toDouble();
  
  double get _totalPrice {
    double total = _basePrice * _days;
    if (_paymentOption == 'stay_flexible') {
      total += (15.0 * _days); // Stay flexible cost
    }
    if (_selectedMileagePackage == 'premium') {
      total += (10.0 * _days); // Premium mileage cost
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // Hero Image Header
          SliverToBoxAdapter(
            child: Container(
              height: 350,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black54, Colors.black87],
                ),
              ),
              child: Stack(
                children: [
                  // Actual car image
                  Positioned.fill(
                    child: widget.car != null ? Image.network(
                      widget.car!.imageUrl,
                      fit: BoxFit.cover,
                    ) : Image.network(
                      'https://images.unsplash.com/photo-1590362891991-f776e747a588?auto=format&fit=crop&q=80&w=800',
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black54, Colors.transparent, Colors.black87],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: Row(
                      children: [
                        const Icon(Icons.check, color: Colors.greenAccent, size: 20),
                        const SizedBox(width: 8),
                        Text('Unlimited kilometers', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Title Block
                Text(widget.car?.name.toUpperCase() ?? 'TOYOTA COROLLA', style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('or similar | ${widget.car?.type.split(' - ').first ?? 'Saloon'}', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
                    Row(
                      children: [
                        const Icon(Icons.business, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(widget.car?.supplier ?? 'Supplier', style: AppTextStyles.bodySmall.copyWith(color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Specs Grid (2 columns)
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildSpecItem(Icons.person, '${widget.car?.seats ?? 5} people')),
                        const SizedBox(width: 16),
                        Expanded(child: _buildSpecItem(Icons.luggage, '${widget.car?.luggageCapacity ?? 2} bags')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildSpecItem(Icons.settings, widget.car?.transmission ?? 'Automatic')),
                        const SizedBox(width: 16),
                        Expanded(child: _buildSpecItem(Icons.local_gas_station, widget.car?.fuelType ?? 'Petrol')),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Payment Option Section
                Text('Payment option', style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildPaymentOptionCard(
                  title: 'Best price',
                  description: 'Free cancellation and rebooking within 24h.',
                  priceInfo: 'Included',
                  value: 'best_price',
                  groupValue: _paymentOption,
                  onChanged: (val) => setState(() => _paymentOption = val),
                  isDark: isDark,
                  isPopular: false,
                ),
                const SizedBox(height: 12),
                _buildPaymentOptionCard(
                  title: 'Stay flexible',
                  description: 'Free cancellation and rebooking any time before pickup time.',
                  priceInfo: '+ €15.00 / day',
                  value: 'stay_flexible',
                  groupValue: _paymentOption,
                  onChanged: (val) => setState(() => _paymentOption = val),
                  isDark: isDark,
                  isPopular: true,
                ),
                const SizedBox(height: 32),
                
                // Mileage Package Section
                Text('Mileage package', style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryGold, width: 2.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Unlimited kilometers', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('All kilometers are included in the price', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
                      const SizedBox(height: 8),
                      Text('Included', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                
                const SizedBox(height: 100),
              ]),
            ),
          ),
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
                  onTap: () {
                    final basePrice = _basePrice * _days;
                    final flexiblePrice = _paymentOption == 'stay_flexible' ? 15.0 * _days : 0.0;
                    _showPriceDetailsBottomSheet(context, basePrice, flexiblePrice, _totalPrice);
                  },
                  child: Row(
                    children: [
                      Text('€${_totalPrice.toStringAsFixed(2)}', style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      Text('total', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
                      const Icon(Icons.keyboard_arrow_up, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              GozoltButton(
                label: 'Continue',
                width: 160,
                icon: Icons.arrow_forward,
                onPressed: () {
                  ref.read(carRentalSearchProvider.notifier).updateSearch(
                    isFlexible: _paymentOption == 'stay_flexible',
                  );
                  context.pushNamed(RouteNames.carRentalPackages, extra: widget.car);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade700),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: AppTextStyles.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _buildPaymentOptionCard({
    required String title,
    required String description,
    required String priceInfo,
    required String value,
    required String? groupValue,
    required ValueChanged<String?> onChanged,
    required bool isDark,
    required bool isPopular,
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
                      Text(title, style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                      if (isPopular) ...[
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('Popular', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                      const SizedBox(width: 8),
                      const Icon(Icons.info_outline, size: 20, color: Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(description, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted, height: 1.4)),
                  const SizedBox(height: 8),
                  Text(priceInfo, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccordionItem(String title, String content) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(content, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard({
    required String title,
    required String price,
    required String description,
    required String value,
    required String? groupValue,
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title, style: AppTextStyles.titleMedium),
                      Text(price, style: AppTextStyles.bodyMedium.copyWith(color: isSelected ? AppColors.primaryGold : AppColors.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(description, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted, height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPriceDetailsBottomSheet(BuildContext context, double basePrice, double flexiblePrice, double totalPrice) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
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
                  Text('Rental ($_daysInt ${_daysInt == 1 ? 'Day' : 'Days'})', style: AppTextStyles.bodyLarge),
                  Text('€${basePrice.toStringAsFixed(2)}', style: AppTextStyles.titleMedium),
                ],
              ),
              if (flexiblePrice > 0) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Stay Flexible ($_daysInt ${_daysInt == 1 ? 'Day' : 'Days'})', style: AppTextStyles.bodyLarge),
                    Text('€${flexiblePrice.toStringAsFixed(2)}', style: AppTextStyles.titleMedium),
                  ],
                ),
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
      ),
    );
  }
}
