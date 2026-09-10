import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../data/models/quick_service_booking_data.dart';
import '../widgets/quick_services_header.dart';

class ComputerRepairReviewScreen extends StatefulWidget {
  final QuickServiceBookingData bookingData;

  const ComputerRepairReviewScreen({super.key, required this.bookingData});

  @override
  State<ComputerRepairReviewScreen> createState() => _ComputerRepairReviewScreenState();
}

class _ComputerRepairReviewScreenState extends State<ComputerRepairReviewScreen> {
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
    final dateStr = DateFormat('dd MMM yyyy').format(widget.bookingData.scheduleDate);
    final timeStr = widget.bookingData.scheduleTime.format(context);
    final addressStr = widget.bookingData.location.address;

    final deviceType = widget.bookingData.computerDeviceType ?? 'Laptop';
    final deviceBrand = widget.bookingData.computerBrand ?? 'Dell';
    final deviceModel = widget.bookingData.computerModel ?? 'Inspiron 15';
    final os = widget.bookingData.computerOS ?? 'Windows';
    final issue = widget.bookingData.computerIssue ?? 'Battery / Charging';

    final fullDeviceSpec = '$deviceType - $deviceBrand $deviceModel - $os';

    final whatYouNeed = widget.bookingData.whatYouNeed;
    final describeIssue = widget.bookingData.describeIssue;
    final uploadedImages = widget.bookingData.uploadedImages;

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
                                Icons.computer,
                                color: Color(0xFFF57F17),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Computer & Laptop Repair',
                                    style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    fullDeviceSpec,
                                    style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[700]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),

                        _buildDetailRow('Issue:', issue),
                        _buildDetailRow('Date & Time:', '$dateStr • $timeStr'),
                        _buildDetailRow('Location:', addressStr),
                        _buildDetailRow('Customer:', widget.bookingData.userName),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Customer & Additional Details Card
                  if ((whatYouNeed != null && whatYouNeed.trim().isNotEmpty) ||
                      (describeIssue != null && describeIssue.trim().isNotEmpty) ||
                      (uploadedImages != null && uploadedImages.isNotEmpty))
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
                          // Tell Us What You Need section
                          if (whatYouNeed != null && whatYouNeed.trim().isNotEmpty) ...[
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
                            if (whatYouNeed != null && whatYouNeed.trim().isNotEmpty) const Divider(height: 20),
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
                              'Attached Photos (${uploadedImages.length})',
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

                  if ((whatYouNeed != null && whatYouNeed.trim().isNotEmpty) ||
                      (describeIssue != null && describeIssue.trim().isNotEmpty) ||
                      (uploadedImages != null && uploadedImages.isNotEmpty))
                    const SizedBox(height: 16),

                  // Price Summary Card
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
                          'Price Summary',
                          style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
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
                            Text('€30–€100', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Replacement Parts / Software Licences', style: AppTextStyles.bodySmall),
                            Text('Not Included', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Final quote after inspection',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // GO Coins Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/go_coin.png',
                          width: 24,
                          height: 24,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.monetization_on,
                            color: AppColors.primaryGold,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'GO Coins',
                                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Use 200 GO Coins',
                                style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        Checkbox(
                          value: _useGoCoins,
                          activeColor: AppColors.primaryGold,
                          onChanged: (val) => setState(() => _useGoCoins = val ?? false),
                        ),
                        if (_useGoCoins)
                          Text(
                            '- €${_coinDiscount.toStringAsFixed(2)}',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Payment Method Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Payment',
                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'PAY AFTER SERVICE',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: const Color(0xFF2E7D32),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Confirm Booking Button
                  ElevatedButton(
                    onPressed: () {
                      context.pushNamed(
                        RouteNames.quickServicesComputerRepairConfirmation,
                        extra: widget.bookingData,
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
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
