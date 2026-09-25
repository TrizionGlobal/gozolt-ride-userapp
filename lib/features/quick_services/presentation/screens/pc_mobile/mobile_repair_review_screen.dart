import '../../providers/quick_services_booking_provider.dart';
import '../../../../../core/widgets/booking_payment_sheet.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/router/route_names.dart';
import '../../../data/models/quick_service_booking_data.dart';
import '../../widgets/quick_services_price_summary.dart';
import '../../widgets/quick_services_header.dart';
import '../../../../ride/data/models/saved_payment_method.dart';

class MobileRepairReviewScreen extends ConsumerStatefulWidget {
  final QuickServiceBookingData bookingData;

  const MobileRepairReviewScreen({super.key, required this.bookingData});

  @override
  ConsumerState<MobileRepairReviewScreen> createState() => _MobileRepairReviewScreenState();
}

class _MobileRepairReviewScreenState extends ConsumerState<MobileRepairReviewScreen> {
  late QuickServiceBookingData _bookingData;
  bool _useGoCoins = false;
  bool _isBooking = false;

  @override
  void initState() {
    super.initState();
    _bookingData = widget.bookingData;
  }

  void _showFullImage(BuildContext context, String path) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: path.startsWith('http')
                ? Image.network(path, fit: BoxFit.contain)
                : Image.file(File(path), fit: BoxFit.contain),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr = DateFormat('dd MMM yyyy').format(_bookingData.scheduleDate);
    final timeStr = _bookingData.scheduleTime.format(context);

