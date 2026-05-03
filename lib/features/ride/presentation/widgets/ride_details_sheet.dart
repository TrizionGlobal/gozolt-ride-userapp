import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../providers/active_ride_provider.dart';

class RideDetailsSheet extends ConsumerWidget {
  const RideDetailsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rideState = ref.watch(activeRideProvider);
    final ride = rideState.ride;
    final driver = rideState.driverInfo;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderDark,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text('Ride Details', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 20),

              // Route
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: Column(
                  children: [
                    // Pickup
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Pickup',
                                  style: AppTextStyles.labelSmall
                                      .copyWith(color: AppColors.success)),
                              const SizedBox(height: 2),
                              Text(
                                ride?.pickupAddress ?? 'Loading...',
                                style: AppTextStyles.bodyMedium,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Dashed line
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Column(
                        children: List.generate(
                          3,
                          (_) => Container(
                            width: 2,
                            height: 6,
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            color: AppColors.borderDark,
                          ),
                        ),
                      ),
                    ),

                    // Dropoff
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Dropoff',
                                  style: AppTextStyles.labelSmall
                                      .copyWith(color: AppColors.error)),
                              const SizedBox(height: 2),
                              Text(
                                ride?.dropoffAddress ?? 'Loading...',
                                style: AppTextStyles.bodyMedium,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Fare + Vehicle + Payment
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: Column(
                  children: [
                    _detailRow('Estimated Fare',
                        '\u20AC${ride?.estimatedFare?.toStringAsFixed(2) ?? '0.00'}',
                        valueColor: AppColors.primaryGold),
                    const Divider(color: AppColors.borderDark, height: 20),
                    _detailRow(
                        'Vehicle Type', ride?.vehicleType ?? 'Standard'),
                    const Divider(color: AppColors.borderDark, height: 20),
                    _detailRow(
                        'Payment', ride?.paymentMethod ?? 'Cash'),
                    if (driver != null) ...[
                      const Divider(color: AppColors.borderDark, height: 20),
                      _detailRow('Driver', driver.name),
                      const Divider(color: AppColors.borderDark, height: 20),
                      _detailRow('Plate', driver.formattedPlate),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Close
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.borderDark),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary)),
        Text(value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
            )),
      ],
    );
  }
}
