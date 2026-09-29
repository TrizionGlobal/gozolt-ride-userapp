import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/models/airport_transfer_vehicle.dart';
import '../providers/airport_transfer_provider.dart';
import '../providers/airport_transfer_vehicle_provider.dart';
import '../widgets/airport_transfer_header.dart';
import '../../../../core/widgets/gozolt_button.dart';
import '../../../../core/widgets/app_filled_text_field.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';

class AirportTransferFilterState {
  String sortBy;
  Set<String> vehicleTypes;
  double? minPrice;
  double? maxPrice;
  Set<String> passengerOptions;
  Set<String> luggageOptions;
  AirportTransferFilterState({
    this.sortBy = 'Recommended',
    Set<String>? vehicleTypes,
    this.minPrice,
    this.maxPrice,
    Set<String>? passengerOptions,
    Set<String>? luggageOptions,
  })  : vehicleTypes = vehicleTypes ?? <String>{},
        passengerOptions = passengerOptions ?? <String>{},
        luggageOptions = luggageOptions ?? <String>{};
  AirportTransferFilterState clone() {
    return AirportTransferFilterState(
      sortBy: sortBy,
      vehicleTypes: Set<String>.from(vehicleTypes),
      minPrice: minPrice,
      maxPrice: maxPrice,
      passengerOptions: Set<String>.from(passengerOptions),
      luggageOptions: Set<String>.from(luggageOptions),
    );
  }
}

class AirportTransferChooseScreen extends ConsumerStatefulWidget {
  const AirportTransferChooseScreen({super.key});
  @override
  ConsumerState<AirportTransferChooseScreen> createState() =>
      _AirportTransferChooseScreenState();
}

