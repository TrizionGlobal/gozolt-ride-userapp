import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../data/models/quick_service_booking_data.dart';
import '../widgets/quick_services_header.dart';

class HomeElectricReviewScreen extends StatelessWidget {
  final QuickServiceBookingData bookingData;

  const HomeElectricReviewScreen({super.key, required this.bookingData});

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const QuickServicesHeader(
            title: 'Review & Book',
          ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                  Icons.bolt,
                                  color: Color(0xFFF57F17),
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            bookingData.selectedServiceTitle ?? 'Electrical Services',
                            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          if (bookingData.selectedAddons.isNotEmpty) ...[
                            ...bookingData.selectedAddons.map(
                              (addon) => Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '• ${addon.name}',
                                      style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade800),
                                    ),
                                    Text(
                                      '×${addon.count}',
                                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ] else ...[
                            Text(
                              '• Electrical Inspection / Repair',
                              style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade700),
                            ),
                          ],
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

                    // Pricing Information Card
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
                            'Pricing Information',
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF324461),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Visit / Inspection Fee', style: AppTextStyles.bodyMedium),
                              Text('€15.00', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Estimated Labour', style: AppTextStyles.bodyMedium),
                              Text('€40 - €85', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Materials / Spare Parts', style: AppTextStyles.bodyMedium),
                              Text('Not Included', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey)),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Estimated Total', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                              Text(
                                '€${bookingData.estimatedTotal.toStringAsFixed(2)}',
                                style: AppTextStyles.titleSmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryGold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Final quote will be provided after on-site inspection.',
                            style: AppTextStyles.bodySmall.copyWith(color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.pushNamed(RouteNames.quickServicesElectricalConfirmation, extra: bookingData);
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
                      'CONFIRM BOOKING',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
