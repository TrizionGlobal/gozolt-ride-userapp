import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/gozolt_button.dart';
import '../../domain/models/bike_model.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/asset_paths.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../history/presentation/providers/history_providers.dart';
import '../../../home/presentation/providers/home_providers.dart';

class BikeRentalConfirmationScreen extends ConsumerStatefulWidget {
  final BikeModel? bike;
  final String? bookingId;
  final int? earnedCoins;
  final double? totalAmount;
  const BikeRentalConfirmationScreen({super.key, this.bike, this.bookingId, this.earnedCoins, this.totalAmount});

  @override
  ConsumerState<BikeRentalConfirmationScreen> createState() => _BikeRentalConfirmationScreenState();
}

class _BikeRentalConfirmationScreenState extends ConsumerState<BikeRentalConfirmationScreen> {
  late String displayBookingId;
  late String fullBookingId;
  late String qrDataJson;

  @override
  void initState() {
    super.initState();
    
    fullBookingId = widget.bookingId ?? 'UNKNOWN';
    
    if (fullBookingId != 'UNKNOWN' && fullBookingId.length >= 8) {
      displayBookingId = 'GZ-BKG-${fullBookingId.substring(0, 8).toUpperCase()}';
    } else {
      displayBookingId = '#GZ-CR-UNKNOWN';
    }
    
    // Create payload for QR code
    final pickupDate = DateTime.now().add(const Duration(days: 1));
    qrDataJson = '''
Booking Reference: $displayBookingId
Brand: ${widget.bike?.brand ?? "-"}
Model: ${widget.bike?.model ?? "-"}
Year: ${widget.bike?.manufacturingYear ?? "-"}
Category: ${widget.bike?.type ?? "-"}
Registration: ${widget.bike?.registrationNumber ?? "-"}
Engine (CC): ${widget.bike?.engineCapacityCc ?? "-"}cc
Fuel Type: ${widget.bike?.fuelType ?? "-"}
Transmission: ${widget.bike?.transmission ?? "-"}
Mileage: ${widget.bike?.mileage ?? "-"} km/l
Seats: ${widget.bike?.seats ?? "-"}
Color: ${widget.bike?.color ?? "-"}
Pickup Date: ${DateFormat('MMM dd, yyyy').format(pickupDate)}
Pickup Time: ${DateFormat('h:mm a').format(pickupDate)}

(ID: $fullBookingId)
'''.trim();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.go('/'),
          )
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Booking Confirmed!',
                        style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your bike is successfully reserved! The supplier has been notified.',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? AppColors.borderDark : Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Text('Booking ID', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
                            const SizedBox(height: 2),
                            Text(displayBookingId, style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                            if (widget.totalAmount != null) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Divider(),
                              ),
                              Text('Amount Paid', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
                              const SizedBox(height: 2),
                              Text('€${widget.totalAmount!.toStringAsFixed(2)}', style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.success)),
                            ],
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: QrImageView(
                                data: qrDataJson,
                                version: QrVersions.auto,
                                size: 160.0,
                                backgroundColor: Colors.white,
                                eyeStyle: const QrEyeStyle(
                                  eyeShape: QrEyeShape.square,
                                  color: AppColors.primaryGold,
                                ),
                                dataModuleStyle: const QrDataModuleStyle(
                                  dataModuleShape: QrDataModuleShape.square,
                                  color: AppColors.primaryGold,
                                ),
                              ),
                            ),
                            Text('Show this QR code at pickup', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      GozoltButton(
                        label: 'View My Bookings',
                        width: double.infinity,
                        onPressed: () {
                          // Select the Bike Rentals tab in History
                          ref.read(historyTabSelectionProvider.notifier).state = 2;
                          // Select the History tab in the bottom nav
                          ref.read(homeTabIndexProvider.notifier).state = 1;
                          context.go('/home');
                        },
                      ),
                      TextButton(
                        onPressed: () => context.go('/'),
                        child: Text('Back to Home', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryGold)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
);
  }
}
