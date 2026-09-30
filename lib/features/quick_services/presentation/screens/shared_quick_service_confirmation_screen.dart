import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../data/models/quick_service_booking_data.dart';
import '../../../ride/data/models/saved_payment_method.dart';

class SharedQuickServiceConfirmationScreen extends StatelessWidget {
  final QuickServiceBookingData bookingData;
  final IconData serviceIcon;
  final String defaultTitle;

  const SharedQuickServiceConfirmationScreen({
    super.key,
    required this.bookingData,
    required this.serviceIcon,
    required this.defaultTitle,
  });

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final String fullBookingId = bookingData.bookingId ?? 'UNKNOWN';
    final String displayBookingId = (fullBookingId != 'UNKNOWN' && fullBookingId.length >= 8)
        ? 'GZ-QS-${fullBookingId.substring(0, 8).toUpperCase()}'
        : 'GZT-QS-260905-1845'; // Fallback

    final String qrData = '''
Booking Reference: $displayBookingId
Service: ${bookingData.selectedServiceTitle ?? defaultTitle}
Date: ${_formatDate(bookingData.scheduleDate)}
Time: ${bookingData.scheduleTime.format(context)}
Location: ${bookingData.location.address}
Amount Paid: €${((bookingData.upfrontBookingFee + bookingData.materialCost) - (bookingData.useGoCoins ? (bookingData.upfrontBookingFee + bookingData.materialCost).clamp(0.0, 6.0) : 0.0)).toStringAsFixed(2)}
'''.trim();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 48),
                    const SizedBox(height: 8),
                    Text(
                      'Your booking is confirmed!',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Service ID',
                      textAlign: TextAlign.center,
                      style:
                          AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayBookingId,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 120.0,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square, color: Colors.black),
                        dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Colors.black),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Show QR code to the service professional',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),

                    // Booking Details Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(serviceIcon,
                                  color: const Color(0xFF324461), size: 24),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  bookingData.selectedServiceTitle ??
                                      defaultTitle,
                                  style: AppTextStyles.titleMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF324461)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow(
                              'Date', _formatDate(bookingData.scheduleDate)),
                          _buildDetailRow(
                              'Time', bookingData.scheduleTime.format(context)),
                          _buildDetailRow(
                              'Location', bookingData.location.address),
                          const Divider(height: 24),
                          _buildDetailRow(
                            'Amount Paid Now',
                            '€${((bookingData.upfrontBookingFee + bookingData.materialCost) - (bookingData.useGoCoins ? (bookingData.upfrontBookingFee + bookingData.materialCost).clamp(0.0, 6.0) : 0.0)).toStringAsFixed(2)}',
                            isTotal: false,
                          ),
                          _buildDetailRow(
                            'Remaining Amount (After Service)',
                            'Based on hours spent × hourly rate',
                            isTotal: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: ElevatedButton(
                onPressed: () {
                  context.goNamed(RouteNames.home);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('Back To Home',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.grey.shade600,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: isTotal ? AppColors.primaryGold : null,
                fontSize: isTotal ? 14 : null, // 16 might be too large for long text
              ),
            ),
          ),
        ],
      ),
    );
  }
}
