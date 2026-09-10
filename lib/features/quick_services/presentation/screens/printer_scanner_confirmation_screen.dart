import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../data/models/quick_service_booking_data.dart';

class PrinterScannerConfirmationScreen extends StatelessWidget {
  final QuickServiceBookingData bookingData;

  const PrinterScannerConfirmationScreen({super.key, required this.bookingData});

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final deviceType = bookingData.printerDeviceType ?? 'Printer';
    final deviceBrand = bookingData.printerBrand ?? '';
    final deviceModel = bookingData.printerModel ?? '';
    
    String serviceTitle = 'Printer & Scanner Service ($deviceType)';
    if (deviceBrand.isNotEmpty || deviceModel.isNotEmpty) {
      serviceTitle = 'Printer & Scanner Service ($deviceBrand $deviceModel)'.trim();
    }

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
                    const Icon(Icons.check_circle, color: Colors.green, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'Your booking is confirmed!',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Booking ID',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'GZT-QS-260907-2821',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: QrImageView(
                        data: 'GZT-QS-260907-2821',
                        version: QrVersions.auto,
                        size: 160.0,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                        dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Show QR code to the service professional',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.print, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  serviceTitle,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text('${_formatDate(bookingData.scheduleDate)} - ${bookingData.scheduleTime.format(context)}', style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(bookingData.location.address, style: const TextStyle(color: Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Estimated Total', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('€12.00', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.access_time, color: Colors.orange, size: 16),
                        SizedBox(width: 8),
                        Text('Professional assignment pending', style: TextStyle(color: Colors.orange, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextButton.icon(
                      onPressed: () => context.pushNamed(RouteNames.support),
                      icon: const Icon(Icons.headset_mic, size: 18),
                      label: const Text('CONTACT SUPPORT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.backgroundDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => context.goNamed(RouteNames.home),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('FINISH', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
