import '../../../../../core/widgets/booking_payment_sheet.dart';
import 'dart:io';
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

class MobileRepairReviewScreen extends ConsumerStatefulWidget {
  final QuickServiceBookingData bookingData;

  const MobileRepairReviewScreen({super.key, required this.bookingData});

  @override
  ConsumerState<MobileRepairReviewScreen> createState() => _MobileRepairReviewScreenState();
}

class _MobileRepairReviewScreenState extends ConsumerState<MobileRepairReviewScreen> {
  late QuickServiceBookingData _bookingData;
  bool _useCoins = false;

  @override
  void initState() {
    super.initState();
    _bookingData = widget.bookingData;
  }

  bool _useGoCoins = false;

  double get _coinDiscount => _useGoCoins ? 2.00 : 0.00;

  void _showFullImage(BuildContext context, File file) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: Image.file(file, fit: BoxFit.contain),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMM yyyy').format(_bookingData.scheduleDate);
    final timeStr = _bookingData.scheduleTime.format(context);
    final addressStr = _bookingData.location.address;

    final deviceBrand = _bookingData.deviceBrand ?? 'Smartphone';
    final deviceModel = _bookingData.deviceModel ?? '';
    final fullDeviceName = deviceModel.isNotEmpty ? '$deviceBrand $deviceModel' : deviceBrand;
    final deviceType = _bookingData.deviceType ?? 'Smartphone';
    final operatingSystem = _bookingData.operatingSystem ?? 'Android';
    final issue = _bookingData.mobileIssue ?? 'General Issue';
    final deviceCount = _bookingData.deviceCount ?? 1;

    final whatYouNeed = _bookingData.whatYouNeed;
    final describeIssue = _bookingData.describeIssue;
    final uploadedImages = _bookingData.uploadedImages;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const QuickServicesHeader(
            title: 'Review & Book',
            subtitle: 'Mobile Repair',
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
                                Icons.smartphone,
                                color: Color(0xFFF57F17),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _bookingData.selectedServiceTitle ?? 'Mobile Repair at Home',
                                style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),

                        _buildDetailRow('Device:', fullDeviceName),
                        _buildDetailRow('Device Type:', deviceType),
                        _buildDetailRow('Operating System:', operatingSystem),
                        _buildDetailRow('Issue:', issue),
                        _buildDetailRow('Devices:', '$deviceCount'),
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

                  // Customer & Additional Details Card
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
                            const Icon(Icons.person_outline, size: 20, color: Colors.grey),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Customer: ${_bookingData.userName}',
                                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),

                        // Tell Us What You Need section
                        if (whatYouNeed != null && whatYouNeed.trim().isNotEmpty) ...[
                          const Divider(height: 20),
                          Text(
                            'Tell us what you need',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            whatYouNeed,
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],

                        // Describe Issue section
                        if (describeIssue != null && describeIssue.trim().isNotEmpty) ...[
                          const Divider(height: 20),
                          Text(
                            'Description',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            describeIssue,
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],

                        // Uploaded Images section
                        if (uploadedImages != null && uploadedImages.isNotEmpty) ...[
                          const Divider(height: 20),
                          Text(
                            'Uploaded Images (${uploadedImages.length})',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 75,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: uploadedImages.length,
                              itemBuilder: (context, index) {
                                final imgPath = uploadedImages[index];
                                final file = File(imgPath);
                                return GestureDetector(
                                  onTap: () {
                                    if (file.existsSync()) {
                                      _showFullImage(context, file);
                                    }
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 10),
                                    width: 75,
                                    height: 75,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: file.existsSync()
                                          ? Image.file(file, fit: BoxFit.cover)
                                          : Container(
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
                  

                  const SizedBox(height: 24),

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
                          RouteNames.quickServicesMobileRepairConfirmation,
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
