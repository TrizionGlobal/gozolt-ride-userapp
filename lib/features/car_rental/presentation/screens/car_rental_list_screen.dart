import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/gozolt_button.dart';
import '../../../../core/widgets/app_filled_text_field.dart';

import '../widgets/car_rental_header.dart';
import '../../domain/models/car_model.dart';
import '../../data/datasources/car_rental_remote_datasource.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/providers/dio_provider.dart';
import '../providers/car_rental_search_provider.dart';

class FilterState {
  String sortBy;
  Set<String> vehicleTypes;
  double? minPrice;
  double? maxPrice;
  Set<String> transmissions;
  Set<String> fuelTypes;
  Set<String> seats;
  Set<String> supplierOptions;
  Set<String> features;
  Set<String> acOptions;

  FilterState({
    this.sortBy = 'Recommended',
    Set<String>? vehicleTypes,
    this.minPrice,
    this.maxPrice,
    Set<String>? transmissions,
    Set<String>? fuelTypes,
    Set<String>? seats,
    Set<String>? supplierOptions,
    Set<String>? features,
    Set<String>? acOptions,
  })  : vehicleTypes = vehicleTypes ?? {},
        transmissions = transmissions ?? {},
        fuelTypes = fuelTypes ?? {},
        seats = seats ?? {},
        supplierOptions = supplierOptions ?? {},
        features = features ?? {},
        acOptions = acOptions ?? {};
        
  FilterState clone() {
    return FilterState(
      sortBy: sortBy,
      vehicleTypes: Set.from(vehicleTypes),
      minPrice: minPrice,
      maxPrice: maxPrice,
      transmissions: Set.from(transmissions),
      fuelTypes: Set.from(fuelTypes),
      seats: Set.from(seats),
      supplierOptions: Set.from(supplierOptions),
      features: Set.from(features),
      acOptions: Set.from(acOptions),
    );
  }
}

class CarRentalListScreen extends ConsumerStatefulWidget {
  const CarRentalListScreen({super.key});

  @override
  ConsumerState<CarRentalListScreen> createState() => _CarRentalListScreenState();
}

class _CarRentalListScreenState extends ConsumerState<CarRentalListScreen> {
  int _selectedCategoryIndex = 0;
  int? _selectedVehicleIndex;
  FilterState _filterState = FilterState();
  
  final List<String> _categories = ['All', 'Go - 5P', 'Premium - 5P', 'SUV - 7P', 'Van - 8P & Above', 'Electric - 5P'];
  
