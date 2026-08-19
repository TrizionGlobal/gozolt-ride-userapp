import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
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

  bool _documentsUploaded = false;
  String? _nationalIdPath;
  String? _drivingLicencePath;

  final ImagePicker _picker = ImagePicker();

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
    
    final double subtotal = basePrice + flexiblePrice + protectionPrice + addonsPrice;
    final double totalPayable = subtotal;

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
                              child: car != null ? Image.network(
                                car.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.directions_car, color: Colors.grey, size: 65),
                              ) : const Icon(Icons.directions_car, color: Colors.grey, size: 65),
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
                                                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
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
                                                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
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
                    title: 'Delivery Details (Doorstep)',
                    children: [
                      _buildRow('Delivery Address', '123 Gozolt Ave, Valletta'),
                      _buildRow('Phone Number', '+356 9912 3456'),
                      _buildRow('Email', 'user@gozolt.com'),
                      _buildRow('WhatsApp Number', '+356 9912 3456'),
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
                      const Divider(height: 32),
                      
                      _buildRow('TOTAL PAYABLE', '€${totalPayable.toStringAsFixed(2)}', isTotal: true),
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
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          child: GozoltButton(
            label: _isBooking ? 'BOOKING...' : 'BOOK NOW',
            width: double.infinity,
            onPressed: _isBooking ? null : () async {
              if (!isFormValid) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please upload required documents and accept the booking terms.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                return;
              }

              setState(() {
                _isBooking = true;
              });

              try {
                final datasource = CarRentalRemoteDatasource(ref.read(dioProvider));
                final myBookings = await datasource.getMyBookings();
                
                final activeBooking = myBookings.cast<Map<String, dynamic>?>().firstWhere(
                  (b) => b != null && ['PENDING_PAYMENT', 'PENDING_APPROVAL', 'CONFIRMED', 'ACTIVE'].contains(b['status']),
                  orElse: () => null,
                );

                if (activeBooking != null) {
                  setState(() { _isBooking = false; });
                  _showActiveBookingModal(activeBooking);
                  return;
                }
              } catch (e) {
                debugPrint('Failed active booking check: $e');
              }

              setState(() {
                _isBooking = false;
              });

              String? successfulBookingId;
              
              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => StripeAddCardSheet(
                  datasource: PaymentRemoteDatasource(ref.read(dioProvider)),
                  amount: totalPayable,
                  simulatePayment: true,
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
                      );
                      
                      successfulBookingId = bookingData['id'];
                      
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
                });
              }
            },
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
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
                    color: Colors.grey.withOpacity(0.3),
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
