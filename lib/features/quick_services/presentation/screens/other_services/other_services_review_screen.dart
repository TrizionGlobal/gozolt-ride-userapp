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
import '../../../../ride/data/models/saved_payment_method.dart';


class OtherServicesReviewScreen extends ConsumerStatefulWidget {
  final QuickServiceBookingData bookingData;

  const OtherServicesReviewScreen({super.key, required this.bookingData});

  @override
  ConsumerState<OtherServicesReviewScreen> createState() => _OtherServicesReviewScreenState();
}

class _OtherServicesReviewScreenState extends ConsumerState<OtherServicesReviewScreen> {
  bool _useGoCoins = false;
  bool _isBooking = false;
  late QuickServiceBookingData _bookingData;
  bool _useCoins = false;

  @override
  void initState() {
    super.initState();
    _bookingData = widget.bookingData;
  }

  bool useCoins = false;

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final bookingData = _bookingData;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const QuickServicesHeader(
            currentStep: 2,title: 'Review & Book', subtitle: 'Other Services'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Service Summary',
                              style: AppTextStyles.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF324461),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFF8E1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.settings,
                                color: Color(0xFFF57F17),
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          bookingData.selectedServiceTitle ?? 'Other Services',
                          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        
                        // Dynamic details based on service type
                        if (bookingData.propertyType != null)
                          Text('• Property Type: ${bookingData.propertyType}', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade800)),
                        if (bookingData.paintingAreas != null && bookingData.paintingAreas!.isNotEmpty)
                          Text('• Areas: ${bookingData.paintingAreas!.join(", ")}', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade800)),
                        if (bookingData.roomCount != null)
                          Text('• Number of Rooms/Areas: ${bookingData.roomCount}', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade800)),
                        if (bookingData.paintProvided != null)
                          Text('• Paint Provided By: ${bookingData.paintProvided! ? 'Painter Brings Paint' : 'Customer Provides Paint'}', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade800)),
                        
                        if (bookingData.eventType != null)
                          Text('• Event Type: ${bookingData.eventType}', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade800)),
                        if (bookingData.guestCount != null)
                          Text('• Estimated Guests: ${bookingData.guestCount}', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade800)),
                        if (bookingData.eventDuration != null)
                          Text('• Duration: ${bookingData.eventDuration}', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade800)),

                        if (bookingData.supplyCategory != null)
                          Text('• Category: ${bookingData.supplyCategory}', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade800)),
                        if (bookingData.itemRequired != null)
                          Text('• Item: ${bookingData.itemRequired}', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade800)),
                        if (bookingData.supplyQuantity != null && bookingData.supplyUnit != null)
                          Text('• Quantity: ${bookingData.supplyQuantity} ${bookingData.supplyUnit}', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade800)),
                        if (bookingData.requestType != null)
                          Text('• Type: ${bookingData.requestType}', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade800)),

                        const Divider(height: 24),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              '${_formatDate(bookingData.scheduleDate)} • ${bookingData.scheduleTime.format(context)}',
                              style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade800),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                bookingData.location.address,
                                style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade800),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${bookingData.userName} • ${bookingData.userPhone}',
                                style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade800),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Additional Details Section
                  if ((bookingData.whatYouNeed != null && bookingData.whatYouNeed!.isNotEmpty) ||
                      (bookingData.describeIssue != null && bookingData.describeIssue!.isNotEmpty) ||
                      (bookingData.requirementDescription != null && bookingData.requirementDescription!.isNotEmpty) ||
                      (bookingData.uploadedImages != null && bookingData.uploadedImages!.isNotEmpty)) ...[
                    Text(
                      'Additional Details',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF324461),
                      ),
                    ),
                    const SizedBox(height: 8),
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
                          if (bookingData.whatYouNeed != null && bookingData.whatYouNeed!.isNotEmpty) ...[
                            Text(
                              'What You Need',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              bookingData.whatYouNeed!,
                              style: AppTextStyles.bodyMedium,
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (bookingData.describeIssue != null && bookingData.describeIssue!.isNotEmpty) ...[
                            Text(
                              'Issue Description',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              bookingData.describeIssue!,
                              style: AppTextStyles.bodyMedium,
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (bookingData.requirementDescription != null && bookingData.requirementDescription!.isNotEmpty) ...[
                            Text(
                              'Requirement Description',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              bookingData.requirementDescription!,
                              style: AppTextStyles.bodyMedium,
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (bookingData.uploadedImages != null && bookingData.uploadedImages!.isNotEmpty) ...[
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
                                itemCount: bookingData.uploadedImages!.length,
                                itemBuilder: (context, index) {
                                  final path = bookingData.uploadedImages![index];
                                  return Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    width: 70,
                                    height: 70,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: path.startsWith('http')
                                                ? Image.network(path, fit: BoxFit.cover,)
                                                : Image.file(File(path), fit: BoxFit.cover,),
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
                  ],

                  // Pricing Details Card
                  QuickServicesPriceSummary(bookingData: _bookingData, useGoCoins: _useGoCoins, onGoCoinsChanged: (val) => setState(() => _useGoCoins = val),),
                ],
              ),
            ),
          ),
          
          // Bottom Bar
          
          const SizedBox(height: 16),
          
          const SizedBox(height: 16),

          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
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
                        context.pushNamed(RouteNames.quickServicesOtherServicesConfirmation, extra: updatedData.copyWith(bookingId: bookingId));
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
                              context.pushNamed(RouteNames.quickServicesOtherServicesConfirmation, extra: updatedData.copyWith(bookingId: bookingId));
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
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
}
