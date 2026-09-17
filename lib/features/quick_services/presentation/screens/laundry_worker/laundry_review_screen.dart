import '../../../../../core/widgets/booking_payment_sheet.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/quick_services_payment_selector.dart';
import '../../../../rewards/presentation/providers/rewards_providers.dart';
import '../../../../../core/constants/asset_paths.dart';

import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/router/route_names.dart';
import '../../widgets/quick_services_header.dart';
import '../../../data/models/quick_service_booking_data.dart';
import '../../widgets/quick_services_price_summary.dart';

class LaundryReviewScreen extends ConsumerStatefulWidget {
  final QuickServiceBookingData bookingData;
  const LaundryReviewScreen({super.key, required this.bookingData});

  @override
  ConsumerState<LaundryReviewScreen> createState() => _LaundryReviewScreenState();
}

class _LaundryReviewScreenState extends ConsumerState<LaundryReviewScreen> {
  late QuickServiceBookingData _bookingData;
  bool _useCoins = false;

  @override
  void initState() {
    super.initState();
    _bookingData = widget.bookingData;
  }

  bool _useGoCoins = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final data = _bookingData;

    final double rawSubtotal = data.subtotal;
    final double goCoinsDiscount = _useGoCoins ? 2.0 : 0.0;
    final double estimatedTotal = (rawSubtotal - goCoinsDiscount).clamp(0.0, 9999.0);

    final String formattedDate = DateFormat('dd MMM yyyy').format(data.scheduleDate);
    final String formattedTime = data.scheduleTime.format(context);

