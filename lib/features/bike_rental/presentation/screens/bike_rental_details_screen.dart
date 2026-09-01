import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/bike_rental_search_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/gozolt_button.dart';
import '../../../../core/utils/geo_utils.dart';
import '../../domain/models/bike_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class BikeRentalDetailsScreen extends ConsumerStatefulWidget {
  final BikeModel? bike;
  const BikeRentalDetailsScreen({super.key, this.bike});

  @override
  ConsumerState<BikeRentalDetailsScreen> createState() => _BikeRentalDetailsScreenState();
}

class _BikeRentalDetailsScreenState extends ConsumerState<BikeRentalDetailsScreen> {
  String? _paymentOption = 'best_price';
  String? _selectedMileagePackage = 'unlimited';
  
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  
  double get _basePrice => widget.bike?.pricePerDay ?? 45.0;
  
  int get _daysInt {
    final searchState = ref.read(bikeRentalSearchProvider);
    if (searchState.pickupDate != null && searchState.dropoffDate != null) {
      final hours = searchState.dropoffDate!.difference(searchState.pickupDate!).inHours;
      if (hours <= 0) return 1;
      int days = (hours / 24).ceil();
      return days < 1 ? 1 : days;
    }
    return 1;
  }
  
  double get _days => _daysInt.toDouble();

  double get _pickupDistance {
    final searchState = ref.read(bikeRentalSearchProvider);
    final supLat = widget.bike?.supplierLatitude;
    final supLng = widget.bike?.supplierLongitude;
    if (supLat != null && supLng != null && searchState.pickupLat != null && searchState.pickupLng != null) {
      if (searchState.deliveryType == 'SELF_PICKUP') return 0.0;
      return haversineDistanceKm(supLat, supLng, searchState.pickupLat!, searchState.pickupLng!);
    }
    return 0.0;
  }

  double get _dropoffDistance {
    final searchState = ref.read(bikeRentalSearchProvider);
    final supLat = widget.bike?.supplierLatitude;
    final supLng = widget.bike?.supplierLongitude;
    if (supLat != null && supLng != null && searchState.dropoffLat != null && searchState.dropoffLng != null) {
      if (searchState.deliveryType == 'SELF_PICKUP' && 
          searchState.dropoffLat == searchState.pickupLat && 
          searchState.dropoffLng == searchState.pickupLng) {
        return 0.0;
      }
      return haversineDistanceKm(supLat, supLng, searchState.dropoffLat!, searchState.dropoffLng!);
    }
    return 0.0;
  }

  double get _totalPrice {
    double total = _basePrice * _days;
    if (_paymentOption == 'stay_flexible') {
      total += (15.0 * _days); // Stay flexible cost
    }
    if (_selectedMileagePackage == 'premium') {
      total += (10.0 * _days); // Premium mileage cost
    }
    
    // Fallback to 1.5 per km if the backend still sends 0 (e.g. backend not restarted or DB value is 0)
    final charge = (widget.bike?.deliveryCharge != null && widget.bike!.deliveryCharge > 0) 
        ? widget.bike!.deliveryCharge 
        : 1.5;
        
    final pickupFee = _pickupDistance * charge;
    final dropoffFee = _dropoffDistance * charge;
    
    total += pickupFee;
    total += dropoffFee;

    return total;
  }

