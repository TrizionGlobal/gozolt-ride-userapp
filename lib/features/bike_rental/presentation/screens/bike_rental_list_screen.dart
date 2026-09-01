import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/gozolt_button.dart';
import '../../../../core/widgets/app_filled_text_field.dart';

import '../widgets/bike_rental_header.dart';
import '../../domain/models/bike_model.dart';
import '../../data/datasources/bike_rental_remote_datasource.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/providers/dio_provider.dart';
import '../providers/bike_rental_search_provider.dart';

class FilterState {
  String sortBy;
  Set<String> bikeTypes;
  double? minPrice;
  double? maxPrice;
  Set<String> transmissions;
  Set<String> fuelTypes;
  Set<String> seats;
  Set<String> supplierOptions;
  Set<String> features;

  FilterState({
    this.sortBy = 'Recommended',
    Set<String>? bikeTypes,
    this.minPrice,
    this.maxPrice,
    Set<String>? transmissions,
    Set<String>? fuelTypes,
    Set<String>? seats,
    Set<String>? supplierOptions,
    Set<String>? features,
  })  : bikeTypes = bikeTypes ?? {},
        transmissions = transmissions ?? {},
        fuelTypes = fuelTypes ?? {},
        seats = seats ?? {},
        supplierOptions = supplierOptions ?? {},
        features = features ?? {};
        
  FilterState clone() {
    return FilterState(
      sortBy: sortBy,
      bikeTypes: Set.from(bikeTypes),
      minPrice: minPrice,
      maxPrice: maxPrice,
      transmissions: Set.from(transmissions),
      fuelTypes: Set.from(fuelTypes),
      seats: Set.from(seats),
      supplierOptions: Set.from(supplierOptions),
      features: Set.from(features),
    );
  }
}

class BikeRentalListScreen extends ConsumerStatefulWidget {
  const BikeRentalListScreen({super.key});

  @override
  ConsumerState<BikeRentalListScreen> createState() => _BikeRentalListScreenState();
}

class _BikeRentalListScreenState extends ConsumerState<BikeRentalListScreen> {
  int _selectedCategoryIndex = 0;
  int? _selectedBikeIndex;
  FilterState _filterState = FilterState();
  
  final List<String> _categories = ['All', 'Commuter Bike', 'Sports Bike', 'Cruiser Bike', 'Adventure Bike', 'Premium Bike', 'Electric Bike', 'Standard Scooter', 'Electric Scooter', 'Premium Scooter'];
  
