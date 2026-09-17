import '../../../../../core/widgets/booking_payment_sheet.dart';
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
import '../../../data/models/quick_service_booking_data.dart';
import '../../widgets/quick_services_price_summary.dart';
import '../../widgets/quick_services_header.dart';

class SecurityPersonnelReviewScreen extends ConsumerStatefulWidget {
  final QuickServiceBookingData bookingData;

  const SecurityPersonnelReviewScreen({super.key, required this.bookingData});

  @override
  ConsumerState<SecurityPersonnelReviewScreen> createState() => _SecurityPersonnelReviewScreenState();
}

class _SecurityPersonnelReviewScreenState extends ConsumerState<SecurityPersonnelReviewScreen> {
  late QuickServiceBookingData _bookingData;
  bool _useCoins = false;

  @override
  void initState() {
    super.initState();
    _bookingData = widget.bookingData;
  }

  bool _useGoCoins = false;

  double get _coinDiscount => _useGoCoins ? 2.00 : 0.00;

  int _calculateHours(String? startStr, String? endStr) {
    if (startStr == null || endStr == null) return 5;
    try {
      final startParts = startStr.split(':');
      final endParts = endStr.split(':');
      int startMins = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      int endMins = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
      if (endMins <= startMins) endMins += 24 * 60;
      int diff = (endMins - startMins) ~/ 60;
      return diff > 0 ? diff : 1;
    } catch (_) {
      return 5;
    }
  }

  (double, double) _getHourlyRateRange(String? service) {
    switch (service) {
      case 'Personal Security':
        return (30.0, 45.0);
      case 'Bouncer / Door Security':
        return (18.0, 25.0);
      case 'Crowd Management':
        return (16.0, 22.0);
      case 'Property / Site Guard':
        return (14.0, 20.0);
      case 'Venue Access Control':
        return (15.0, 20.0);
      case 'Event Security':
      default:
        return (15.0, 22.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMM yyyy').format(_bookingData.scheduleDate);
    final timeStr = _bookingData.scheduleTime.format(context);
    final addressStr = _bookingData.location.address;

    final serviceName = _bookingData.securityService ?? 'Event Security';
    final venueName = _bookingData.venueType ?? 'Corporate Event';
    final personnelCount = _bookingData.personnelCount ?? 2;
    final startTime = _bookingData.dutyStartTime ?? '18:00';
    final endTime = _bookingData.dutyEndTime ?? '23:00';
    final area = _bookingData.serviceArea ?? 'Indoor';
    final dress = _bookingData.dressPreference ?? 'Security Uniform';
    final alcohol = _bookingData.alcoholServed ?? 'Yes';
    final dutyInstructions = _bookingData.describeIssue ?? '';

    final durationHours = _calculateHours(startTime, endTime);
    final (minRate, maxRate) = _getHourlyRateRange(serviceName);
    final minPrice = (personnelCount * durationHours * minRate).toInt();
    final maxPrice = (personnelCount * durationHours * maxRate).toInt();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const QuickServicesHeader(
            title: 'Review & Book',
            subtitle: 'Security Personnel',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              physics: const BouncingScrollPhysics(),
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
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFF8E1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.security,
                                color: Color(0xFFF57F17),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Security Personnel',
                                style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),

                        _buildDetailRow('Service:', serviceName),
                        _buildDetailRow('Venue:', venueName),
                        _buildDetailRow('Personnel:', '$personnelCount'),
                        _buildDetailRow('Duty:', '$startTime–$endTime • $durationHours Hours'),
                        _buildDetailRow('Area:', area),
                        _buildDetailRow('Dress:', dress),
                        _buildDetailRow('Alcohol Served:', alcohol),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Date & Location Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_month_outlined, size: 20, color: Colors.grey),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '$dateStr • $timeStr',
                                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on_outlined, size: 20, color: Colors.grey),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                addressStr,
                                style: AppTextStyles.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Customer Details Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person_outline, size: 20, color: Colors.grey),
                            const SizedBox(width: 10),
                            Text(
                              'Customer: ${_bookingData.userName}',
                              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        if (dutyInstructions.isNotEmpty) ...[
                          const Divider(height: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Duty Instructions',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dutyInstructions,
                                style: AppTextStyles.bodyMedium,
                              ),
                            ],
                          ),
                        ],
                        const Divider(height: 24),
                          
                          if (_bookingData.whatYouNeed != null && _bookingData.whatYouNeed!.isNotEmpty) ...[
                            Text('Tell us what you need', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(_bookingData.whatYouNeed!, style: AppTextStyles.bodyMedium),
                            const SizedBox(height: 16),
                          ],

                          if (_bookingData.uploadedImages != null &&
                            _bookingData.uploadedImages!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 60,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _bookingData.uploadedImages!.length,
                              itemBuilder: (context, index) {
                                final imgPath = _bookingData.uploadedImages![index];
                                return Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  width: 60,
                                  height: 60,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      imgPath,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: Colors.grey.shade300,
                                        child: const Icon(Icons.image, color: Colors.grey),
                                      ),
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

                  const SizedBox(height: 16),

                  // Price Summary Card
                  QuickServicesPriceSummary(bookingData: _bookingData, useGoCoins: _useGoCoins, onGoCoinsChanged: (val) => setState(() => _useGoCoins = val),),

                  const SizedBox(height: 16),

                  const SizedBox(height: 16),

                  // Payment Method Badge
                  

                  const SizedBox(height: 16),

                  // Confirm Booking Button
                  ElevatedButton(
                    onPressed: () {
                  final finalTotal = _bookingData.hasRateRange
                      ? _bookingData.estimatedTotalMax - (_useGoCoins ? 2.0 : 0.0)
                      : _bookingData.estimatedTotalMin - (_useGoCoins ? 2.0 : 0.0);
                      
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
                        );
                        context.pushNamed(
                          RouteNames.quickServicesSecurityPersonnelConfirmation,
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
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
