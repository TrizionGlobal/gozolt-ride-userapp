import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/asset_paths.dart';
import '../../../../core/widgets/gozolt_button.dart';
import '../widgets/car_rental_header.dart';
import '../../domain/models/car_model.dart';
import '../../../../core/router/route_names.dart';
import '../../../ride/presentation/widgets/stripe_add_card_sheet.dart';
import '../../../ride/data/datasources/payment_remote_datasource.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/datasources/car_rental_remote_datasource.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/dio_provider.dart';
import '../providers/car_rental_search_provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/geo_utils.dart';
import '../../../history/presentation/screens/car_rentals_history_view.dart';
import '../../../rewards/presentation/providers/rewards_providers.dart';
import 'package:flutter/services.dart';

class CarRentalReviewScreen extends ConsumerStatefulWidget {
  final CarModel? car;
  const CarRentalReviewScreen({super.key, this.car});

  @override
  ConsumerState<CarRentalReviewScreen> createState() => _CarRentalReviewScreenState();
}

class _CarRentalReviewScreenState extends ConsumerState<CarRentalReviewScreen> {
  bool _agreeRentalAgreement = false;
  bool _agreeTerms = false;
  bool _isBooking = false;
  bool _useCoins = false;

  bool _documentsUploaded = false;
  String? _nationalIdPath;
  String? _drivingLicencePath;