class _AirportTransferChooseScreenState
    extends ConsumerState<AirportTransferChooseScreen> {
  static const List<String> _categories = [
    'All',
    'Go - 5P',
    'Premium - 5P',
    'SUV - 7P',
    'Mini Van - 8P & Above',
    'Van - 8P & Above',
    'Electric - 5P',
  ];

  String _selectedCategory = 'All';
  AirportTransferFilterState _filterState = AirportTransferFilterState();

Future<void> _showFilterModal() async {
  final newFilterState =
      await showModalBottomSheet<AirportTransferFilterState>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).cardTheme.color,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(20),
      ),
    ),
    builder: (context) {
      return _AirportTransferFilterModal(
        initialState: _filterState,
      );
    },
  );
  if (newFilterState != null && mounted) {
    setState(() {
      _filterState = newFilterState;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final draft = ref.watch(airportTransferDraftProvider);
    final vehiclesAsync = ref.watch(airportTransferVehiclesProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          AirportTransferHeader(
            title: 'Choose Transfer',
            trailing: IconButton(
              onPressed: _showFilterModal,
              tooltip: 'Filters',
              icon: const Icon(
                Icons.filter_list_rounded,
                color: AppColors.backgroundDark,
                size: 22,
              ),
            ),
          ),
          _JourneySummaryCard(
            isDark: isDark,
            pickupAddress: draft.pickupLocation?.address ?? 'Pickup location',
            dropoffAddress:
                draft.dropoffLocation?.address ?? 'Drop-off location',
            pickupDate: draft.pickupDate,
            pickupTime: draft.pickupTime,
            passengerCount: draft.totalPassengers,
            luggageCount: draft.totalLuggage,
            isRoundTrip: draft.isRoundTrip,
            returnDate: draft.returnDate,
            onEdit: () => Navigator.of(context).pop(),
          ),
          _buildCategoryTabs(isDark),
          Expanded(
            child: vehiclesAsync.when(
              loading: () => _buildLoadingList(isDark),
              error: (error, stackTrace) => _buildErrorState(error),
              data: (vehicles) {
                final filteredVehicles = _filterVehicles(vehicles);
                if (filteredVehicles.isEmpty) {
                  return _buildEmptyState();
                }
                return RefreshIndicator(
                  color: AppColors.primaryGold,
                  onRefresh: () async {
                    ref.invalidate(
                      airportTransferVehiclesProvider,
                    );
                    await ref.read(
                      airportTransferVehiclesProvider.future,
                    );
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB( 16, 6, 16, 24),
                    itemCount: filteredVehicles.length,
                    itemBuilder: (context, index) {
                      return _TransferVehicleCard(
                        vehicle: filteredVehicles[index],
                        isDark: isDark,
                        onPressed: () => _selectVehicle(
                          filteredVehicles[index],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  double _priceValue(AirportTransferVehicle vehicle) {
    return double.tryParse(
          vehicle.formattedPrice.replaceAll(RegExp(r'[^0-9.]'), ''),
        ) ??
        0;
  }

  int _capacityValue(String text) {
    final match = RegExp(r'\d+').firstMatch(text);
    return match == null ? 0 : int.tryParse(match.group(0)!) ?? 0;
  }

  List<AirportTransferVehicle> _filterVehicles(
    List<AirportTransferVehicle> vehicles,
  ) {
    final filtered = vehicles.where((vehicle) {
      if (_selectedCategory != 'All' &&
          vehicle.type != _selectedCategory) {
        return false;
      }

      if (_filterState.vehicleTypes.isNotEmpty &&
          !_filterState.vehicleTypes.contains(vehicle.type)) {
        return false;
      }

      final price = _priceValue(vehicle);
      if (_filterState.minPrice != null &&
          price < _filterState.minPrice!) {
        return false;
      }
      if (_filterState.maxPrice != null &&
          price > _filterState.maxPrice!) {
        return false;
      }

      final passengers = _capacityValue(vehicle.passengerText);
      if (_filterState.passengerOptions.isNotEmpty) {
        final matches =
            (_filterState.passengerOptions.contains('Up to 5') &&
                passengers <= 5) ||
            (_filterState.passengerOptions.contains('Up to 7') &&
                passengers >= 6 &&
                passengers <= 7) ||
            (_filterState.passengerOptions.contains('8+ Passengers') &&
                passengers >= 8);
        if (!matches) return false;
      }

      final luggage = _capacityValue(vehicle.luggageText);
      if (_filterState.luggageOptions.isNotEmpty) {
        final matches =
            (_filterState.luggageOptions.contains('1-2 Bags') &&
                luggage >= 1 &&
                luggage <= 2) ||
            (_filterState.luggageOptions.contains('3-4 Bags') &&
                luggage >= 3 &&
                luggage <= 4) ||
            (_filterState.luggageOptions.contains('5+ Bags') &&
                luggage >= 5);
        if (!matches) return false;
      }

      return true;
    }).toList();

    switch (_filterState.sortBy) {
      case 'Lowest Price':
        filtered.sort((a, b) => _priceValue(a).compareTo(_priceValue(b)));
        break;
      case 'Highest Price':
        filtered.sort((a, b) => _priceValue(b).compareTo(_priceValue(a)));
        break;
      case 'Highest Rated':
        filtered.sort(
          (a, b) => b.supplierRating.compareTo(a.supplierRating),
        );
        break;
      case 'Recommended':
      default:
        filtered.sort((a, b) {
          final aPriority = a.isRecommended || a.isBestValue ? 1 : 0;
          final bPriority = b.isRecommended || b.isBestValue ? 1 : 0;
          return bPriority.compareTo(aPriority);
        });
    }
    return filtered;
  }

  Widget _buildCategoryTabs(bool isDark) {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        itemCount: _categories.length,
        separatorBuilder: (context, index) {
          return const SizedBox(width: 8);

        },
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;
          return ChoiceChip(
            selected: isSelected,
            showCheckmark: isSelected,
            checkmarkColor: AppColors.textPrimaryLight,
            selectedColor: AppColors.primaryGold,
            backgroundColor:
                isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            side: BorderSide(
              color: isSelected
                  ? AppColors.primaryGold
                  : isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            label: Text(
              category,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.textPrimaryLight
                    : isDark
                        ? AppColors.textPrimary
                        : AppColors.textPrimaryLight,
              ),
            ),
            onSelected: (_) {
              setState(() {
                _selectedCategory = category;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildLoadingList(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          height: 230,
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryGold,
              strokeWidth: 2,
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 44,
            ),
            const SizedBox(height: 12),
            Text(
              'Unable to load transfer vehicles',
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                ref.invalidate(
                  airportTransferVehiclesProvider,
                );
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.airport_shuttle_outlined,
              color: AppColors.primaryGold,
              size: 52,
            ),
            const SizedBox(height: 12),
            Text(
              'No suitable vehicles found',
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Try another category or edit the passenger and luggage details.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _selectedCategory = 'All';
                });
              },
              child: const Text('Show All'),
            ),
          ],
        ),
      ),
    );
  }

  void _selectVehicle(AirportTransferVehicle vehicle) {
    ref.read(selectedAirportTransferVehicleProvider.notifier).select(vehicle);
    context.pushNamed(
    RouteNames.airportTransferDetails,
    );     
  }
}

class _AirportTransferFilterModal extends StatefulWidget {
  final AirportTransferFilterState initialState;
  const _AirportTransferFilterModal({
    required this.initialState,
  });

  @override
  State<_AirportTransferFilterModal> createState() =>
      _AirportTransferFilterModalState();
}

class _AirportTransferFilterModalState
    extends State<_AirportTransferFilterModal> {
  late AirportTransferFilterState _state;
  final List<String> _sortOptions = [
    'Recommended',
    'Lowest Price',
    'Highest Price',
    'Highest Rated',
  ];

  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _state = widget.initialState.clone();
    if (_state.minPrice != null) {
      _minPriceController.text = _state.minPrice.toString();
    }

    if (_state.maxPrice != null) {
      _maxPriceController.text = _state.maxPrice.toString();
    }
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  Widget _buildFilterHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 22,
        bottom: 12,
      ),

      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.labelLarge.copyWith(
          color: AppColors.primaryGold,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCheckbox(
    String title,
    Set<String> targetSet,
  ) {

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        setState(() {
          if (targetSet.contains(title)) {
            targetSet.remove(title);
          } else {
            targetSet.add(title);
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: targetSet.contains(title),
                activeColor: AppColors.primaryGold,
                onChanged: (selected) {
                  setState(() {
                    if (selected == true) {
                      targetSet.add(title);
                    } else {
                      targetSet.remove(title);
                    }
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.90,
      padding: const EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceDark
            : Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Filters & Sorting',
                  style: AppTextStyles.titleLarge,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Divider(
            color: isDark
                ? AppColors.borderDark
                : Colors.grey.shade300,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 30),
              children: [
                _buildFilterHeader('Sort By'),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceDark
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _state.sortBy,
                      isExpanded: true,
                      dropdownColor: isDark
                          ? AppColors.surfaceDark
                          : Colors.white,
                      items: _sortOptions.map((option) {
                        return DropdownMenuItem<String>(
                          value: option,
                          child: Text(
                            option,
                            style: AppTextStyles.bodyMedium,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _state.sortBy = value;
                          });
                        }
                      },
                    ),
                  ),
                ),
                _buildFilterHeader('Vehicle Type'),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCheckbox(
                      'Go - 5P',
                      _state.vehicleTypes,
                    ),
                    _buildCheckbox(
                      'Premium - 5P',
                      _state.vehicleTypes,
                    ),
                    _buildCheckbox(
                      'SUV - 7P',
                      _state.vehicleTypes,
                    ),
                    _buildCheckbox(
                      'Mini Van - 8P & Above',
                      _state.vehicleTypes,
                    ),
                    _buildCheckbox(
                      'Van - 8P & Above',
                      _state.vehicleTypes,
                    ),
                    _buildCheckbox(
                      'Electric - 5P',
                      _state.vehicleTypes,
                    ),
                  ],
                ),
                
                _buildFilterHeader('Price Range'),
                Row(
                  children: [
                    Expanded(
                      child: AppFilledTextField(
                        controller: _minPriceController,
                        hint: 'Min €',
                        icon: Icons.euro_rounded,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppFilledTextField(
                        controller: _maxPriceController,
                        hint: 'Max €',
                        icon: Icons.euro_rounded,
                      ),
                    ),
                  ],
                ),
                _buildFilterHeader('Passengers'),
                Wrap(
                  spacing: 18,
                  runSpacing: 4,
                  children: [
                    _buildCheckbox(
                      'Up to 5',
                      _state.passengerOptions,
                    ),
                    _buildCheckbox(
                      'Up to 7',
                      _state.passengerOptions,
                    ),
                    _buildCheckbox(
                      '8+ Passengers',
                      _state.passengerOptions,
                    ),
                  ],
                ),
                _buildFilterHeader('Luggage Capacity'),
                Wrap(
                  spacing: 18,
                  runSpacing: 4,
                  children: [
                    _buildCheckbox(
                      '1-2 Bags',
                      _state.luggageOptions,
                    ),
                    _buildCheckbox(
                      '3-4 Bags',
                      _state.luggageOptions,
                    ),
                    _buildCheckbox(
                      '5+ Bags',
                      _state.luggageOptions,
                    ),
                  ],
                ),
              ],
            ),
          ),

          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB( 0, 10, 0, 16),
              child: SizedBox(
                height: 48,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(
                            context,
                            AirportTransferFilterState(),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark
                              ? Colors.white
                              : AppColors.backgroundDark,
                          side: BorderSide(
                            color: isDark
                                ? AppColors.borderDark
                                : Colors.grey.shade300,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Clear Filters',
                          style:
                              AppTextStyles.labelLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GozoltButton(
                        label: 'Apply Filters',
                        onPressed: () {
                          _state.minPrice = double.tryParse(
                            _minPriceController.text.trim(),
                          );
                          _state.maxPrice = double.tryParse(
                            _maxPriceController.text.trim(),
                          );

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

class _JourneySummaryCard extends StatelessWidget {
  const _JourneySummaryCard({
    required this.isDark,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.pickupDate,
    required this.pickupTime,
    required this.passengerCount,
    required this.luggageCount,
    required this.isRoundTrip,
    required this.returnDate,
    required this.onEdit,
  });
  final bool isDark;
  final String pickupAddress;
  final String dropoffAddress;
  final DateTime? pickupDate;
  final String? pickupTime;
  final int passengerCount;
  final int luggageCount;
  final bool isRoundTrip;
  final DateTime? returnDate;
  final VoidCallback onEdit;
  @override
  Widget build(BuildContext context) {
    final dateText = pickupDate == null
        ? 'Date not selected'
        : DateFormat('dd MMM').format(pickupDate!);
    final journeyDetails = <String>[
      dateText,
      if (pickupTime != null && pickupTime!.isNotEmpty) pickupTime!,
      '$passengerCount ${passengerCount == 1 ? 'passenger' : 'passengers'}',
      '$luggageCount ${luggageCount == 1 ? 'bag' : 'bags'}',
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryGold.withValues(
                alpha: 0.14,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.airport_shuttle_rounded,
              color: AppColors.primaryGold,
              size: 21,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$pickupAddress → $dropoffAddress',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  journeyDetails.join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondary
                        : AppColors.textSecondaryLight,
                  ),
                ),
                if (isRoundTrip && returnDate != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Round trip · Return ${DateFormat('dd MMM').format(returnDate!)}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primaryGold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit search',
            onPressed: onEdit,
            icon: const Icon(
              Icons.edit_outlined,
              size: 19,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransferVehicleCard extends ConsumerWidget {
  const _TransferVehicleCard({
    required this.vehicle,
    required this.isDark,
    required this.onPressed,
  });
  final AirportTransferVehicle vehicle;
  final bool isDark;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedVehicle = ref.watch(selectedAirportTransferVehicleProvider);
    final isSelected = selectedVehicle?.id == vehicle.id;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppColors.primaryGold
              : isDark
                  ? AppColors.borderDark
                  : AppColors.borderLight,
          width: isSelected ? 1.8 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark ? 0.10 : 0.04,
            ),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVehicleImage(),
            Padding(
              padding: const EdgeInsets.fromLTRB( 14, 12, 14, 14,),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBadges(),
                  _buildVehicleHeading(isSelected),
                  const SizedBox(height: 6),
                  _buildSupplierRow(),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 14,
                    runSpacing: 8,
                    children: [
                      _VehicleSpecification(
                        icon: Icons.category_outlined,
                        text: vehicle.type,
                        isDark: isDark,
                      ),
                      _VehicleSpecification(
                        icon: Icons.people_alt_outlined,
                        text: vehicle.passengerText,
                        isDark: isDark,
                      ),
                      _VehicleSpecification(
                        icon: Icons.luggage_outlined,
                        text: vehicle.luggageText,
                        isDark: isDark,
                      ),
                      _VehicleSpecification(
                        icon: Icons.schedule_rounded,
                        text: vehicle.estimatedDurationText,
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fixed transfer price',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.success,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              vehicle.formattedPrice,
                              style: AppTextStyles.titleLarge.copyWith(
                                color: AppColors.primaryGold,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: onPressed,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryGold,
                          side: const BorderSide(
                            color: AppColors.primaryGold,
                          ),
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 7,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          isSelected ? 'Selected' : 'View Details',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.primaryGold,
                            fontWeight: FontWeight.w600,
                          ),
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

  Widget _buildVehicleImage() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(15),
      ),

      child: SizedBox(
        width: double.infinity,
        height: 142,
        child: vehicle.imageUrl.isEmpty
            ? _buildImageFallback()
            : Image.network(
                vehicle.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildImageFallback();
                },
              ),
      ),
    );
  }

  Widget _buildImageFallback() {
    return Container(
      color: isDark ? AppColors.cardDark : const Color(0xFFF4F6F8),
      alignment: Alignment.center,
      child: Icon(
        Icons.airport_shuttle_rounded,
        size: 70,
        color: isDark ? AppColors.textSecondary : AppColors.textMutedLight,
      ),
    );
  }

  Widget _buildBadges() {
    if (!vehicle.isRecommended && !vehicle.isBestValue) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Wrap(
        spacing: 6,
        children: [
          if (vehicle.isBestValue)
            const _VehicleBadge(
              text: 'BEST VALUE',
              color: AppColors.success,
            ),
          if (vehicle.isRecommended)
            const _VehicleBadge(
              text: 'RECOMMENDED',
              color: AppColors.primaryGold,
            ),
        ],
      ),
    );
  }

  Widget _buildVehicleHeading(bool isSelected) {
    return Row(
      children: [
        Expanded(
          child: Text(
            vehicle.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (isSelected)
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.primaryGold,
          ),
      ],
    );
  }

  Widget _buildSupplierRow() {
    return Row(
      children: [
        Icon(
          Icons.business_outlined,
          size: 14,
          color:
              isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            vehicle.supplierName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppColors.textSecondary
                  : AppColors.textSecondaryLight,
            ),
          ),
        ),
        const Icon(
          Icons.star_rounded,
          size: 15,
          color: Colors.orange,
        ),
        const SizedBox(width: 2),
        Text(
          vehicle.supplierRating.toStringAsFixed(1),
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _VehicleSpecification extends StatelessWidget {
  const _VehicleSpecification({
    required this.icon,
    required this.text,
    required this.isDark,
  });
  final IconData icon;
  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 15,
          color:
              isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTextStyles.labelSmall.copyWith(
            color:
                isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

class _VehicleBadge extends StatelessWidget {
  const _VehicleBadge({
    required this.text,
    required this.color,
  });
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
