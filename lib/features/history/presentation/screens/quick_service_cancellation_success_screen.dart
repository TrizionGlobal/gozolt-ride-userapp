import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class QuickServiceCancellationSuccessScreen extends StatelessWidget {
  final double refundAmount;
  final double upfrontFee;
  final String refundDays;
  final String refundStatus;

  const QuickServiceCancellationSuccessScreen({
    super.key,
    required this.refundAmount,
    this.upfrontFee = 0.0,
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
                  color: (isFailedRefund ? Colors.amber : Colors.green).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isFailedRefund ? Icons.warning_amber_rounded : Icons.check_circle_outline,
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
                  color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Subtitle
              Text(
                isFailedRefund
                    ? 'Your booking was cancelled, but the automated refund requires manual review.'
                    : 'Your quick service booking has been successfully cancelled.',
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
                          : (isDark ? AppColors.borderDark : AppColors.borderLight),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isFailedRefund ? Icons.access_time_rounded : Icons.check_circle,
                            size: 18,
                            color: isFailedRefund ? Colors.amber[700] : Colors.green,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isFailedRefund ? 'Refund Pending Manual Review' : 'Refund Initiated',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: isFailedRefund ? Colors.amber[800] : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '€${refundAmount.toStringAsFixed(2)}',
                        style: AppTextStyles.headlineLarge.copyWith(
                          color: isFailedRefund ? Colors.amber[700] : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        isFailedRefund
                            ? 'The automated gateway refund encountered a delay. Our support team has been notified and will manually credit €${refundAmount.toStringAsFixed(2)} back to your original payment method within $refundDays.'
                            : 'The refundable amount will be credited to your original payment method within $refundDays.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (upfrontFee > 0) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            'Note: The upfront booking fee (€${upfrontFee.toStringAsFixed(2)}) is non-refundable per cancellation policy.',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.amber[800],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
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
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'No Refund Applicable',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'The upfront booking fee is non-refundable per platform cancellation policy.',
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
                    Navigator.of(context).pop(); // pop this screen back to details
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
