import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../data/datasources/airport_transfer_remote_datasource.dart';
import '../widgets/airport_transfer_payment_sheet.dart';

class AirportTransferPaymentFailureScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final String? bookingReference;
  final String? serviceTitle;
  final double amount;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;

  const AirportTransferPaymentFailureScreen({
    super.key,
    required this.bookingId,
    this.bookingReference,
    this.serviceTitle = 'Airport Transfer',
    required this.amount,
    this.errorMessage,
    this.onRetry,
    this.onCancel,
  });

  @override
  ConsumerState<AirportTransferPaymentFailureScreen> createState() =>
      _AirportTransferPaymentFailureScreenState();
}

class _AirportTransferPaymentFailureScreenState
    extends ConsumerState<AirportTransferPaymentFailureScreen>
    with WidgetsBindingObserver {
  late String _bookingId;
  late String _bookingReference;
  late String _serviceTitle;
  late double _amount;
  String? _errorMessage;
  bool _isProcessing = false;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bookingId = widget.bookingId;
    _bookingReference = widget.bookingReference ?? widget.bookingId;
    _serviceTitle = widget.serviceTitle ?? 'Airport Transfer';
    _amount = widget.amount;
    _errorMessage = widget.errorMessage;

    if (_bookingId.isNotEmpty && _amount <= 0) {
      _loadDynamicDetails();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _verifyPaymentStatus();
    }
  }

  Future<void> _loadDynamicDetails() async {
    try {
      final res = await ref
          .read(airportTransferRemoteDatasourceProvider)
          .verifyPayment(_bookingId);
      if (mounted) {
        setState(() {
          if (res['bookingReference'] != null) {
            _bookingReference = res['bookingReference'].toString();
          }
          if (res['amount'] is num) {
            _amount = (res['amount'] as num).toDouble();
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _verifyPaymentStatus() async {
    if (!mounted) return;
    try {
      final res = await ref
          .read(airportTransferRemoteDatasourceProvider)
          .verifyPayment(_bookingId);
      if (res['isPaid'] == true && mounted) {
        _pollingTimer?.cancel();
        context.pushReplacementNamed(
          RouteNames.airportTransferPaymentConfirmation,
          extra: {
            'bookingId': _bookingReference,
            'amount': (res['amount'] is num)
                ? (res['amount'] as num).toDouble()
                : _amount,
            'paymentMethod': 'Online Payment (Stripe)',
            'stripePaymentIntentId': res['stripePaymentIntentId']?.toString(),
            'serviceTitle': _serviceTitle,
          },
        );
      }
    } catch (_) {}
  }

  void _handleCancel() {
    if (widget.onCancel != null) {
      widget.onCancel!();
      return;
    }
    context.goNamed(RouteNames.home);
  }

  void _openRetrySheet() {
    if (widget.onRetry != null) {
      widget.onRetry!();
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AirportTransferPaymentSheet(
        amount: _amount,
        onConfirm: (option, {cardId}) async {
          final datasource = ref.read(airportTransferRemoteDatasourceProvider);

          if (option == AirportPaymentOption.card) {
            setState(() => _isProcessing = true);
            try {
              final res = await datasource.processPayment(
                _bookingId,
                paymentMethod: 'CARD',
                paymentMethodId: cardId,
              );

              if (mounted) {
                context.pushReplacementNamed(
                  RouteNames.airportTransferPaymentConfirmation,
                  extra: {
                    'bookingId': _bookingReference,
                    'amount': _amount,
                    'paymentMethod': 'Saved Card',
                    'stripePaymentIntentId':
                        res['stripePaymentIntentId']?.toString(),
                    'serviceTitle': _serviceTitle,
                  },
                );
              }
              return true;
            } catch (e) {
              if (mounted) {
                setState(() {
                  _errorMessage = e.toString().replaceAll('Exception: ', '');
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Payment failed: $_errorMessage'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              return false;
            } finally {
              if (mounted) setState(() => _isProcessing = false);
            }
          } else {
            // Online Payment
            setState(() => _isProcessing = true);
            try {
              final res = await datasource.processPayment(
                _bookingId,
                paymentMethod: 'ONLINE',
              );

              final checkoutUrl = res['checkoutUrl']?.toString();
              if (checkoutUrl != null) {
                final uri = Uri.parse(checkoutUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              }

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Opening secure Stripe payment...'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }

              // Poll verification periodically
              _pollingTimer?.cancel();
              _pollingTimer =
                  Timer.periodic(const Duration(seconds: 3), (timer) {
                if (timer.tick > 45) {
                  timer.cancel();
                } else {
                  _verifyPaymentStatus();
                }
              });

              return true;
            } catch (e) {
              if (mounted) {
                setState(() {
                  _errorMessage = e.toString().replaceAll('Exception: ', '');
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to initiate online payment: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              return false;
            } finally {
              if (mounted) setState(() => _isProcessing = false);
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;
    final secondaryTextColor =
        isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor =
        isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);

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
                  width: 92,
                  height: 92,
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
                      size: 56,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  'Payment Incomplete',
                  style: AppTextStyles.headlineSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                Text(
                  'Your payment for airport transfer could not be completed. You can retry with a saved card or online payment.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: secondaryTextColor,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Amount Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: borderColor,
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 14,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Amount Due',
                            style: AppTextStyles.labelSmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '€${_amount.toStringAsFixed(2)}',
                        style: AppTextStyles.headlineLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 26,
                          color: isDark ? Colors.white : AppColors.backgroundDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Details Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
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
                        textColor: textColor,
                        secondaryColor: secondaryTextColor,
                        icon: Icons.local_taxi_rounded,
                      ),
                      const Divider(height: 20),
                      _buildDetailRow(
                        label: 'Service ID',
                        value: _bookingReference,
                        textColor: textColor,
                        secondaryColor: secondaryTextColor,
                        icon: Icons.tag_rounded,
                      ),
                      if (_errorMessage != null && _errorMessage!.isNotEmpty) ...[
                        const Divider(height: 20),
                        _buildDetailRow(
                          label: 'Reason',
                          value: _errorMessage!,
                          textColor: Colors.red[400] ?? Colors.red,
                          secondaryColor: secondaryTextColor,
                          icon: Icons.info_outline_rounded,
                        ),
                      ],
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 18,
                                color: Colors.orange[700],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Status',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: secondaryTextColor,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Payment Pending',
                              style: AppTextStyles.labelSmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.red[700],
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
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _openRetrySheet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.black,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.refresh_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Retry Payment',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _handleCancel,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Cancel & Return Home',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
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
    required Color textColor,
    required Color secondaryColor,
    required IconData icon,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: secondaryColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: secondaryColor,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
