import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../widgets/quick_services_header.dart';
import '../../data/models/quick_service_booking_data.dart';

class BeautyWellnessReviewScreen extends StatefulWidget {
  final QuickServiceBookingData bookingData;
  const BeautyWellnessReviewScreen({super.key, required this.bookingData});

  @override
  State<BeautyWellnessReviewScreen> createState() => _BeautyWellnessReviewScreenState();
}

class _BeautyWellnessReviewScreenState extends State<BeautyWellnessReviewScreen> {
  bool _useGoCoins = false;

  final Map<String, double> _treatmentPrices = {
    'Haircut & Styling': 25.0,
    'Hair Colouring': 45.0,
    'Facial Treatment': 30.0,
    'Manicure': 20.0,
    'Pedicure': 25.0,
    'Waxing': 15.0,
    'Threading': 10.0,
    'Makeup Service': 35.0,
    'Massage & Relaxation': 40.0,
    "Men's Grooming": 20.0,
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final data = widget.bookingData;

    final String formattedDate = DateFormat('dd MMM yyyy').format(data.scheduleDate);
    final String formattedTime = data.scheduleTime.format(context);

    final selectedTreatments = data.beautySelectedTreatments ?? [];
    final peopleCount = data.peopleCount ?? 1;

    double subtotal = 0.0;
    for (final t in selectedTreatments) {
      subtotal += (_treatmentPrices[t] ?? 0.0);
    }
    subtotal *= peopleCount;

    final double goCoinsDiscount = _useGoCoins ? 2.0 : 0.0;
    final double estimatedTotal = (subtotal - goCoinsDiscount).clamp(0.0, double.infinity);

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
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selected Services Card
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
                              child: const Icon(Icons.spa, color: AppColors.primaryGold, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Beauty & Wellness',
                                style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),

                        Text(
                          'Selected Services',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),

                        ...selectedTreatments.map((treatment) {
                          final price = _treatmentPrices[treatment] ?? 0.0;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(treatment, style: AppTextStyles.bodyMedium),
                                ),
                                Text(
                                  price > 0 ? '€${price.toStringAsFixed(0)}' : 'Inspection',
                                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          );
                        }),

                        const SizedBox(height: 8),
                        _buildDetailRow('Number of People', '$peopleCount'),
                        _buildDetailRow('Professional Preference', data.professionalPreference ?? 'Any Professional'),
                        _buildDetailRow('Date & Time', '$formattedDate • $formattedTime', icon: Icons.calendar_today_outlined),
                        _buildDetailRow('Address', data.location.address.isNotEmpty ? data.location.address : '8 Triq Santa Rita, Sliema, Malta', icon: Icons.location_on_outlined),
                        _buildDetailRow('Customer', data.userName.isNotEmpty ? data.userName : 'Justin Camilleri', icon: Icons.person_outline),
                        
                        if (data.whatYouNeed != null && data.whatYouNeed!.isNotEmpty)
                          _buildDetailRow('Tell Us', data.whatYouNeed!, icon: Icons.note_outlined),
                        if (data.describeIssue != null && data.describeIssue!.isNotEmpty)
                          _buildDetailRow('Description', data.describeIssue!, icon: Icons.description_outlined),

                        if (data.uploadedImages != null && data.uploadedImages!.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              const Icon(Icons.photo_library_outlined, size: 18, color: AppColors.primaryGold),
                              const SizedBox(width: 10),
                              Text(
                                'Reference Photos (${data.uploadedImages!.length})',
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
                                return Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  width: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.primaryGold.withOpacity(0.5)),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(data.uploadedImages![index]),
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx, err, stack) => const Icon(Icons.image, size: 24, color: Colors.grey),
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
                        ...selectedTreatments.map((treatment) {
                          final price = (_treatmentPrices[treatment] ?? 0.0) * peopleCount;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(treatment, style: AppTextStyles.bodyMedium),
                                Text(
                                  price > 0 ? '€${price.toStringAsFixed(2)}' : 'Inspection',
                                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          );
                        }),

                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Subtotal', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                            Text('€${subtotal.toStringAsFixed(2)}', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // GO Coins Discount Box
                        GestureDetector(
                          onTap: () => setState(() => _useGoCoins = !_useGoCoins),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[850] : const Color(0xFFFFF8E1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _useGoCoins ? AppColors.primaryGold : Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: _useGoCoins,
                                  activeColor: AppColors.primaryGold,
                                  onChanged: (val) => setState(() => _useGoCoins = val ?? false),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('GO Coins: 250 available', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                                    Text('Use 200 GO Coins', style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[700])),
                                  ],
                                ),
                                const Spacer(),
                                Text('-€2.00', style: AppTextStyles.bodySmall.copyWith(color: Colors.green, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),

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
                        const SizedBox(height: 14),

                        // PAY AFTER SERVICE Badge
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Text(
                            'PAY AFTER SERVICE',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Confirm Booking Button
                  ElevatedButton(
                    onPressed: () {
                      final finalData = data.copyWith(
                        subtotal: estimatedTotal,
                      );
                      context.pushNamed(
                        RouteNames.quickServicesBeautyWellnessConfirmation,
                        extra: finalData,
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
                    child: Text(
                      'CONFIRM BOOKING',
                      style: AppTextStyles.button.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
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

  Widget _buildDetailRow(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.primaryGold),
            const SizedBox(width: 8),
          ],
          Text('$label:', style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[600])),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
