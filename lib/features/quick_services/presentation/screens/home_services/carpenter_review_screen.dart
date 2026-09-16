import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/quick_services_payment_selector.dart';
import '../../../../rewards/presentation/providers/rewards_providers.dart';
import '../../../../../core/constants/asset_paths.dart';

import 'package:go_router/go_router.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../widgets/quick_services_header.dart';
import '../../../data/models/quick_service_booking_data.dart';
import '../../widgets/quick_services_price_summary.dart';

class CarpenterReviewScreen extends ConsumerStatefulWidget {
  final QuickServiceBookingData bookingData;
  const CarpenterReviewScreen({super.key, required this.bookingData});

  @override
  ConsumerState<CarpenterReviewScreen> createState() => _CarpenterReviewScreenState();
}

class _CarpenterReviewScreenState extends ConsumerState<CarpenterReviewScreen> {
  late QuickServiceBookingData _bookingData;
  bool _useCoins = false;

  @override
  void initState() {
    super.initState();
    _bookingData = widget.bookingData;
  }

  bool useCoins = false;

  @override
  Widget build(BuildContext context) {
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.withOpacity(0.3)), borderRadius: BorderRadius.circular(8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Appointment Summary\n${_formatDate(_bookingData.scheduleDate)} • ${_bookingData.scheduleTime.format(context)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Service Location\n${_bookingData.location.address}',
                            style: const TextStyle(fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    if (_bookingData.materialPreference != null && _bookingData.materialPreference!.isNotEmpty) ...[
                      const Divider(height: 24),
                      Row(
                        children: [
                          const Icon(Icons.cleaning_services, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Materials\n${_bookingData.materialPreference}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (_bookingData.whatYouNeed != null || _bookingData.describeIssue != null || (_bookingData.uploadedImages?.isNotEmpty ?? false)) ...[
                const SizedBox(height: 20),
                Text('Additional Details', style: AppTextStyles.titleSmall),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.withOpacity(0.3)), borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_bookingData.whatYouNeed != null) ...[
                        const Text('What you need:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF324461))),
                        const SizedBox(height: 4),
                        Text(_bookingData.whatYouNeed!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        if (_bookingData.describeIssue != null || (_bookingData.uploadedImages?.isNotEmpty ?? false)) const SizedBox(height: 12),
                      ],
                      if (_bookingData.describeIssue != null) ...[
                        const Text('Issue Description:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF324461))),
                        const SizedBox(height: 4),
                        Text(_bookingData.describeIssue!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        if (_bookingData.uploadedImages?.isNotEmpty ?? false) const SizedBox(height: 12),
                      ],
                      if (_bookingData.uploadedImages?.isNotEmpty ?? false) ...[
                        const Text('Uploaded Photos:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF324461))),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _bookingData.uploadedImages!.map((path) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(path),
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
                            QuickServicesPriceSummary(bookingData: _bookingData),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Available: 250 GO Coins', style: TextStyle(fontSize: 12)),
                        Text('Use 200 coins', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Switch(
                      value: useCoins,
                      activeColor: AppColors.primaryGold,
                      onChanged: (v) => setState(() => useCoins = v),
                    ),
                  ],
                ),
              ),
              if (useCoins) _buildPriceRow('Discount', '-€2.00', isDiscount: true),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text('€${_calculateTotal().toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              const SizedBox(height: 8),
              const Text('ℹ️ Pay after service', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          )),
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: ElevatedButton(
                onPressed: () {
                  context.pushNamed(
                    RouteNames.quickServicesCarpenterConfirmation,
                    extra: _bookingData,
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String price, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(price, style: TextStyle(fontSize: 14, color: isDiscount ? Colors.red : null)),
        ],
      ),
    );
  }

  double _calculateTotal() {
    double total = _bookingData.estimatedTotalMin;
    if (useCoins) total -= 2.00;
    return total > 0 ? total : 0;
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return '${date.day} ${months[date.month - 1]} ${date.year} • ${weekdays[date.weekday - 1]}';
  }
}
