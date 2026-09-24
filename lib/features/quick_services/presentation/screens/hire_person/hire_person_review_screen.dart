import '../../providers/quick_services_booking_provider.dart';
import '../../../../../core/widgets/booking_payment_sheet.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/quick_services_payment_selector.dart';
import '../../../../rewards/presentation/providers/rewards_providers.dart';
import '../../../../../core/constants/asset_paths.dart';

import 'package:go_router/go_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/router/route_names.dart';
import '../../../data/models/quick_service_booking_data.dart';
import '../../widgets/quick_services_price_summary.dart';
import '../../widgets/quick_services_header.dart';
import '../../widgets/quick_services_booking_summary.dart';
import '../../widgets/quick_services_additional_details_review.dart';
import '../../../../ride/data/models/saved_payment_method.dart';


class HirePersonReviewScreen extends ConsumerStatefulWidget {
  const HirePersonReviewScreen({
    super.key,
    required this.bookingData,
  });

  final QuickServiceBookingData bookingData;

  @override
  ConsumerState<HirePersonReviewScreen> createState() => _HirePersonReviewScreenState();
}

class _HirePersonReviewScreenState extends ConsumerState<HirePersonReviewScreen> {
  bool _useGoCoins = false;
  bool _isBooking = false;
  late QuickServiceBookingData _bookingData;
  bool _useCoins = false;

  @override
  void initState() {
    super.initState();
    _bookingData = widget.bookingData;
  }

  @override
  Widget build(BuildContext context) {
    final hours = _getDurationHours(_bookingData.expectedDuration);
    final helpers = _bookingData.helperCount ?? 1;
    final hourlyRate = 14.00;
    final totalLabour = hours * hourlyRate * helpers;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const QuickServicesHeader(
            currentStep: 2,
            title: 'Review & Book',
            subtitle: 'Hire Person',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  QuickServicesBookingSummary(
                    bookingData: _bookingData,
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 12),

                  // Service Summary Card
                  Container(
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Service', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade700)),
                            Text('Hire a Person', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Helper', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade700)),
                            Text('$helpers ${helpers == 1 ? "Helper" : "Helpers"}', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Gender Preference', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade700)),
                            Text(_bookingData.genderPreference ?? 'Any', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Duration', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade700)),
                            Text(_bookingData.expectedDuration ?? '2 Hours', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        if ((_bookingData.describeIssue != null && _bookingData.describeIssue!.isNotEmpty) ||
                            (_bookingData.uploadedImages != null && _bookingData.uploadedImages!.isNotEmpty)) ...[
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 12),
                          if (_bookingData.describeIssue != null && _bookingData.describeIssue!.isNotEmpty) ...[
                            Text(
                              'Issue Description',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _bookingData.describeIssue!,
                              style: AppTextStyles.bodyMedium,
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (_bookingData.uploadedImages != null && _bookingData.uploadedImages!.isNotEmpty) ...[
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
                                itemCount: _bookingData.uploadedImages!.length,
                                itemBuilder: (context, index) {
                                  final path = _bookingData.uploadedImages![index];
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
                    bookingData: _bookingData, 
                    useGoCoins: _useGoCoins, 
                    onGoCoinsChanged: (val) => setState(() => _useGoCoins = val),
                    showAdditionalDetails: false,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          const SizedBox(height: 16),

          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
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
                        context.pushNamed(RouteNames.quickServicesHirePersonConfirmation, extra: updatedData.copyWith(bookingId: bookingId));
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
                              context.pushNamed(RouteNames.quickServicesHirePersonConfirmation, extra: updatedData.copyWith(bookingId: bookingId));
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isBooking ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : Text('Confirm Booking', style: AppTextStyles.button.copyWith(color: Colors.black)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }

  int _getDurationHours(String? duration) {
    if (duration == null) return 2;
    final match = RegExp(r'\d+').firstMatch(duration);
    if (match != null) {
      return int.parse(match.group(0)!);
    }
    return 2;
  }
}
