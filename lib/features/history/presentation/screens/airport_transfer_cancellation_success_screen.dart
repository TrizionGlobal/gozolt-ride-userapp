import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class AirportTransferCancellationSuccessScreen extends StatelessWidget {
  final double refundAmount;
  final String refundDays;
  final String refundStatus;

  const AirportTransferCancellationSuccessScreen({
    super.key,
    required this.refundAmount,
    this.refundDays = '3-5 business days',
    this.refundStatus = 'REFUNDED',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isFailedRefund = refundStatus.toUpperCase() == 'FAILED';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Status Icon (Green check for success, Amber warning for failed/delayed refund)
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: (isFailedRefund ? Colors.amber : Colors.green)
                      .withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isFailedRefund
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline,
                  color: isFailedRefund ? Colors.amber[700] : Colors.green,
                  size: 60,
                ),
              ),
              const SizedBox(height: 28),

              // Title
              Text(
                'Booking Cancelled',
                style: AppTextStyles.headlineMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.textPrimary
                      : AppColors.textPrimaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Subtitle
              Text(
                isFailedRefund
                    ? 'Your transfer booking was cancelled, but the automated refund requires manual processing.'
                    : 'Your airport transfer booking has been successfully cancelled.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // Refund Details Card
              if (refundAmount > 0)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isFailedRefund
                          ? Colors.amber.withValues(alpha: 0.4)
                          : (isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isFailedRefund
                                ? Icons.access_time_rounded
                                : Icons.check_circle,
                            size: 18,
                            color:
                                isFailedRefund ? Colors.amber[700] : Colors.green,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isFailedRefund
                                ? 'Refund Pending Manual Review'
                                : 'Refund Initiated',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: isFailedRefund
                                  ? Colors.amber[800]
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '€${refundAmount.toStringAsFixed(2)}',
                        style: AppTextStyles.headlineLarge.copyWith(
                          color:
                              isFailedRefund ? Colors.amber[700] : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        isFailedRefund
                            ? 'The automated refund gateway encountered a delay. Our support team will credit €${refundAmount.toStringAsFixed(2)} back to your original payment method within $refundDays.'
                            : 'The refundable amount will be credited to your original payment method within $refundDays.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isDark
                              ? AppColors.textPrimary
                              : AppColors.textPrimaryLight,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

              if (refundAmount <= 0)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'No Payment Refund Applicable',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'This transfer booking was cancelled. No advance payment was charged for this booking.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

              const Spacer(),

              // Done Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    foregroundColor: AppColors.backgroundDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
