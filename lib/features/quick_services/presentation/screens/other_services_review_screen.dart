import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../data/models/quick_service_booking_data.dart';
import '../widgets/quick_services_header.dart';

class OtherServicesReviewScreen extends StatefulWidget {
  final QuickServiceBookingData bookingData;

  const OtherServicesReviewScreen({super.key, required this.bookingData});

  @override
  State<OtherServicesReviewScreen> createState() => _OtherServicesReviewScreenState();
}

class _OtherServicesReviewScreenState extends State<OtherServicesReviewScreen> {
  bool useCoins = false;

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final bookingData = widget.bookingData;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const QuickServicesHeader(title: 'Review & Book'),
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
                        if (bookingData.paintingType != null)
                          Text('• Painting Type: ${bookingData.paintingType}', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade800)),
                        if (bookingData.roomCount != null)
                          Text('• Number of Rooms: ${bookingData.roomCount}', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade800)),
                        if (bookingData.paintProvided != null)
                          Text('• Paint Provided: ${bookingData.paintProvided! ? 'Yes' : 'No'}', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade800)),
                        
                        if (bookingData.eventType != null)
                          Text('• Event Type: ${bookingData.eventType}', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade800)),
                        if (bookingData.guestCount != null)
                          Text('• Estimated Guests: ${bookingData.guestCount}', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade800)),
                        if (bookingData.eventDuration != null)
                          Text('• Duration: ${bookingData.eventDuration}', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade800)),

                        if (bookingData.supplyType != null)
                          Text('• Supply Type: ${bookingData.supplyType}', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade800)),
                        if (bookingData.supplyScale != null)
                          Text('• Scale: ${bookingData.supplyScale}', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade800)),

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
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Pricing Details Card
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
                        Text(
                          'Pricing Details',
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF324461),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Estimated Subtotal',
                              style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade800),
                            ),
                            Text(
                              '€${bookingData.subtotal.toStringAsFixed(2)}',
                              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Final price may vary based on exact requirements and duration.',
                                  style: AppTextStyles.bodySmall.copyWith(color: Colors.grey.shade600),
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
            ),
          ),
          
          // Bottom Bar
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Estimated Total',
                          style: AppTextStyles.bodySmall.copyWith(color: Colors.grey.shade600),
                        ),
                        Text(
                          '€${bookingData.estimatedTotal.toStringAsFixed(2)}',
                          style: AppTextStyles.titleLarge.copyWith(
                            color: AppColors.primaryGold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        context.pushNamed(
                          RouteNames.quickServicesOtherServicesConfirmation,
                          extra: bookingData,
                        );
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
                      child: const Text(
                        'Confirm Booking',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
