import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class DriverArrivedView extends StatelessWidget {
  final String otpPin;

  const DriverArrivedView({super.key, required this.otpPin});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Arrival banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: AppColors.success.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle,
                  color: AppColors.success, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your driver has arrived!',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Ride PIN Section
        Text(
          'Your Ride PIN',
          style: AppTextStyles.titleSmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Share this PIN with your driver to start the ride',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),

        // Ride PIN boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: otpPin.split('').map((digit) {
            return Container(
              width: 56,
              height: 64,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.primaryGold.withOpacity(0.5),
                    width: 1.5),
              ),
              child: Center(
                child: Text(
                  digit,
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: AppColors.primaryGold,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),

        Text(
          'Ride PIN Verification',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.primaryGold,
          ),
        ),
      ],
    );
  }
}
