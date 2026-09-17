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

class HomeElectricReviewScreen extends ConsumerStatefulWidget {
  const HomeElectricReviewScreen({
    super.key,
    required this.bookingData,
  });

  final QuickServiceBookingData bookingData;

  @override
  ConsumerState<HomeElectricReviewScreen> createState() => _HomeElectricReviewScreenState();
}

class _HomeElectricReviewScreenState extends ConsumerState<HomeElectricReviewScreen> {
  bool _useGoCoins = false;
  late QuickServiceBookingData _bookingData;
  bool _useCoins = false;

  @override
  void initState() {
    super.initState();
    _bookingData = widget.bookingData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const QuickServicesHeader(
            title: 'Review & Book',
            subtitle: 'Home Electric',
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
                            _bookingData.selectedServiceTitle ?? 'Electrical Services',
                            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          if (_bookingData.selectedAddons.isNotEmpty) ...[
                            ..._bookingData.selectedAddons.map(
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
                                '${_formatDate(_bookingData.scheduleDate)} • ${_bookingData.scheduleTime.format(context)}',
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
                                  _bookingData.location.address,
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
                                  '${_bookingData.userName} • ${_bookingData.userPhone}',
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
                    if ((_bookingData.whatYouNeed != null && _bookingData.whatYouNeed!.isNotEmpty) ||
                        (_bookingData.describeIssue != null && _bookingData.describeIssue!.isNotEmpty) ||
                        (_bookingData.uploadedImages != null && _bookingData.uploadedImages!.isNotEmpty)) ...[
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
                            if (_bookingData.whatYouNeed != null && _bookingData.whatYouNeed!.isNotEmpty) ...[
                              Text(
                                'What You Need',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _bookingData.whatYouNeed!,
                                style: AppTextStyles.bodyMedium,
                              ),
                              const SizedBox(height: 12),
                            ],
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
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    QuickServicesPriceSummary(bookingData: _bookingData, useGoCoins: _useGoCoins, onGoCoinsChanged: (val) => setState(() => _useGoCoins = val),),
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
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
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
                          RouteNames.quickServicesElectricalConfirmation,
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
}