  void _showSupplierInfoModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final lat = widget.bike?.supplierLatitude;
    final lng = widget.bike?.supplierLongitude;
    final supplierName = widget.bike?.supplier ?? 'Supplier';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.business, size: 36, color: AppColors.primaryGold),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('SUPPLIER',
                              style: AppTextStyles.titleSmall.copyWith(
                                color: isDark ? Colors.white54 : Colors.black54,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(supplierName,
                              style: AppTextStyles.headlineSmall.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.star, color: AppColors.primaryGold, size: 20),
                                const SizedBox(width: 4),
                                Text(
                                  widget.bike?.rating.toStringAsFixed(1) ?? '4.8',
                                  style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 8),
                                Text('•', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
                                const SizedBox(width: 8),
                                Icon(Icons.verified, color: AppColors.primaryGold, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  'Trusted Partner',
                                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryGold, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  if (lat != null && lng != null)
                    GozoltButton(
                      label: 'View on Google Maps',
                      icon: Icons.map,
                      width: double.infinity,
                      onPressed: () async {
                        final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
                        final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
                        if (!launched) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Could not open maps. Please ensure a map app is installed.')),
                            );
                          }
                        }
                      },
                    )
                  else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'Location details are not available.',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
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
                  Positioned.fill(
                    child: widget.bike != null && widget.bike!.images.isNotEmpty
                      ? PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() {
                              _currentImageIndex = index;
                            });
                          },
                          itemCount: widget.bike!.images.length,
                          itemBuilder: (context, index) {
                            return Image.network(
                              widget.bike!.images[index],
                              fit: BoxFit.cover,
                            );
                          },
                        )
                      : Image.network(
                          'https://images.unsplash.com/photo-1590362891991-f776e747a588?auto=format&fit=crop&q=80&w=800',
                          fit: BoxFit.cover,
                        ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
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
                  ),
                  if (widget.bike != null && widget.bike!.images.length > 1)
                    Positioned(
                      bottom: 40,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          widget.bike!.images.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentImageIndex == index ? 12 : 8,
                            height: _currentImageIndex == index ? 12 : 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentImageIndex == index ? AppColors.primaryGold : Colors.white54,
                            ),
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
                Text(widget.bike?.name.toUpperCase() ?? 'ROYAL ENFIELD CLASSIC 350', style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('or similar | ${widget.bike?.type.split(' - ').first ?? 'Cruiser'}', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
                    GestureDetector(
                      onTap: () => _showSupplierInfoModal(context),
                      child: Row(
                        children: [
                          const Icon(Icons.business, size: 16, color: AppColors.primaryGold),
                          const SizedBox(width: 4),
                          Text('Supplier Info', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryGold, decoration: TextDecoration.underline, decorationColor: AppColors.primaryGold)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Specs Grid (2 columns)
                _buildDetailedSpecs(isDark),
                
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
            BoxShadow(color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4)),
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
                    final charge = (widget.bike?.deliveryCharge != null && widget.bike!.deliveryCharge > 0) 
                        ? widget.bike!.deliveryCharge 
                        : 1.5;
                    final pickupFee = _pickupDistance * charge;
                    final dropoffFee = _dropoffDistance * charge;
                    _showPriceDetailsBottomSheet(
                      context, 
                      basePrice, 
                      flexiblePrice, 
                      pickupFee, 
                      _pickupDistance, 
                      dropoffFee, 
                      _dropoffDistance, 
                      _totalPrice
                    );
                  },
                  child: Row(
                    children: [
                      Text('€${_totalPrice.toStringAsFixed(2)}', style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold)),
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
                  ref.read(bikeRentalSearchProvider.notifier).updateSearch(
                    isFlexible: _paymentOption == 'stay_flexible',
                  );
                  context.pushNamed(RouteNames.bikeRentalPackages, extra: widget.bike);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecItem(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 20, color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight.withOpacity(0.7)),
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
                      Icon(Icons.info_outline, size: 20, color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight),
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

  void _showPriceDetailsBottomSheet(
    BuildContext context, 
    double basePrice, 
    double flexiblePrice, 
    double pickupFee, 
    double pickupDistance, 
    double dropoffFee, 
    double dropoffDistance, 
    double totalPrice
  ) {
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


  Widget _buildDetailedSpecs(bool isDark) {
    final b = widget.bike;
    if (b == null) return const SizedBox();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Basic Information', style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? AppColors.borderDark : Colors.grey.shade200),
          ),
          child: Column(
            children: [
              _buildSpecRow('Brand', b.brand, isDark),
              _buildSpecRow('Model', b.model, isDark),
              _buildSpecRow('Year', b.manufacturingYear.toString(), isDark),
              _buildSpecRow('Category', b.type, isDark),
              _buildSpecRow('Registration', b.registrationNumber, isDark),
              if (b.engineCapacityCc != null) _buildSpecRow('Engine (CC)', '${b.engineCapacityCc}cc', isDark),
              _buildSpecRow('Fuel Type', b.fuelType, isDark),
              _buildSpecRow('Transmission', b.transmission, isDark),
              if (b.mileage != null) _buildSpecRow('Mileage', '${b.mileage} km/l', isDark),
              _buildSpecRow('Seats', b.seats.toString(), isDark),
              _buildSpecRow('Color', b.color, isDark, isLast: true),
            ],
          ),
        ),
        
        if (b.fuelType.toLowerCase() == 'electric') ...[
          const SizedBox(height: 32),
          Text('Electric Specifications', style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryGold.withOpacity(0.5)),
            ),
            child: Column(
              children: [
                _buildSpecRow('Battery Capacity', b.batteryCapacity ?? 'N/A', isDark),
                _buildSpecRow('Estimated Range', b.estimatedRange ?? 'N/A', isDark),
                _buildSpecRow('Charging Type', b.chargingType ?? 'N/A', isDark),
                _buildSpecRow('Charging Time', b.chargingTime ?? 'N/A', isDark, isLast: true),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSpecRow(String label, String value, bool isDark, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
          Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}