  List<BikeModel> _allBikes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBikes();
  }

  Future<void> _fetchBikes() async {
    try {
      final dio = ref.read(dioProvider);
      final datasource = BikeRentalRemoteDatasource(dio);
      final bikes = await datasource.getAvailableBikes();
      if (mounted) {
        setState(() {
          _allBikes = bikes;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching bikes: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _allBikes = [];
        });
      }
    }
  }
  
  List<BikeModel> get _filteredBikes {
    var bikes = _allBikes.where((bike) {
      // Apply category tab filter
      final selectedCategory = _categories[_selectedCategoryIndex];
      if (selectedCategory != 'All' && bike.type != selectedCategory) return false;

      // Apply delivery type filter
      final searchState = ref.watch(bikeRentalSearchProvider);
      if (searchState.deliveryType == 'SELF_PICKUP' && !bike.isSelfPickupAllowed) return false;
      if (searchState.deliveryType == 'SUPPLIER_DELIVERY' && !bike.isSupplierDeliveryAllowed) return false;
      if (searchState.deliveryType == 'DOORSTEP_DELIVERY' && !bike.isDoorstepDeliveryAllowed) return false;

      // Apply modal filters
      if (_filterState.bikeTypes.isNotEmpty && !_filterState.bikeTypes.contains(bike.type)) return false;
      if (_filterState.minPrice != null && bike.pricePerDay < _filterState.minPrice!) return false;
      if (_filterState.maxPrice != null && bike.pricePerDay > _filterState.maxPrice!) return false;
      if (_filterState.transmissions.isNotEmpty && !_filterState.transmissions.contains(bike.transmission)) return false;
      if (_filterState.fuelTypes.isNotEmpty && !_filterState.fuelTypes.contains(bike.fuelType)) return false;
      
      if (_filterState.seats.isNotEmpty) {
        bool match = false;
        if (_filterState.seats.contains('1 Seat') && bike.seats == 1) match = true;
        if (_filterState.seats.contains('2 Seats') && bike.seats == 2) match = true;
        if (!match) return false;
      }
      
      if (_filterState.supplierOptions.isNotEmpty && !_filterState.supplierOptions.contains(bike.supplierOption)) return false;
      
      if (_filterState.features.isNotEmpty) {
        if (!_filterState.features.every((f) => bike.features.contains(f))) return false;
      }

      return true;
    }).toList();
    
    if (_filterState.sortBy == 'Lowest Price') {
      bikes.sort((a, b) => a.pricePerDay.compareTo(b.pricePerDay));
    } else if (_filterState.sortBy == 'Highest Price') {
      bikes.sort((a, b) => b.pricePerDay.compareTo(a.pricePerDay));
    } else if (_filterState.sortBy == 'Highest Rated') {
      bikes.sort((a, b) => b.rating.compareTo(a.rating));
    }
    
    return bikes;
  }

  int _calculateDays() {
    final searchState = ref.read(bikeRentalSearchProvider);
    if (searchState.pickupDate != null && searchState.dropoffDate != null) {
      final hours = searchState.dropoffDate!.difference(searchState.pickupDate!).inHours;
      if (hours <= 0) return 1;
      int days = (hours / 24).ceil();
      return days < 1 ? 1 : days;
    }
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final int durationDays = _calculateDays();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          BikeRentalHeader(
            title: 'Available Bikes',
            trailing: IconButton(
              icon: const Icon(Icons.filter_list, color: AppColors.backgroundDark),
              onPressed: _showFilterModal,
            ),
          ),
          _buildCategoryTabs(isDark),
          Expanded(
            child: _isLoading
                ? _buildSkeletonList(isDark)
                : _filteredBikes.isEmpty 
                  ? Center(child: Text("No bikes match your filters.", style: AppTextStyles.titleMedium))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      itemCount: _filteredBikes.length,
                      itemBuilder: (context, index) {
                        return _buildBikeCard(isDark, index, _filteredBikes[index], durationDays);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(bool isDark) {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedCategoryIndex == index;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(_categories[index]),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedCategoryIndex = index);
                }
              },
              selectedColor: AppColors.primaryGold,
              backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              labelStyle: AppTextStyles.bodyMedium.copyWith(
                color: isSelected 
                    ? Colors.white 
                    : (isDark ? AppColors.textPrimary : AppColors.textPrimaryLight),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.primaryGold : (isDark ? AppColors.borderDark : Colors.grey.shade300),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkeletonList(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: 4, // Show 4 skeletons
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.borderDark : Colors.grey.shade200,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Shimmer.fromColors(
                baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
                child: Container(
                  height: 180,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Shimmer.fromColors(
                      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
                      child: Container(
                        width: 150,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Shimmer.fromColors(
                      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
                      child: Container(
                        width: double.infinity,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Shimmer.fromColors(
                      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
                      child: Container(
                        width: 100,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBikeCard(bool isDark, int index, BikeModel bike, int durationDays) {
    final isSelected = _selectedBikeIndex == index;
    
    return GestureDetector(
      onTap: () {
        context.pushNamed(RouteNames.bikeRentalDetails, extra: bike);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryGold : (isDark ? AppColors.borderDark : Colors.grey.shade200),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            if (!isDark || isSelected)
              BoxShadow(
                color: isSelected ? AppColors.primaryGold.withOpacity(0.2) : Colors.black.withOpacity(0.04),
                blurRadius: isSelected ? 12 : 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: SizedBox(
                height: 160,
                width: double.infinity,
                child: bike.imageUrl.isNotEmpty
                  ? Image.network(
                      bike.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: isDark ? Colors.black12 : Colors.grey.shade100,
                          child: Center(
                            child: Icon(Icons.motorcycle, size: 80, color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: isDark ? Colors.black12 : Colors.grey.shade100,
                      child: Center(
                        child: Icon(Icons.motorcycle, size: 80, color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight),
                      ),
                    ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(bike.name, style: AppTextStyles.titleMedium),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryGold.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('or similar', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primaryGold, fontSize: 10)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.business, size: 14, color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight),
                                const SizedBox(width: 4),
                                Text(bike.supplier, style: AppTextStyles.bodySmall.copyWith(color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight)),
                                const SizedBox(width: 8),
                                const Icon(Icons.star, size: 14, color: Colors.orange),
                                const SizedBox(width: 2),
                                Text('${bike.rating}', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      _buildSpec(isDark, Icons.settings, bike.transmission),
                      _buildSpec(isDark, Icons.local_gas_station, bike.fuelType),
                      _buildSpec(isDark, Icons.event_seat, '${bike.seats} Seats'),
                    ],
                  ),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(height: 1),
                  ),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bike.deliveryCharge > 0 
                                ? '${bike.supplierOption} (+€${bike.deliveryCharge.toStringAsFixed(1)}/km)' 
                                : bike.supplierOption, 
                            style: AppTextStyles.labelSmall.copyWith(color: AppColors.success)
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('€${bike.pricePerDay.toInt()}', style: AppTextStyles.titleLarge.copyWith(color: AppColors.primaryGold)),
                              Text(' / day', style: AppTextStyles.bodySmall.copyWith(color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight)),
                            ],
                          ),
                          Text('Total: €${(bike.pricePerDay * durationDays).toInt()} for $durationDays ${durationDays == 1 ? 'day' : 'days'}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11)),
                        ],
                      ),
                      OutlinedButton(
                        onPressed: () {
                          context.pushNamed(RouteNames.bikeRentalDetails, extra: bike);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primaryGold),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'View Details', 
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryGold, fontWeight: FontWeight.w600)
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpec(bool isDark, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.labelSmall.copyWith(color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight, fontSize: 11)),
      ],
    );
  }

  Future<void> _showFilterModal() async {
    final newFilterState = await showModalBottomSheet<FilterState>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return _FilterModalContent(initialState: _filterState);
      },
    );
    if (newFilterState != null) {
      setState(() {
        _filterState = newFilterState;
      });
    }
  }
}

class _FilterModalContent extends StatefulWidget {
  final FilterState initialState;
  const _FilterModalContent({required this.initialState});

  @override
  State<_FilterModalContent> createState() => _FilterModalContentState();
}

class _FilterModalContentState extends State<_FilterModalContent> {
  late FilterState _state;
  final List<String> _sortOptions = ['Recommended', 'Lowest Price', 'Highest Price', 'Highest Rated'];

  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _state = widget.initialState.clone();
    if (_state.minPrice != null) _minPriceController.text = _state.minPrice.toString();
    if (_state.maxPrice != null) _maxPriceController.text = _state.maxPrice.toString();
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  Widget _buildFilterHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryGold, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildCheckbox(String title, Set<String> targetSet) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: targetSet.contains(title),
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  targetSet.add(title);
                } else {
                  targetSet.remove(title);
                }
              });
            },
            activeColor: AppColors.primaryGold,
          ),
        ),
        const SizedBox(width: 8),
        Text(title, style: AppTextStyles.bodyMedium),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filters & Sorting', style: AppTextStyles.titleLarge),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 40),
              children: [
                _buildFilterHeader('Sort By'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? AppColors.borderDark : Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _state.sortBy,
                      isExpanded: true,
                      dropdownColor: Theme.of(context).cardTheme.color,
                      items: _sortOptions.map((s) {
                        return DropdownMenuItem(value: s, child: Text(s));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _state.sortBy = val);
                        }
                      },
                    ),
                  ),
                ),

                _buildFilterHeader('Bike Type'),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    _buildCheckbox('Commuter Bike', _state.bikeTypes),
                    _buildCheckbox('Sports Bike', _state.bikeTypes),
                    _buildCheckbox('Cruiser Bike', _state.bikeTypes),
                    _buildCheckbox('Adventure Bike', _state.bikeTypes),
                    _buildCheckbox('Premium Bike', _state.bikeTypes),
                    _buildCheckbox('Electric Bike', _state.bikeTypes),
                    _buildCheckbox('Standard Scooter', _state.bikeTypes),
                    _buildCheckbox('Electric Scooter', _state.bikeTypes),
                    _buildCheckbox('Premium Scooter', _state.bikeTypes),
                  ],
                ),
                
                _buildFilterHeader('Price Range'),
                Row(
                  children: [
                    Expanded(
                      child: AppFilledTextField(
                        controller: _minPriceController,
                        hint: 'Min €',
                        icon: Icons.euro,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppFilledTextField(
                        controller: _maxPriceController,
                        hint: 'Max €',
                        icon: Icons.euro,
                      ),
                    ),
                  ],
                ),
                
                _buildFilterHeader('Transmission'),
                Row(
                  children: [
                    _buildCheckbox('Automatic', _state.transmissions),
                    const SizedBox(width: 24),
                    _buildCheckbox('Manual', _state.transmissions),
                  ],
                ),
                
                _buildFilterHeader('Fuel Type'),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    _buildCheckbox('Petrol', _state.fuelTypes),
                    _buildCheckbox('Electric', _state.fuelTypes),
                  ],
                ),
                
                _buildFilterHeader('Seats'),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    _buildCheckbox('1 Seat', _state.seats),
                    _buildCheckbox('2 Seats', _state.seats),
                  ],
                ),

              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
              child: SizedBox(
                height: 44,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: isDark ? AppColors.borderDark : Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        final clearedState = FilterState(sortBy: 'Recommended');
                        Navigator.pop(context, clearedState);
                      },
                      child: Text(
                        'Clear Filters',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GozoltButton(
                      label: 'Apply Filters',
                      onPressed: () {
                        _state.minPrice = double.tryParse(_minPriceController.text);
                        _state.maxPrice = double.tryParse(_maxPriceController.text);
                        Navigator.pop(context, _state);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ],
      ),
    );
  }
}
