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

class GardeningReviewScreen extends ConsumerStatefulWidget {
  final QuickServiceBookingData bookingData;

  const GardeningReviewScreen({super.key, required this.bookingData});

  @override
  ConsumerState<GardeningReviewScreen> createState() => _GardeningReviewScreenState();
}

class _GardeningReviewScreenState extends ConsumerState<GardeningReviewScreen> {
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
    final booking = _bookingData;

    final serviceArea = booking.gardeningServiceArea ?? 'Not selected';
    final approxArea = booking.gardeningApproximateArea ?? 'Not selected';
    final wasteRemoval = booking.greenWasteRemoval ?? 'Not selected';

    final String dateStr =
        '${booking.scheduleDate.day} ${_monthName(booking.scheduleDate.month)} ${booking.scheduleDate.year}';
    final String timeStr = booking.scheduleTime.format(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const QuickServicesHeader(
            currentStep: 2,
            title: 'Review & Book',
            subtitle: 'Gardening',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Booking Summary Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[850] : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Booking Summary',
                              style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGold.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.yard_outlined, color: Colors.black, size: 20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Services list
                        Text(
                          'Services',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (booking.selectedAddons.isEmpty)
                          Text(
                            '• None Selected',
                            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: Colors.grey),
                          )
                        else
                          ...booking.selectedAddons.map((addon) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(
                                '• ${addon.name}${addon.count > 1 ? ' x${addon.count}' : ''}',
                                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                              ),
                            );
                          }),
                        const SizedBox(height: 12),

                        // Area
                        Row(
                          children: [
                            Text(
                              'Area: ',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '$serviceArea • $approxArea',
                              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Waste Removal
                        Row(
                          children: [
                            Text(
                              'Waste Removal: ',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              wasteRemoval,
                              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const Divider(height: 24),

                        // Date & Time
                        Row(
                          children: [
                            const Icon(Icons.calendar_month, size: 18, color: AppColors.primaryGold),
                            const SizedBox(width: 10),
                            Text(
                              '$dateStr • $timeStr',
                              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Location
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on, size: 18, color: AppColors.primaryGold),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                booking.location.address,
                                style: AppTextStyles.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Customer Details
                        Row(
                          children: [
                            const Icon(Icons.person, size: 18, color: AppColors.primaryGold),
                            const SizedBox(width: 10),
                            Text(
                              booking.userName,
                              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),

                        // What You Need if present
                        if (booking.whatYouNeed != null && booking.whatYouNeed!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            'What you need',
                            style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            booking.whatYouNeed!,
                            style: AppTextStyles.bodySmall,
                          ),
                        ],

                        // Description if present
                        if (booking.describeIssue != null && booking.describeIssue!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Issue description',
                            style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            booking.describeIssue!,
                            style: AppTextStyles.bodySmall,
                          ),
                        ],

                        // Uploaded Photos if present
                        if (booking.uploadedImages != null && booking.uploadedImages!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Attached Photos (${booking.uploadedImages!.length})',
                            style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 60,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: booking.uploadedImages!.length,
                              itemBuilder: (context, index) {
                                final path = booking.uploadedImages![index];
                                return Container(
                                  width: 60,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: FileImage(File(path)),
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
                  QuickServicesPriceSummary(bookingData: _bookingData, useGoCoins: _useGoCoins, onGoCoinsChanged: (val) => setState(() => _useGoCoins = val),),
                  const SizedBox(height: 16),

                  
                  const SizedBox(height: 16),

                  // CONFIRM BOOKING Button
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
                          RouteNames.quickServicesGardeningConfirmation,
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text('Confirm Booking', style: AppTextStyles.button.copyWith(color: Colors.black)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[600]),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
