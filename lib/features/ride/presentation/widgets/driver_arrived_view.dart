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
      ],
    );
  }
}
