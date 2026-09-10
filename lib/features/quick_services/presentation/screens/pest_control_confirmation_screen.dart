import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../../core/router/route_names.dart';
import '../../data/models/quick_service_booking_data.dart';

class PestControlConfirmationScreen extends StatelessWidget {
  final QuickServiceBookingData bookingData;

  const PestControlConfirmationScreen({super.key, required this.bookingData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 100,
              ),
              const SizedBox(height: 32),
              Text(
                'Booking Confirmed!',
                style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Your Pest Control service has been successfully booked for:\n\n${bookingData.scheduleDate.toLocal().toString().split(' ')[0]} at ${bookingData.scheduleTime.format(context)}',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () {
                  context.goNamed(RouteNames.home);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Return to Home', style: AppTextStyles.button.copyWith(fontWeight: FontWeight.bold, color: Colors.black)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
