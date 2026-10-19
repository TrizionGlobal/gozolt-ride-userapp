import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/gozolt_button.dart';
import '../../data/models/quick_service_booking_data.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String fullBookingId = bookingData.bookingId ?? 'UNKNOWN';
    final String displayBookingId = (fullBookingId != 'UNKNOWN' && fullBookingId.length >= 8)
        ? 'GZ-QS-${fullBookingId.substring(0, 8).toUpperCase()}'
        : 'GZT-QS-260905-1845'; // Fallback

    final double upfrontRaw = bookingData.upfrontBookingFee + bookingData.materialCost;
    final double discount = bookingData.useGoCoins
        ? (bookingData.discountAmount ?? upfrontRaw.clamp(0.0, 6.0))
        : 0.0;
    final double amountPaid = (upfrontRaw - discount).clamp(0.0, double.infinity);

    final String qrData = '''
Booking Reference: $displayBookingId
Service: ${bookingData.selectedServiceTitle ?? defaultTitle}
Date: ${_formatDate(bookingData.scheduleDate)}
Time: ${bookingData.scheduleTime.format(context)}
Location: ${bookingData.location.address}
Amount Paid: €${amountPaid.toStringAsFixed(2)}
'''.trim();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.goNamed(RouteNames.home);
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 14.0, 20.0, 12.0),
            child: Column(
              children: [
                // Breathing space below Dynamic Island / notch
                const SizedBox(height: 10),

                // Top Header with centered confirmation & right-aligned close button
                Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: GestureDetector(
                        onTap: () => context.goNamed(RouteNames.home),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 18,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 36.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.success,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Booking Confirmed!',
                            style: AppTextStyles.titleLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your service has been scheduled. The provider will arrive at your address.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 11.5,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Structured Confirmation / Receipt Card (Clean & Compact without extra spaces)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Theme.of(context).cardTheme.color ?? Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : Colors.grey.shade200,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Section 1: Booking ID Pill + QR Code + Subtitle
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.confirmation_number_outlined,
                                size: 13, color: AppColors.primaryGold),
                            const SizedBox(width: 6),
                            Text(
                              displayBookingId,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryGold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // QR Code
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          size: 100.0,
                          backgroundColor: Colors.white,
                          eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square, color: Colors.black),
                          dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Colors.black),
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Show this QR code to the service professional',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),

                      const SizedBox(height: 10),
                      Divider(height: 1, color: isDark ? AppColors.borderDark : Colors.grey.shade200),
                      const SizedBox(height: 10),

                      // Section 2: Service Header Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              serviceIcon,
                              color: AppColors.primaryGold,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bookingData.selectedServiceTitle ?? defaultTitle,
                                  style: AppTextStyles.titleMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (bookingData.category.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    bookingData.category,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),
                      Divider(height: 1, color: isDark ? AppColors.borderDark : Colors.grey.shade200),
                      const SizedBox(height: 10),

                      // Section 3: Detail Rows
                      _buildDetailRow(
                        context,
                        icon: Icons.calendar_today_outlined,
                        label: 'Date',
                        value: _formatDate(bookingData.scheduleDate),
                      ),
                      _buildDetailRow(
                        context,
                        icon: Icons.access_time_outlined,
                        label: 'Time',
                        value: bookingData.scheduleTime.format(context),
                      ),
                      _buildDetailRow(
                        context,
                        icon: Icons.location_on_outlined,
                        label: 'Location',
                        value: bookingData.location.address,
                      ),
                      if (bookingData.useGoCoins && discount > 0) ...[
                        _buildDetailRow(
                          context,
                          icon: Icons.monetization_on_outlined,
                          label: 'GoCoins Discount',
                          value: '-€${discount.toStringAsFixed(2)}',
                          valueColor: AppColors.primaryGold,
                        ),
                      ],

                      const SizedBox(height: 8),
                      Divider(height: 1, color: isDark ? AppColors.borderDark : Colors.grey.shade200),
                      const SizedBox(height: 10),

                      // Section 4: Amount Paid Now
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Amount Paid Now',
                            style: AppTextStyles.labelLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '€${amountPaid.toStringAsFixed(2)}',
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: amountPaid == 0.0 ? AppColors.success : AppColors.primaryGold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Bottom Button
                GozoltButton(
                  label: 'Back To Home',
                  width: double.infinity,
                  onPressed: () {
                    context.goNamed(RouteNames.home);
                  },
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
