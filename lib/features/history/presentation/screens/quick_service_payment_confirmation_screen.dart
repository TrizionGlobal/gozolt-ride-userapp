import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../../quick_services/presentation/providers/quick_services_booking_provider.dart';

class QuickServicePaymentConfirmationScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final String serviceTitle;
  final double amount;
  final String paymentMethod;
  final String? stripePaymentIntentId;
  final VoidCallback? onDone;

  const QuickServicePaymentConfirmationScreen({
    super.key,
    required this.bookingId,
    required this.serviceTitle,
    required this.amount,
    this.paymentMethod = 'Online Payment (Stripe)',
    this.stripePaymentIntentId,
    this.onDone,
  });

  @override
  ConsumerState<QuickServicePaymentConfirmationScreen> createState() =>
      _QuickServicePaymentConfirmationScreenState();
}

class _QuickServicePaymentConfirmationScreenState
    extends ConsumerState<QuickServicePaymentConfirmationScreen> {
  late String _bookingId;
  late String _serviceTitle;
  late double _amount;
  late String _paymentMethod;
  @override
  void initState() {
    super.initState();
    _bookingId = widget.bookingId;
    _serviceTitle = widget.serviceTitle;
    _amount = widget.amount;
    _paymentMethod = widget.paymentMethod;

    if (_bookingId.isNotEmpty && (_amount <= 0 || _serviceTitle == 'Quick Service')) {
      _loadDynamicDetails();
    }
  }

  Future<void> _loadDynamicDetails() async {
    try {
      final res = await ref.read(quickServicesRepositoryProvider).verifyPayment(_bookingId);
      if (mounted) {
        setState(() {
          if (res['serviceTitle'] != null && res['serviceTitle'].toString().isNotEmpty) {
            _serviceTitle = res['serviceTitle'].toString();
          }
          if (res['amount'] is num) {
            _amount = (res['amount'] as num).toDouble();
          }
        });
      }
    } catch (_) {
      // Keep initial parameters on error
    }
  }

  void _handleDone() {
    if (widget.onDone != null) {
      widget.onDone!();
      return;
    }
    if (context.canPop()) {
      context.pop(true);
    } else {
      context.goNamed(RouteNames.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleDone();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              children: [
                const Spacer(),

                // Animated/Styled Success Icon
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                      size: 58,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Success Title
                Text(
                  'Payment Confirmed!',
                  style: AppTextStyles.headlineMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                Text(
                  'Your payment has been successfully processed & confirmed.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                // Compact & Styled Amount Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 14,
                            color: Colors.green[600],
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Total Amount Paid',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.textSecondary : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '€${_amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.backgroundDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Transaction Details Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        label: 'Service',
                        value: _serviceTitle,
                        isDark: isDark,
                        icon: Icons.home_repair_service_rounded,
                      ),
                      const Divider(height: 24),
                      _buildDetailRow(
                        label: 'Service ID',
                        value: _bookingId.length >= 8
                            ? 'GZ-QS-${_bookingId.substring(0, 8).toUpperCase()}'
                            : _bookingId,
                        isDark: isDark,
                        icon: Icons.tag_rounded,
                      ),
                      const Divider(height: 24),
                      _buildDetailRow(
                        label: 'Payment Method',
                        value: _paymentMethod.replaceAll(' (Stripe)', '').replaceAll('(Stripe)', '').trim(),
                        isDark: isDark,
                        icon: Icons.payment_rounded,
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.verified_rounded,
                                size: 18,
                                color: Colors.green[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Status',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Paid & Completed',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Done Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _handleDone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: AppColors.backgroundDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    required bool isDark,
    required IconData icon,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        Flexible(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
