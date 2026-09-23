import '../../../providers/quick_services_booking_provider.dart';
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
import '../../widgets/quick_services_booking_summary.dart';
import '../../../../ride/data/models/saved_payment_method.dart';


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
  bool _isBooking = false;

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
          QuickServicesHeader(
            currentStep: 2,
            title: 'Review Booking',
            subtitle: (data.selectedServiceTitle ?? 'Home').toLowerCase().endsWith('laundry') ? data.selectedServiceTitle! : '${data.selectedServiceTitle ?? 'Home'} Laundry',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service Overview Card
                  QuickServicesBookingSummary(
                    bookingData: data,
                    icon: Icons.local_laundry_service_outlined,
                  ),
                  const SizedBox(height: 12),

                  // Service Summary Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGold.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.assignment_outlined,
                                color: AppColors.primaryGold,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Service Summary',
                              style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (data.selectedServiceTitle == 'Hospital Laundry' || data.selectedServiceTitle == 'Hotel Laundry' || data.selectedServiceTitle == 'Commercial Laundry') ...[
                          if (data.facilityName != null) _buildDetailRow(data.selectedServiceTitle == 'Commercial Laundry' ? 'Business Name' : (data.selectedServiceTitle == 'Hotel Laundry' ? 'Hotel Name' : 'Facility Name'), data.facilityName!),
                          if (data.businessType != null) _buildDetailRow('Business Type', data.businessType!),
                          if (data.collectionPoint != null) _buildDetailRow('Collection Point', data.collectionPoint!),
                          if (data.facilityContactPerson != null) _buildDetailRow('Contact Person', data.facilityContactPerson!),
                          if (data.facilityContactNumber != null) _buildDetailRow('Contact Number', data.facilityContactNumber!),
                          if (data.commercialLaundryTypes != null && data.commercialLaundryTypes!.isNotEmpty)
                            _buildDetailRow('Laundry Types', data.commercialLaundryTypes!.join(', ')),
                          if (data.serviceFrequency != null) _buildDetailRow('Frequency', data.serviceFrequency!),
                          if (data.requestedReturnDate != null) _buildDetailRow('Return Date', DateFormat('dd MMM yyyy').format(data.requestedReturnDate!)),
                          if (data.requestedReturnTime != null) _buildDetailRow('Return Time', data.requestedReturnTime!.format(context)),
                        ] else ...[
                          if (data.laundryServiceMethod != null)
                            _buildDetailRow('Method', data.laundryServiceMethod!),
                          if (data.requestedReturnDate != null) _buildDetailRow('Return Date', DateFormat('dd MMM yyyy').format(data.requestedReturnDate!)),
                          if (data.requestedReturnTime != null) _buildDetailRow('Return Time', data.requestedReturnTime!.format(context)),
                          if (data.laundryServiceType != null)
                            _buildDetailRow('Service', data.laundryServiceType!),
                          _buildDetailRow('Estimated Quantity', '${data.laundryQuantityKg ?? 1} kg'),
                          if (specialCareList.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Special-Care Items', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade700)),
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
                            _buildDetailRow('Special-Care Items', 'None'),
                          ],
                        ],

                        if ((data.whatYouNeed != null && data.whatYouNeed!.isNotEmpty) ||
                            (data.describeIssue != null && data.describeIssue!.isNotEmpty) ||
                            (data.uploadedImages != null && data.uploadedImages!.isNotEmpty)) ...[
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 12),
                          if (data.whatYouNeed != null && data.whatYouNeed!.isNotEmpty) ...[
                            Text(
                              'Requirements',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data.whatYouNeed!,
                              style: AppTextStyles.bodyMedium,
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (data.describeIssue != null && data.describeIssue!.isNotEmpty) ...[
                            Text(
                              'Issue Description',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data.describeIssue!,
                              style: AppTextStyles.bodyMedium,
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (data.uploadedImages != null && data.uploadedImages!.isNotEmpty) ...[
                            Text(
                              'Uploaded Photos',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 70,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: data.uploadedImages!.length,
                                itemBuilder: (context, index) {
                                  final path = data.uploadedImages![index];
                                  return Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    width: 70,
                                    height: 70,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        File(path),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Pricing Details Card
                  QuickServicesPriceSummary(
                    bookingData: data, 
                    useGoCoins: _useGoCoins, 
                    onGoCoinsChanged: (val) => setState(() => _useGoCoins = val),
                    showAdditionalDetails: false,
                  ),

                  const SizedBox(height: 24),

                  // Confirm Booking Button
                  ElevatedButton(
                    onPressed: _isBooking ? null : () async {

                  final finalTotal = ((_bookingData.upfrontBookingFee + _bookingData.materialCost) - (_useGoCoins ? (_bookingData.upfrontBookingFee + _bookingData.materialCost).clamp(0.0, 6.0) : 0.0)).clamp(0.0, double.infinity);
                      
                  if (finalTotal <= 0.0) {
                    final updatedData = _bookingData.copyWith(
                      paymentMethodType: PaymentMethodType.cash,
                      useGoCoins: _useGoCoins,
                    );
                    
                      setState(() => _isBooking = true);
                      final bookingId = await ref.read(quickServicesBookingProvider.notifier).bookQuickService(updatedData);
                      if (mounted) setState(() => _isBooking = false);
                      if (bookingId != null && mounted) {
                        context.pushNamed(RouteNames.quickServicesLaundryConfirmation, extra: updatedData);
                      } else {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to book service')));
                      }
                    } else {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => BookingPaymentSheet(
                          currentType: _bookingData.paymentMethodType,
                          currentCardId: _bookingData.paymentMethodId,
                          isQuickService: true,
                          amount: finalTotal,
                          onConfirm: (type, {cardId}) async {
                            final updatedData = _bookingData.copyWith(
                            paymentMethodType: type,
                            paymentMethodId: cardId,
                            useGoCoins: _useGoCoins,
                          );
                            final bookingId = await ref.read(quickServicesBookingProvider.notifier).bookQuickService(updatedData);
                            if (bookingId != null && mounted) {
                              context.pushNamed(RouteNames.quickServicesLaundryConfirmation, extra: updatedData);
                              return true;
                            } else {
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to book service')));
                              return false;
                            }
                          },
                        ),
                      );
                    }
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
                    child: _isBooking ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : Text('Confirm Booking', style: AppTextStyles.button.copyWith(color: Colors.black)),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade700)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