    // Format Special Care items list
    final List<Map<String, dynamic>> specialCareList = [];
    if ((data.specialCareShirtCount ?? 0) > 0) {
      specialCareList.add({'name': 'Shirts', 'count': data.specialCareShirtCount});
    }
    if ((data.specialCareTrouserCount ?? 0) > 0) {
      specialCareList.add({'name': 'Trousers', 'count': data.specialCareTrouserCount});
    }
    if ((data.specialCareDressCount ?? 0) > 0) {
      specialCareList.add({'name': 'Suits / Party wear', 'count': data.specialCareDressCount});
    }
    if ((data.specialCareBeddingCount ?? 0) > 0) {
      specialCareList.add({'name': 'Bedding / Linen', 'count': data.specialCareBeddingCount});
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const QuickServicesHeader(
            title: 'Review & Book',
            subtitle: 'Laundry Service',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service Overview Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGold.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.local_laundry_service, color: AppColors.primaryGold, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                data.selectedServiceTitle ?? 'Laundry & Ironing',
                                style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        if (data.selectedServiceTitle == 'Hospital Laundry' || data.selectedServiceTitle == 'Hotel Laundry' || data.selectedServiceTitle == 'Commercial Laundry') ...[
                          if (data.facilityName != null) _buildDetailRow(data.selectedServiceTitle == 'Commercial Laundry' ? 'Business Name:' : (data.selectedServiceTitle == 'Hotel Laundry' ? 'Hotel Name:' : 'Facility Name:'), data.facilityName!),
                          if (data.businessType != null) _buildDetailRow('Business Type:', data.businessType!),
                          if (data.collectionPoint != null) _buildDetailRow('Collection Point:', data.collectionPoint!),
                          if (data.facilityContactPerson != null) _buildDetailRow('Contact Person:', data.facilityContactPerson!),
                          if (data.facilityContactNumber != null) _buildDetailRow('Contact Number:', data.facilityContactNumber!),
                          if (data.commercialLaundryTypes != null && data.commercialLaundryTypes!.isNotEmpty)
                            _buildDetailRow('Laundry Types:', data.commercialLaundryTypes!.join(', ')),
                          if (data.laundryQuantityKg != null) _buildDetailRow('Estimated Weight:', '${data.laundryQuantityKg} kg'),
                          if (data.numberOfBags != null) _buildDetailRow('Number of Bags:', '${data.numberOfBags}'),
                          if (data.serviceFrequency != null) _buildDetailRow('Frequency:', data.serviceFrequency!),
                          if (data.linenHandlingType != null) _buildDetailRow(data.selectedServiceTitle == 'Hotel Laundry' ? 'Special Handling:' : 'Linen Type:', data.linenHandlingType!),
                          if (data.requestedReturnDate != null) _buildDetailRow('Return Date:', DateFormat('dd MMM yyyy').format(data.requestedReturnDate!)),
                          if (data.requestedReturnTime != null) _buildDetailRow('Return Time:', data.requestedReturnTime!.format(context)),
                        ] else ...[
                          if (data.laundryServiceMethod != null)
                            _buildDetailRow('Method:', data.laundryServiceMethod!),
                          if (data.laundryServiceType != null)
                            _buildDetailRow('Service:', data.laundryServiceType!),
                          _buildDetailRow('Estimated Quantity:', '${data.laundryQuantityKg ?? 5} kg'),
                          if (specialCareList.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Special-Care Items:', style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[600])),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Wrap(
                                    alignment: WrapAlignment.end,
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: specialCareList.map((item) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.amber.shade900.withOpacity(0.25) : const Color(0xFFFFF8E1),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: AppColors.primaryGold.withOpacity(0.4)),
                                        ),
                                        child: Text(
                                          '${item['count']}x ${item['name']}',
                                          style: AppTextStyles.bodySmall.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                            color: isDark ? AppColors.primaryGold : const Color(0xFFD97706),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                          ] else ...[
                            _buildDetailRow('Special-Care Items:', 'None'),
                          ],
                          if (data.detergentArrangement != null)
                            _buildDetailRow('Detergent:', data.detergentArrangement!),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Location, Schedule & Customer Info Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 18, color: AppColors.primaryGold),
                            const SizedBox(width: 10),
                            Text(
                              '$formattedDate • $formattedTime',
                              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on, size: 18, color: AppColors.primaryGold),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                data.location.address,
                                style: AppTextStyles.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.person, size: 18, color: AppColors.primaryGold),
                            const SizedBox(width: 10),
                            Text(
                              'Customer: ${data.userName}',
                              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        if (data.whatYouNeed != null && data.whatYouNeed!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.assignment_outlined, size: 18, color: AppColors.primaryGold),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Requirements: ${data.whatYouNeed}',
                                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[700]),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (data.describeIssue != null && data.describeIssue!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.note_alt_outlined, size: 18, color: AppColors.primaryGold),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Description: ${data.describeIssue}',
                                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[700]),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (data.uploadedImages != null && data.uploadedImages!.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              const Icon(Icons.photo_library_outlined, size: 18, color: AppColors.primaryGold),
                              const SizedBox(width: 10),
                              Text(
                                'Attached Photos (${data.uploadedImages!.length})',
                                style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 60,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: data.uploadedImages!.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(data.uploadedImages![index]),
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Price Summary Card
                  if (data.selectedServiceTitle == 'Hospital Laundry' || data.selectedServiceTitle == 'Hotel Laundry' || data.selectedServiceTitle == 'Commercial Laundry') ...[
                    QuickServicesPriceSummary(
                      bookingData: data,
                      useGoCoins: _useGoCoins,
                      onGoCoinsChanged: (val) => setState(() => _useGoCoins = val),
                    ),
                  ] else ...[
                    Text(
                      'Price Summary',
                      style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                (data.laundryPackagePrice != null && data.laundryPackagePrice! > 0)
                                    ? '${data.laundryServiceType ?? 'Service'} (${data.laundryQuantityKg ?? 5} kg x €${data.laundryPackagePrice!.toStringAsFixed(2)})'
                                    : data.laundryServiceType ?? 'Service',
                                style: AppTextStyles.bodyMedium,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              (data.laundryPackagePrice != null && data.laundryPackagePrice! > 0)
                                  ? '€${rawSubtotal.toStringAsFixed(2)}'
                                  : 'Price after inspection',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: (data.laundryPackagePrice == null || data.laundryPackagePrice == 0)
                                    ? Colors.orange[800]
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        if (data.detergentArrangement != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Detergent Charge:', style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[600])),
                              Text('Included', style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[600])),
                            ],
                          ),
                        ],
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Subtotal', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                            Text('€${rawSubtotal.toStringAsFixed(2)}', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // GO Coins Discount Box
                        
                        // ── GoCoins Redeem Section ──
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(top: 16, bottom: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _useGoCoins ? AppColors.primaryGold : (Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
                              width: _useGoCoins ? 1.5 : 0.5,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGold.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Image.asset(AssetPaths.iconGoCoin, width: 24, height: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Redeem GoCoins', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Balance: 250 Coins',
                                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                                    ),
                                    if (_useGoCoins)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          'Save €2.00 with 200 coins',
                                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryGold, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Transform.scale(
                                scale: 0.8,
                                child: Switch.adaptive(
                                  value: _useGoCoins,
                                  activeColor: AppColors.backgroundDark,
                                  activeTrackColor: AppColors.primaryGold,
                                  inactiveTrackColor: Theme.of(context).dividerTheme.color ?? AppColors.borderDark,
                                  onChanged: (val) => setState(() => _useGoCoins = val),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_useGoCoins) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text('GoCoins Discount', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryGold))),
                              Text(
                                '-€2.00',
                                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryGold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],


                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Estimated Total', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                            Text(
                              '€${estimatedTotal.toStringAsFixed(2)}',
                              style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryGold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ],

                  const SizedBox(height: 24),

                  // Confirm Booking Button
                  ElevatedButton(
                    onPressed: () {
                  final finalTotal = _bookingData.upfrontBookingFee - (_useGoCoins ? 2.0 : 0.0);
                      
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => BookingPaymentSheet(
                      currentType: _bookingData.paymentMethodType,
                      currentCardId: _bookingData.paymentMethodId,
                      isQuickService: true,
                      amount: finalTotal,
                      onConfirm: (type, {cardId}) {
                        final updatedData = _bookingData.copyWith(
                          paymentMethodType: type,
                          paymentMethodId: cardId,
                          useGoCoins: _useGoCoins,
                        );
                        context.pushNamed(
                          RouteNames.quickServicesLaundryConfirmation,
                          extra: updatedData,
                        );
                      },
                    ),
                  );
                },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text('Confirm Booking', style: AppTextStyles.button.copyWith(color: Colors.black)),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[600])),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
