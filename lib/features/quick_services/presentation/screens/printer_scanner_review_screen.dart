import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../data/models/quick_service_booking_data.dart';
import '../widgets/quick_services_header.dart';

class PrinterScannerReviewScreen extends StatefulWidget {
  final QuickServiceBookingData bookingData;

  const PrinterScannerReviewScreen({super.key, required this.bookingData});

  @override
  State<PrinterScannerReviewScreen> createState() => _PrinterScannerReviewScreenState();
}

class _PrinterScannerReviewScreenState extends State<PrinterScannerReviewScreen> {
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

    final deviceType = widget.bookingData.printerDeviceType ?? 'Printer';
    final deviceBrand = widget.bookingData.printerBrand ?? '';
    final deviceModel = widget.bookingData.printerModel ?? '';
    final connMethod = widget.bookingData.printerConnectionMethod ?? '';
    final issues = widget.bookingData.printerIssues?.join(', ') ?? '';

    String fullDeviceSpec = deviceType;
    if (deviceBrand.isNotEmpty || deviceModel.isNotEmpty) {
      fullDeviceSpec += ' - $deviceBrand $deviceModel'.trim();
    }
    if (connMethod.isNotEmpty) {
      fullDeviceSpec += ' ($connMethod)';
    }

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
                                Icons.print,
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
                                    widget.bookingData.selectedServiceTitle ?? 'Printer & Scanner Service',
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

                        if (issues.isNotEmpty) _buildDetailRow('Issue:', issues),
                        if (widget.bookingData.printerDeviceCount != null && widget.bookingData.printerDeviceCount! > 1)
                          _buildDetailRow('Devices:', '${widget.bookingData.printerDeviceCount}'),
                        if (widget.bookingData.printerErrorCode != null && widget.bookingData.printerErrorCode!.isNotEmpty)
                          _buildDetailRow('Error Code:', widget.bookingData.printerErrorCode!),
                        
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
                              'Problem Description',
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
                            if (describeIssue != null && describeIssue.trim().isNotEmpty) const Divider(height: 20),
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
                            Text('€12.00', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Estimated Labour', style: AppTextStyles.bodyMedium),
                            Text('€20–€80', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Replacement Parts', style: AppTextStyles.bodySmall),
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

                  const SizedBox(height: 24),

                  // Confirm Booking Button
                  ElevatedButton(
                    onPressed: () {
                      context.pushNamed(
                        RouteNames.quickServicesPrinterScannerConfirmation,
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
