import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../../history/presentation/providers/history_providers.dart';
import '../../../home/presentation/providers/home_providers.dart';

class AirportTransferConfirmationScreen extends ConsumerWidget {
  final String bookingId;
  final String paymentMethod;
  final String paymentStatus;

  const AirportTransferConfirmationScreen({
    super.key,
    required this.bookingId,
    required this.paymentMethod,
    required this.paymentStatus,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final qrData = '''
GOZOLT AIRPORT TRANSFER
Service ID: $bookingId
Payment Method: $paymentMethod
Payment Status: $paymentStatus
Status: Booking Confirmed
'''
        .trim();

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  24,
                  20,
                  24,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 48,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(
                            alpha: 0.12,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          size: 52,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Transfer Booked!',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.headlineSmall.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your airport transfer has been booked! Your chauffeur will meet you at your pickup location and drop you off at your chosen destination.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.textSecondary
                              : AppColors.textSecondaryLight,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.surfaceDark
                              : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isDark
                                ? AppColors.borderDark
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'SERVICE ID',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primaryGold,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.7,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              bookingId,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.titleMedium.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Divider(
                              color: isDark
                                  ? AppColors.borderDark
                                  : Colors.grey.shade300,
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(10),
                              color: Colors.white,
                              child: QrImageView(
                                data: qrData,
                                version: QrVersions.auto,
                                size: 165,
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
                            const SizedBox(height: 9),
                            Text(
                              'Keep this QR code for your transfer',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: isDark
                                    ? AppColors.textSecondary
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.surfaceDark
                              : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? AppColors.borderDark
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Column(
                          children: [
                            _ConfirmationRow(
                              icon: paymentMethod == 'Cash'
                                  ? Icons.payments_outlined
                                  : Icons.credit_card_rounded,
                              label: 'Payment Method',
                              value: paymentMethod,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 12),
                            _ConfirmationRow(
                              icon: Icons.schedule_rounded,
                              label: 'Payment Status',
                              value: paymentStatus,
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGold.withValues(
                            alpha: 0.11,
                          ),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 19,
                              color: AppColors.primaryGold,
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                'Your chauffeur will meet you at the pickup location with your welcome sign (if requested) and assist with luggage. Direct drop-off at your destination with no vehicle handover or return required.',
                                style: AppTextStyles.bodySmall.copyWith(
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            ref.read(historyTabSelectionProvider.notifier).state = 4;
                            ref.read(homeTabIndexProvider.notifier).state = 1;
                            context.goNamed(RouteNames.home);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGold,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'View My Transfers',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => context.goNamed(RouteNames.home),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isDark ? AppColors.borderDark : Colors.grey.shade400,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'Back to Home',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ConfirmationRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _ConfirmationRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.primaryGold.withValues(
              alpha: 0.12,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: AppColors.primaryGold,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.textSecondary
                      : AppColors.textSecondaryLight,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.textPrimary
                      : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
