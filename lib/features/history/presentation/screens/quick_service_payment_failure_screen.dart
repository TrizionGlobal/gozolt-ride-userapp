import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../../quick_services/presentation/providers/quick_services_booking_provider.dart';

class QuickServicePaymentFailureScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final String serviceTitle;
  final double amount;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;

  const QuickServicePaymentFailureScreen({
    super.key,
    required this.bookingId,
    required this.serviceTitle,
    required this.amount,
    this.errorMessage,
    this.onRetry,
    this.onCancel,
  });

  @override
  ConsumerState<QuickServicePaymentFailureScreen> createState() =>
      _QuickServicePaymentFailureScreenState();
}

class _QuickServicePaymentFailureScreenState
    extends ConsumerState<QuickServicePaymentFailureScreen> {
  late String _bookingId;
  late String _serviceTitle;
  late double _amount;
  String? _errorMessage;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _bookingId = widget.bookingId;
    _serviceTitle = widget.serviceTitle;
    _amount = widget.amount;
    _errorMessage = widget.errorMessage;

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
    } catch (_) {}
  }

  void _handleCancel() {
    if (widget.onCancel != null) {
      widget.onCancel!();
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(RouteNames.home);
    }
  }

  Future<void> _handleRetry() async {
    if (widget.onRetry != null) {
      if (context.canPop()) {
        context.pop();
      }
      widget.onRetry!();
      return;
    }

    // Dynamic direct retry using processPayment if opened from deep link
    setState(() => _isRetrying = true);
    try {
      final response = await ref.read(quickServicesRepositoryProvider).processPayment(_bookingId, 'iban', null);
      if (response['checkoutUrl'] != null) {
        final url = Uri.parse(response['checkoutUrl']);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Reopening secure payment gateway...'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to re-initiate payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRetrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleCancel();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              children: [
                const Spacer(),

                // Error Icon
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.error_outline_rounded,
                      color: Colors.red,
                      size: 58,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Error Title
                Text(
                  'Payment Failed',
                  style: AppTextStyles.headlineMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                Text(
                  _errorMessage ??
                      'We could not complete your transaction. Please verify your details or retry your payment.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                // Failed Details Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.25),
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
                        label: 'Amount Due',
                        value: '€${_amount.toStringAsFixed(2)}',
                        isDark: isDark,
                        icon: Icons.euro_rounded,
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                size: 18,
                                color: Colors.red,
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
                              color: Colors.red.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Unpaid / Failed',
                              style: TextStyle(
                                color: Colors.red,
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

                // Retry Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _isRetrying ? null : _handleRetry,
                    icon: _isRetrying
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : const Icon(Icons.refresh_rounded),
                    label: Text(
                      _isRetrying ? 'Opening Gateway...' : 'Retry Payment',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: AppColors.backgroundDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Return / Cancel Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _handleCancel,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Return to Booking',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
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