  List<CarModel> _allCars = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCars();
  }

  Future<void> _fetchCars() async {
    try {
      final dio = ref.read(dioProvider);
      final datasource = CarRentalRemoteDatasource(dio);
      final cars = await datasource.getAvailableVehicles();
      if (mounted) {
        setState(() {
          _allCars = cars;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching cars: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _allCars = mockCars; // fallback to mock
        });
      }
    }
  }
  
  List<CarModel> get _filteredCars {
    var cars = _allCars.where((car) {
      // Apply category tab filter
      final selectedCategory = _categories[_selectedCategoryIndex];
      if (selectedCategory != 'All' && car.type != selectedCategory) return false;

      // Apply delivery type filter
      final searchState = ref.watch(carRentalSearchProvider);
      if (searchState.deliveryType == 'SELF_PICKUP' && !car.isSelfPickupAllowed) return false;
      if (searchState.deliveryType == 'SUPPLIER_DELIVERY' && !car.isSupplierDeliveryAllowed) return false;
      if (searchState.deliveryType == 'DOORSTEP_DELIVERY' && !car.isDoorstepDeliveryAllowed) return false;

      // Apply modal filters
      if (_filterState.vehicleTypes.isNotEmpty && !_filterState.vehicleTypes.contains(car.type)) return false;
      if (_filterState.minPrice != null && car.pricePerDay < _filterState.minPrice!) return false;
      if (_filterState.maxPrice != null && car.pricePerDay > _filterState.maxPrice!) return false;
      if (_filterState.transmissions.isNotEmpty && !_filterState.transmissions.contains(car.transmission)) return false;
      if (_filterState.fuelTypes.isNotEmpty && !_filterState.fuelTypes.contains(car.fuelType)) return false;
      
      if (_filterState.seats.isNotEmpty) {
        bool match = false;
        if (_filterState.seats.contains('5 Seats') && car.seats == 5) match = true;
        if (_filterState.seats.contains('7 Seats') && car.seats == 7) match = true;
        if (_filterState.seats.contains('8+ Seats') && car.seats >= 8) match = true;
        if (!match) return false;
      }
      
      if (_filterState.supplierOptions.isNotEmpty && !_filterState.supplierOptions.contains(car.supplierOption)) return false;
      
      if (_filterState.features.isNotEmpty) {
        if (!_filterState.features.every((f) => car.features.contains(f))) return false;
      }
      
      if (_filterState.acOptions.isNotEmpty) {
        bool hasAC = car.features.contains('A/C');
        bool matchAC = _filterState.acOptions.contains('AC') && hasAC;
        bool matchNonAC = _filterState.acOptions.contains('Non-AC') && !hasAC;
        if (!matchAC && !matchNonAC) return false;
      }

      return true;
    }).toList();
    
    if (_filterState.sortBy == 'Lowest Price') {
      cars.sort((a, b) => a.pricePerDay.compareTo(b.pricePerDay));
    } else if (_filterState.sortBy == 'Highest Price') {
      cars.sort((a, b) => b.pricePerDay.compareTo(a.pricePerDay));
    } else if (_filterState.sortBy == 'Highest Rated') {
      cars.sort((a, b) => b.rating.compareTo(a.rating));
    }
    
    return cars;
  }

  int _calculateDays() {
    final searchState = ref.read(carRentalSearchProvider);
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
          CarRentalHeader(
            title: 'Available Vehicles',
            trailing: IconButton(
              icon: const Icon(Icons.filter_list, color: AppColors.backgroundDark),
              onPressed: _showFilterModal,
            ),
          ),
          _buildCategoryTabs(isDark),
          Expanded(
            child: _isLoading
                ? _buildSkeletonList(isDark)
                : _filteredCars.isEmpty 
                  ? Center(child: Text("No vehicles match your filters.", style: AppTextStyles.titleMedium))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      itemCount: _filteredCars.length,
                      itemBuilder: (context, index) {
                        return _buildVehicleCard(isDark, index, _filteredCars[index], durationDays);
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

  Widget _buildVehicleCard(bool isDark, int index, CarModel car, int durationDays) {
    final isSelected = _selectedVehicleIndex == index;
    
    return GestureDetector(
      onTap: () {
        context.pushNamed(RouteNames.carRentalDetails, extra: car);
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
                child: Image.network(
                  car.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: isDark ? Colors.black12 : Colors.grey.shade100,
                      child: const Center(
                        child: Icon(Icons.directions_car, size: 80, color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight),
                      ),
                    );
                  },
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
                                Text(car.name, style: AppTextStyles.titleMedium),
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
                                Text(car.supplier, style: AppTextStyles.bodySmall.copyWith(color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight)),
                                const SizedBox(width: 8),
                                const Icon(Icons.star, size: 14, color: Colors.orange),
                                const SizedBox(width: 2),
                                Text('${car.rating}', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
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
                      if (car.transmission == 'Automatic') _buildSpec(Icons.settings, 'Automatic') else _buildSpec(Icons.settings, 'Manual'),
                      if (car.fuelType == 'Petrol') _buildSpec(Icons.local_gas_station, 'Petrol') else if (car.fuelType == 'Electric') _buildSpec(Icons.electric_car, 'Electric') else _buildSpec(Icons.local_gas_station, car.fuelType),
                      _buildSpec(Icons.airline_seat_recline_normal, '${car.seats} Seats'),
                      if (car.features.contains('A/C')) _buildSpec(Icons.ac_unit, 'A/C'),
                      if (car.features.contains('Unlimited Mileage')) _buildSpec(Icons.speed, 'Unlimited Mileage'),
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
                          Text(car.supplierOption, style: AppTextStyles.labelSmall.copyWith(color: AppColors.success)),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('\$${car.pricePerDay.toInt()}', style: AppTextStyles.titleLarge.copyWith(color: AppColors.primaryGold)),
                              Text(' / day', style: AppTextStyles.bodySmall.copyWith(color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight)),
                            ],
                          ),
                          Text('Total: \$${(car.pricePerDay * durationDays).toInt()} for $durationDays ${durationDays == 1 ? 'day' : 'days'}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11)),
                        ],
                      ),
                      OutlinedButton(
                        onPressed: () {
                          context.pushNamed(RouteNames.carRentalDetails, extra: car);
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

  Widget _buildSpec(IconData icon, String label) {
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

                _buildFilterHeader('Vehicle Type'),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    _buildCheckbox('Go - 5P', _state.vehicleTypes),
                    _buildCheckbox('Premium - 5P', _state.vehicleTypes),
                    _buildCheckbox('SUV - 7P', _state.vehicleTypes),
                    _buildCheckbox('Van - 8P & Above', _state.vehicleTypes),
                          _buildCheckbox('Electric - 5P', _state.vehicleTypes),
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
                
                _buildFilterHeader('Air Conditioning'),
                Row(
                  children: [
                    _buildCheckbox('AC', _state.acOptions),
                    const SizedBox(width: 24),
                    _buildCheckbox('Non-AC', _state.acOptions),
                  ],
                ),
                
                _buildFilterHeader('Fuel Type'),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    _buildCheckbox('Petrol', _state.fuelTypes),
                    _buildCheckbox('Diesel', _state.fuelTypes),
                    _buildCheckbox('Hybrid', _state.fuelTypes),
                    _buildCheckbox('Electric', _state.fuelTypes),
                  ],
                ),
                
                _buildFilterHeader('Seats'),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    _buildCheckbox('5 Seats', _state.seats),
                    _buildCheckbox('7 Seats', _state.seats),
                    _buildCheckbox('8+ Seats', _state.seats),
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
