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

class PestControlReviewScreen extends ConsumerStatefulWidget {
  final QuickServiceBookingData bookingData;

  const PestControlReviewScreen({super.key, required this.bookingData});

  @override
  ConsumerState<PestControlReviewScreen> createState() => _PestControlReviewScreenState();
}

class _PestControlReviewScreenState extends ConsumerState<PestControlReviewScreen> {
  late QuickServiceBookingData _bookingData;
  bool _useCoins = false;

  @override
  void initState() {
    super.initState();
    _bookingData = widget.bookingData;
  }

  bool _useGoCoins = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final booking = _bookingData;

    final pestType = booking.pestType ?? 'Not selected';
    final propertyType = booking.propertyType ?? 'Not selected';
    final affectedAreas = booking.pestAffectedAreas?.join(', ') ?? 'None';
    final rooms = booking.pestAffectedRooms?.toString() ?? '1';
    final observedLevel = booking.pestObservedLevel ?? 'Not selected';
    final childrenOrPets = booking.childrenOrPets ?? 'Not selected';
    final description = booking.describeIssue ?? '';

    final String dateStr =
        '${booking.scheduleDate.day} ${_monthName(booking.scheduleDate.month)} ${booking.scheduleDate.year}';
    final String timeStr = booking.scheduleTime.format(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const QuickServicesHeader(
            title: 'Review & Book',
            subtitle: 'Pest Control',
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
                              child: const Icon(Icons.bug_report, color: Colors.black, size: 20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        _buildSummaryItem('Pest Type', pestType),
                        _buildSummaryItem('Property Type', propertyType),
                        _buildSummaryItem('Affected Areas', affectedAreas),
                        _buildSummaryItem('Affected Rooms', rooms),
                        _buildSummaryItem('Observed Level', observedLevel),
                        _buildSummaryItem('Children/Pets', childrenOrPets),
                        
                        if (description.isNotEmpty) ...[
                          const Divider(height: 24),
                          Text(
                            'Problem Description',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                        
                        // Uploaded Images
                        if (booking.uploadedImages != null && booking.uploadedImages!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Photos Provided',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 60,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: booking.uploadedImages!.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  width: 60,
                                  height: 60,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: FileImage(File(booking.uploadedImages![index])),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],

                        const Divider(height: 32),

                        // Date & Time
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Date',
                                    style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    dateStr,
                                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 40, color: Colors.grey[300]),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Time',
                                      style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[600]),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      timeStr,
                                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 32),

                        // Location
                        Text(
                          'Location',
                          style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: AppColors.primaryGold, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                booking.location.address,
                                style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w500),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Payment Section
                  QuickServicesPriceSummary(bookingData: booking),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          
          // Bottom Bar
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: QuickServicesPaymentSelector(
              bookingData: _bookingData,
              onChanged: (newData) {
                setState(() {
                  _bookingData = newData;
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Consumer(
              builder: (context, ref, child) {
                final rewardSummary = ref.watch(rewardSummaryProvider).value;
                final int balance = rewardSummary?.currentPoints.toInt() ?? 0;
                final int conversionRate = (ref.watch(rewardRulesProvider).value?.redemption.pointsToEurRatio ?? 400.0).toInt();
                
                final double maxEurValue = balance / conversionRate;
                final double appliedEurValue = maxEurValue > _bookingData.estimatedTotalMax ? _bookingData.estimatedTotalMax : maxEurValue;
                final int coinsUsed = (appliedEurValue * conversionRate).round();

                return GestureDetector(
                  onTap: () => setState(() => _useCoins = !_useCoins),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _useCoins ? AppColors.primaryGold.withValues(alpha: 0.1) : Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _useCoins ? AppColors.primaryGold : (Theme.of(context).dividerTheme.color ?? AppColors.borderDark), width: _useCoins ? 1.5 : 0.5),
                    ),
                    child: Row(
                      children: [
                        Image.asset(AssetPaths.iconGoCoin, width: 24, height: 24),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('GO Coins: $balance available', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                              Text('Use $coinsUsed GO Coins', style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[700])),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (appliedEurValue > 0)
                          Text('-€${appliedEurValue.toStringAsFixed(2)}', style: AppTextStyles.bodySmall.copyWith(color: Colors.green, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Checkbox(
                          value: _useCoins,
                          onChanged: (val) => setState(() => _useCoins = val ?? false),
                          activeColor: AppColors.primaryGold,
                          checkColor: Colors.black,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
 SafeArea(
              top: false,
              child: ElevatedButton(
                onPressed: () {
                  context.pushNamed(RouteNames.quickServicesPestControlConfirmation, extra: booking);
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
            ),
          ],
          ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[600]),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