    final devices = _bookingData.mobileDevices ?? [];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          QuickServicesHeader(
            currentStep: 2,
            title: 'Review & Book',
            subtitle: _bookingData.selectedServiceTitle ?? 'Mobile Repair',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Booking Details Card ──────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
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
                              decoration: BoxDecoration(
                                color: AppColors.primaryGold.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.smartphone,
                                color: AppColors.primaryGold,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Booking Details',
                              style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Date & Time
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                            const SizedBox(width: 10),
                            Text(
                              '$dateStr • $timeStr',
                              style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Location
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on, size: 18, color: Colors.grey),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _bookingData.location.address,
                                style: AppTextStyles.bodySmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Customer
                        Row(
                          children: [
                            const Icon(Icons.person, size: 18, color: Colors.grey),
                            const SizedBox(width: 10),
                            Text(
                              'Customer: ${_bookingData.userName}',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Devices & Additional Details Card ─────────────────────
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
                          'Mobile Devices (${devices.length})',
                          style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ...devices.map((device) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[850] : Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.withOpacity(0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${device.deviceBrand} ${device.deviceModel}',
                                  style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                _buildDetailRow('Type:', device.deviceType),
                                if (device.operatingSystem != null && device.operatingSystem!.isNotEmpty)
                                  _buildDetailRow('OS:', device.operatingSystem!),
                                _buildDetailRow('Issue:', device.issue),
                              ],
                            ),
                          ),
                        )),

                        // Additional Details section (inline, like car mechanic)
                        if ((_bookingData.whatYouNeed != null && _bookingData.whatYouNeed!.isNotEmpty) ||
                            (_bookingData.describeIssue != null && _bookingData.describeIssue!.isNotEmpty) ||
                            (_bookingData.uploadedImages != null && _bookingData.uploadedImages!.isNotEmpty)) ...[
                          const SizedBox(height: 8),
                          const Divider(),
                          const SizedBox(height: 8),
                          Text(
                            'Additional Details',
                            style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          if (_bookingData.whatYouNeed != null && _bookingData.whatYouNeed!.isNotEmpty) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.grey),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'What You Need: ${_bookingData.whatYouNeed!}',
                                    style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[700]),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                          ],
                          if (_bookingData.describeIssue != null && _bookingData.describeIssue!.isNotEmpty) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.note_alt_outlined, size: 18, color: Colors.grey),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Issue description: ${_bookingData.describeIssue!}',
                                    style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[700]),
                                  ),
                                ),
                              ],
                            ),
                            if (_bookingData.uploadedImages != null && _bookingData.uploadedImages!.isNotEmpty)
                              const SizedBox(height: 10),
                          ],
                          if (_bookingData.uploadedImages != null && _bookingData.uploadedImages!.isNotEmpty) ...[
                            Row(
                              children: [
                                const Icon(Icons.image_outlined, size: 18, color: Colors.grey),
                                const SizedBox(width: 10),
                                Text(
                                  'Attached Photos (${_bookingData.uploadedImages!.length})',
                                  style: AppTextStyles.bodySmall,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: SizedBox(
                                    height: 40,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        shrinkWrap: true,
                                        itemCount: _bookingData.uploadedImages!.length,
                                        itemBuilder: (context, index) {
                                          final path = _bookingData.uploadedImages![index];
                                          final file = File(path);
                                          return GestureDetector(
                                            onTap: () {
                                              if (path.startsWith('http') || file.existsSync()) _showFullImage(context, path);
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.only(left: 4.0),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(4),
                                                child: path.startsWith('http')
                                                    ? Image.network(path, width: 40, height: 40, fit: BoxFit.cover,)
                                                    : Image.file(File(path), width: 40, height: 40, fit: BoxFit.cover),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Price Summary ─────────────────────────────────────────
                  QuickServicesPriceSummary(
                    bookingData: _bookingData,
                    useGoCoins: _useGoCoins,
                    onGoCoinsChanged: (val) => setState(() => _useGoCoins = val),
                    showAdditionalDetails: false,
                  ),

                  const SizedBox(height: 40),

                  // ── Confirm Booking Button ────────────────────────────────
                  ElevatedButton(
                    onPressed: _isBooking ? null : () async {

                      final finalTotal = ((_bookingData.upfrontBookingFee + _bookingData.materialCost) -
                              (_useGoCoins
                                  ? (_bookingData.upfrontBookingFee + _bookingData.materialCost).clamp(0.0, 6.0)
                                  : 0.0))
                          .clamp(0.0, double.infinity);

                      if (finalTotal <= 0.0) {
                        final updatedData = _bookingData.copyWith(
                          paymentMethodType: PaymentMethodType.cash,
                          useGoCoins: _useGoCoins,
                        );
                        
                      setState(() => _isBooking = true);
                      final bookingId = await ref.read(quickServicesBookingProvider.notifier).bookQuickService(updatedData);
                      if (mounted) setState(() => _isBooking = false);
                      if (bookingId != null && mounted) {
                        context.pushNamed(RouteNames.quickServicesMobileRepairConfirmation, extra: updatedData.copyWith(bookingId: bookingId));
                      } else {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to book service')));
                      }
                    } else {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => BookingPaymentSheet(
                          currentType: _bookingData.paymentMethodType,
                          currentCardId: _bookingData.paymentMethodId,
                          isQuickService: true,
                          amount: finalTotal,
                          onConfirm: (type, {cardId}) async {
                            final updatedData = _bookingData.copyWith(
                                paymentMethodType: type,
                                paymentMethodId: cardId,
                                useGoCoins: _useGoCoins,
                              );
                            final bookingId = await ref.read(quickServicesBookingProvider.notifier).bookQuickService(updatedData);
                            if (bookingId != null && mounted) {
                              context.pushNamed(RouteNames.quickServicesMobileRepairConfirmation, extra: updatedData.copyWith(bookingId: bookingId));
                              return true;
                            } else {
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to book service')));
                              return false;
                            }
                          },
                        ),
                      );
                    }
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
                    child: _isBooking ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : Text('Confirm Booking', style: AppTextStyles.button.copyWith(color: Colors.black)),
                  ),
                  const SizedBox(height: 40),
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
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[600])),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
