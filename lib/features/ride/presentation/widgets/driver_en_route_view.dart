import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class DriverEnRouteView extends StatelessWidget {
  final int etaMinutes;
  final VoidCallback onCancel;

  const DriverEnRouteView({
    super.key,
    required this.etaMinutes,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ETA banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.primaryGold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.primaryGold.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.access_time,
                  color: AppColors.primaryGold, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Driver arriving in $etaMinutes min',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.primaryGold,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$etaMinutes min',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.backgroundDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Cancel button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Cancel Ride'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}