  bool _isCheckingActiveBooking = true;
  bool _hasActiveBooking = false;
  Map<String, dynamic>? _activeBookingData;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _checkActiveBooking();
  }

  Future<void> _checkActiveBooking() async {
    try {
      final dio = ref.read(dioProvider);
      final datasource = CarRentalRemoteDatasource(dio);
      final myBookings = await datasource.getMyBookings();
      
      final activeBooking = myBookings.cast<Map<String, dynamic>?>().firstWhere(
        (b) => b != null && ['PENDING_PAYMENT', 'PENDING_APPROVAL', 'CONFIRMED', 'ACTIVE'].contains(b['status']),
        orElse: () => null,
      );

      if (activeBooking != null && mounted) {
        setState(() {
          _hasActiveBooking = true;
          _activeBookingData = activeBooking;
        });
      }
    } catch (e) {
      debugPrint('Failed active booking check: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingActiveBooking = false;
        });
      }
    }
  }

  Future<void> _pickImage(bool isNationalId) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (isNationalId) {
          _nationalIdPath = image.path;
        } else {
          _drivingLicencePath = image.path;
        }
        
        if (_nationalIdPath != null && _drivingLicencePath != null) {
          _documentsUploaded = true;
        }
      });
    }
  }

  Widget _buildSummarySection(BuildContext context, {required String title, required List<Widget> children}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryGold)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: isTotal ? AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold) : AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value, 
              textAlign: TextAlign.right,
              style: isTotal ? AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold) : AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxRow(String title, bool value, ValueChanged<bool?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primaryGold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    if (_isCheckingActiveBooking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryGold),
        ),
      );
    }

    final car = widget.car;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Find the selected protection package
    ProtectionPackageModel? selectedProtection;
    if (widget.car != null && widget.car!.selectedProtectionPackageId != null) {
      try {
        selectedProtection = widget.car!.protectionPackages.firstWhere(
          (p) => p.valueIdentifier == widget.car!.selectedProtectionPackageId
        );
      } catch (e) {
        selectedProtection = null;
      }
    }

    // Find selected addons
    List<AddonModel> selectedAddons = [];
    if (widget.car != null && widget.car!.selectedAddonIds != null) {
      selectedAddons = widget.car!.addons
          .where((a) => widget.car!.selectedAddonIds!.contains(a.id))
          .toList();
    }

    final searchState = ref.watch(carRentalSearchProvider);
    final bool isFlexible = searchState.isFlexible;

    int durationDays = 1;
    if (searchState.pickupDate != null && searchState.dropoffDate != null) {
      final hours = searchState.dropoffDate!.difference(searchState.pickupDate!).inHours;
      if (hours > 0) {
        durationDays = (hours / 24).ceil();
      }
      if (durationDays < 1) durationDays = 1;
    }

    final double basePrice = (widget.car?.pricePerDay ?? 45.0) * durationDays;
    final double flexiblePrice = isFlexible ? (15.0 * durationDays) : 0.0;
    final double protectionPrice = (selectedProtection?.pricePerDay ?? 0.0) * durationDays;
    
    double addonsPrice = 0.0;
    for (final addon in selectedAddons) {
      addonsPrice += addon.pricePerDay * durationDays;
    }
    
    double pickupFee = 0.0;
    double dropoffFee = 0.0;
    double pickupDistance = 0.0;
    double dropoffDistance = 0.0;
    final supLat = widget.car?.supplierLatitude;
    final supLng = widget.car?.supplierLongitude;
    
    if (supLat != null && supLng != null) {
        final charge = (widget.car?.deliveryCharge != null && widget.car!.deliveryCharge > 0) ? widget.car!.deliveryCharge : 1.5;

      if (searchState.deliveryType != 'SELF_PICKUP' && searchState.pickupLat != null && searchState.pickupLng != null && supLat != null && supLng != null) {
        pickupDistance = haversineDistanceKm(supLat, supLng, searchState.pickupLat!, searchState.pickupLng!);
        pickupFee = pickupDistance * charge;
      }
      
      if (searchState.dropoffLat != null && searchState.dropoffLng != null && supLat != null && supLng != null) {
        if (searchState.deliveryType == 'SELF_PICKUP' && searchState.dropoffLat == searchState.pickupLat && searchState.dropoffLng == searchState.pickupLng) {
          dropoffDistance = 0;
          dropoffFee = 0;
        } else {
          dropoffDistance = haversineDistanceKm(supLat, supLng, searchState.dropoffLat!, searchState.dropoffLng!);
          dropoffFee = dropoffDistance * charge;
        }
      }
    }
    
    final double deliveryFee = pickupFee + dropoffFee;    
    final double subtotal = basePrice + flexiblePrice + protectionPrice + addonsPrice + deliveryFee;
    
    // GoCoins logic
    final rewardSummary = ref.watch(rewardSummaryProvider).value;
    final int balance = rewardSummary?.currentPoints.toInt() ?? 0;
    final int conversionRate = (ref.watch(rewardRulesProvider).value?.redemption.pointsToEurRatio ?? 400.0).toInt();
    
    final double maxEurValue = balance / conversionRate;
    final double appliedEurValue = maxEurValue > subtotal ? subtotal : maxEurValue;
    final int coinsUsed = (appliedEurValue * conversionRate).round();

    final double discount = _useCoins ? appliedEurValue : 0.0;
    final double totalPayable = subtotal - discount;
    final int earnedCoins = (subtotal * 10).floor();

    final isFormValid = _agreeRentalAgreement && _agreeTerms && _documentsUploaded;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const CarRentalHeader(title: 'Review and Book'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummarySection(
                    context,
                    title: 'Vehicle Details',
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 100,
                              height: 65,
                              child: car != null && car.imageUrl.isNotEmpty ? Image.network(
                                car.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Icon(Icons.directions_car, color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight, size: 65),
                              ) : Icon(Icons.directions_car, color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight, size: 65),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(car?.name.toUpperCase() ?? 'TOYOTA COROLLA', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('${car?.transmission ?? 'Automatic'} • ${car?.seats ?? 5} Seats • ${car?.fuelType ?? 'Petrol'}', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      _buildRow('Pickup', 'Aug 04, 2026 • 5:07 PM'),
                      _buildRow('Drop-off', 'Aug 06, 2026 • 6:07 PM'),
                      _buildRow('Location', 'Malta International Airport'),
                    ],
                  ),
                  
                  _buildSummarySection(
                    context,
                    title: 'Upload Documents',
                    children: [
                      Text('Please upload your documents to proceed with the booking.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('National ID', style: AppTextStyles.bodyMedium),
                                const SizedBox(height: 8),
                                _nationalIdPath == null
                                    ? OutlinedButton(
                                        onPressed: () => _pickImage(true),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: AppColors.primaryGold),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          minimumSize: const Size(0, 36),
                                        ),
                                        child: Text('Upload ID', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryGold)),
                                      )
                                    : GestureDetector(
                                        onTap: () {
                                          showDialog(context: context, builder: (_) => Dialog(
                                            backgroundColor: Colors.transparent,
                                            insetPadding: const EdgeInsets.all(16),
                                            child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(_nationalIdPath!))),
                                          ));
                                        },
                                        child: Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.file(File(_nationalIdPath!), height: 80, width: double.infinity, fit: BoxFit.cover),
                                            ),
                                            Positioned(
                                              top: 4,
                                              right: 4,
                                              child: GestureDetector(
                                                onTap: () => _pickImage(true),
                                                child: Container(
                                                  padding: const EdgeInsets.all(4),
                                                  decoration: BoxDecoration(color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight, shape: BoxShape.circle),
                                                  child: const Icon(Icons.edit, size: 16, color: Colors.white),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Driving Licence', style: AppTextStyles.bodyMedium),
                                const SizedBox(height: 8),
                                _drivingLicencePath == null
                                    ? OutlinedButton(
                                        onPressed: () => _pickImage(false),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: AppColors.primaryGold),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          minimumSize: const Size(0, 36),
                                        ),
                                        child: Text('Upload Licence', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryGold)),
                                      )
                                    : GestureDetector(
                                        onTap: () {
                                          showDialog(context: context, builder: (_) => Dialog(
                                            backgroundColor: Colors.transparent,
                                            insetPadding: const EdgeInsets.all(16),
                                            child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(_drivingLicencePath!))),
                                          ));
                                        },
                                        child: Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.file(File(_drivingLicencePath!), height: 80, width: double.infinity, fit: BoxFit.cover),
                                            ),
                                            Positioned(
                                              top: 4,
                                              right: 4,
                                              child: GestureDetector(
                                                onTap: () => _pickImage(false),
                                                child: Container(
                                                  padding: const EdgeInsets.all(4),
                                                  decoration: BoxDecoration(color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight, shape: BoxShape.circle),
                                                  child: const Icon(Icons.edit, size: 16, color: Colors.white),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  _buildSummarySection(
                    context,
                    title: 'Protection & Add-ons',
                    children: [
                      _buildRow('Protection Package', selectedProtection != null ? '${selectedProtection.title} (${selectedProtection.pricePerDay == 0 ? 'Included' : '+€${selectedProtection.pricePerDay.toStringAsFixed(2)}'})' : 'Basic Price (Included)'),
                      _buildRow('Mileage Package', 'Unlimited'),
                      if (selectedAddons.isEmpty)
                        _buildRow('Add-ons', 'None selected')
                      else
                        ...selectedAddons.map((addon) => _buildRow(addon.name, '€${addon.pricePerDay.toStringAsFixed(2)} / day')),
                    ],
                  ),

                  // ── GoCoins Redeem Section ──
                  Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _useCoins ? AppColors.primaryGold : (Theme.of(context).dividerTheme.color ?? AppColors.borderDark), width: _useCoins ? 1.5 : 0.5),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGold.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Image.asset(AssetPaths.iconGoCoin, width: 32, height: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Redeem GoCoins', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(
                                  'Balance: $balance Coins',
                                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                                ),
                                if (appliedEurValue > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      'Save €${appliedEurValue.toStringAsFixed(2)} with $coinsUsed coins',
                                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryGold, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Transform.scale(
                            scale: 0.9,
                            child: Switch.adaptive(
                              value: _useCoins,
                              activeColor: AppColors.backgroundDark,
                              activeTrackColor: AppColors.primaryGold,
                              inactiveTrackColor: Theme.of(context).dividerTheme.color ?? AppColors.borderDark,
                              onChanged: (val) {
                                setState(() {
                                  _useCoins = val;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                  ),

                  _buildSummarySection(
                    context,
                    title: 'Payment Summary',
                    children: [
                      _buildRow('Vehicle Rental ($durationDays days)', '€${basePrice.toStringAsFixed(2)}'),
                      if (isFlexible) _buildRow('Stay Flexible ($durationDays days)', '€${flexiblePrice.toStringAsFixed(2)}'),
                      
                      if (selectedProtection != null)
                        _buildRow(selectedProtection.title, '€${protectionPrice.toStringAsFixed(2)}')
                      else
                        _buildRow('Basic Protection', '€${protectionPrice.toStringAsFixed(2)}'),
                      
                      ...selectedAddons.map((addon) {
                        final addonTotal = addon.pricePerDay * durationDays;
                        return _buildRow('${addon.name} ($durationDays days)', '€${addonTotal.toStringAsFixed(2)}');
                      }),
                      if (pickupFee > 0)
                        _buildRow('Pickup Fee (${pickupDistance.toStringAsFixed(1)} km)', '€${pickupFee.toStringAsFixed(2)}'),
                      if (dropoffFee > 0)
                        _buildRow('Dropoff Fee (${dropoffDistance.toStringAsFixed(1)} km)', '€${dropoffFee.toStringAsFixed(2)}'),
                      const Divider(height: 32),
                      
                      _buildRow('Subtotal', '€${subtotal.toStringAsFixed(2)}'),
                      if (_useCoins)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('GoCoins Discount', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryGold)),
                              Text('-€${discount.toStringAsFixed(2)}', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryGold)),
                            ],
                          ),
                        ),
                      Divider(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
                      const SizedBox(height: 12),
                      _buildRow('Total', '€${totalPayable.toStringAsFixed(2)}', isTotal: true),
                    ],
                  ),

                  _buildSummarySection(
                    context,
                    title: 'Booking Terms',
                    children: [
                      _buildCheckboxRow('I agree to the Rental Agreement', _agreeRentalAgreement, (val) => setState(() => _agreeRentalAgreement = val ?? false)),
                      _buildCheckboxRow('I accept Terms & Conditions', _agreeTerms, (val) => setState(() => _agreeTerms = val ?? false)),
                    ],
                  ),

                  const SizedBox(height: 80),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GozoltButton(
                label: _isBooking ? 'Booking...' : 'Book Now',
                width: double.infinity,
            onPressed: _isBooking ? null : () async {
              if (_hasActiveBooking && _activeBookingData != null) {
                _showActiveBookingModal(_activeBookingData!);
                return;
              }

              if (!isFormValid) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please upload required documents and accept the booking terms.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                return;
              }

              String? successfulBookingId;
              
              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => StripeAddCardSheet(
                  datasource: PaymentRemoteDatasource(ref.read(dioProvider)),
                  amount: totalPayable,
                  simulatePayment: false,
                  onCardAdded: (paymentMethodId) async {
                    try {
                      final dio = ref.read(dioProvider);
                      final datasource = CarRentalRemoteDatasource(dio);
                      final searchState = ref.read(carRentalSearchProvider);
                      
                      // Fallbacks just in case
                      final fallbackStart = DateTime.now().add(const Duration(days: 1));
                      final fallbackEnd = fallbackStart.add(const Duration(days: 3));
                      
                      final startDate = searchState.pickupDate ?? fallbackStart;
                      final endDate = searchState.dropoffDate ?? fallbackEnd;
                      
                      final bookingData = await datasource.createBooking(
                        vehicleId: widget.car?.id ?? '1', 
                        startDate: startDate, 
                        endDate: endDate,
                        protectionPackageId: widget.car?.selectedProtectionPackageId,
                        addonIds: widget.car?.selectedAddonIds,
                        deliveryType: searchState.deliveryType,
                        deliveryAddress: searchState.deliveryAddress,
                        pickupLocation: searchState.pickupLocation,
                        dropoffLocation: searchState.dropoffLocation,
                        isFlexible: searchState.isFlexible,
                        nationalIdPath: _nationalIdPath!,
                        drivingLicencePath: _drivingLicencePath!,
                        paymentMethodId: paymentMethodId,
                        walletAmountUsed: discount > 0 ? discount : null,
                        deliveryFee: deliveryFee,
                      );
                      successfulBookingId = bookingData['id'];
                      ref.invalidate(carRentalHistoryProvider);
                      
                    } catch (e) {
                      debugPrint('Error creating booking: $e');
                      throw Exception(e.toString().replaceAll('Exception: ', ''));
                    }
                  },
                ),
              );
              
              if (successfulBookingId != null && context.mounted) {
                context.pushNamed(RouteNames.carRentalConfirmation, extra: {
                  'car': widget.car,
                  'bookingId': successfulBookingId,
                  'earnedCoins': earnedCoins,
                  'totalAmount': totalPayable,
                });
              }
            },
          ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActiveBookingModal(Map<String, dynamic> activeBooking) {
    final vehicle = activeBooking['vehicle'] ?? {};
    final vehicleName = vehicle['name'] ?? 'Rental Car';
    final returnDateStr = activeBooking['endDate'] ?? '';
    final grandTotal = activeBooking['grandTotal'] ?? 0;
    
    DateTime? returnDate;
    int extraDays = 0;
    bool isExpired = false;
    if (returnDateStr.isNotEmpty) {
      try {
        returnDate = DateTime.parse(returnDateStr);
        final now = DateTime.now();
        if (now.isAfter(returnDate)) {
          isExpired = true;
          extraDays = now.difference(returnDate).inDays;
        }
      } catch (_) {}
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => WillPopScope(
        onWillPop: () async => false,
        child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? (isDark ? AppColors.cardDark : Colors.white),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 56),
              const SizedBox(height: 16),
              
              Text(
                'Active Booking Detected',
                style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              
              Text(
                'You already have an active car rental. Please return your current vehicle before booking another one.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Details Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
                ),
                child: Column(
                  children: [
                    _buildModalRow('Vehicle', vehicleName, isBold: true),
                    const Divider(height: 24),
                    _buildModalRow('Total Price', '€${double.parse(grandTotal.toString()).toStringAsFixed(2)}'),
                    const SizedBox(height: 12),
                    if (returnDate != null)
                      _buildModalRow('Return Date', DateFormat('MMM dd, yyyy').format(returnDate)),
                    
                    if (isExpired) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Expired by $extraDays ${extraDays == 1 ? "day" : "days"}',
                              style: AppTextStyles.labelLarge.copyWith(color: Colors.red, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ]
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              GozoltButton(
                label: 'Go to Home',
                width: double.infinity,
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.goNamed(RouteNames.home);
                },
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildModalRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
