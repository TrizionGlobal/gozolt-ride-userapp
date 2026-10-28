import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/app_date_utils.dart';
import '../../data/datasources/airport_transfer_remote_datasource.dart';
import '../providers/airport_transfer_provider.dart';
import '../providers/airport_transfer_passenger_provider.dart';
import '../providers/airport_transfer_vehicle_provider.dart';
import '../../../history/presentation/providers/history_providers.dart';
import '../../../home/presentation/providers/home_providers.dart';

class AirportTransferPaymentConfirmationScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final String? bookingReference;
  final String? serviceTitle;
  final double amount;
  final String paymentMethod;
  final String? stripePaymentIntentId;
  final String? pickupLocation;
  final String? dropoffLocation;
  final String? pickupDateTime;
  final String? returnDateTime;
  final VoidCallback? onDone;

  const AirportTransferPaymentConfirmationScreen({
    super.key,
    required this.bookingId,
    this.bookingReference,
    this.serviceTitle = 'Airport Transfer',
    required this.amount,
    this.paymentMethod = 'Online Payment (Stripe)',
    this.stripePaymentIntentId,
    this.pickupLocation,
    this.dropoffLocation,
    this.pickupDateTime,
    this.returnDateTime,
    this.onDone,
  });

  @override
  ConsumerState<AirportTransferPaymentConfirmationScreen> createState() =>
      _AirportTransferPaymentConfirmationScreenState();
}

class _AirportTransferPaymentConfirmationScreenState
    extends ConsumerState<AirportTransferPaymentConfirmationScreen> {
  late String _bookingId;
  String? _bookingReference;
  late String _serviceTitle;
  late double _amount;
  late String _paymentMethod;
  String? _pickupLocation;
  String? _dropoffLocation;
  String? _pickupDateTime;
  String? _returnDateTime;

  String _formatServiceId(String? ref, String id) {
    if (ref != null && ref.trim().isNotEmpty) {
      final trimmed = ref.trim();
      if (trimmed.startsWith('GZLT-TRF-')) return trimmed;
      if (trimmed.startsWith('TRF-')) return 'GZLT-$trimmed';
      if (!trimmed.contains('-') && trimmed.length >= 6) {
        return 'GZLT-TRF-$trimmed';
      }
      return trimmed;
    }
    if (id.trim().isNotEmpty) {
      final trimmed = id.trim();
      if (trimmed.startsWith('GZLT-TRF-')) return trimmed;
      if (trimmed.startsWith('TRF-')) return 'GZLT-$trimmed';
      final clean = trimmed.replaceAll('-', '').toUpperCase();
      if (clean.length >= 7) {
        return 'GZLT-TRF-${clean.substring(0, 7)}';
      }
      return 'GZLT-TRF-$trimmed';
    }
    return 'GZLT-TRF';
  }

  @override
  void initState() {
    super.initState();
    _bookingId = widget.bookingId;
    _bookingReference = widget.bookingReference;

    // Check if bookingId itself is in GZLT-TRF- format
    if (_bookingReference == null || _bookingReference!.isEmpty) {
      if (widget.bookingId.startsWith('GZLT-') || widget.bookingId.startsWith('TRF-')) {
        _bookingReference = widget.bookingId;
      }
    }

    // If serviceTitle contains reference like (GZLT-TRF-994230...), extract it
    if (_bookingReference == null || _bookingReference!.isEmpty) {
      final match = RegExp(r'GZLT-TRF-[A-Za-z0-9_-]+').firstMatch(widget.serviceTitle ?? '');
      if (match != null) {
        _bookingReference = match.group(0);
      }
    }

    // Always display clean "Airport Transfer" as requested
    _serviceTitle = 'Airport Transfer';
    _amount = widget.amount;
    _paymentMethod = widget.paymentMethod;
    _pickupLocation = widget.pickupLocation;
    _dropoffLocation = widget.dropoffLocation;
    _pickupDateTime = widget.pickupDateTime;
    _returnDateTime = widget.returnDateTime;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(airportTransferDraftProvider.notifier).reset();
      ref.read(airportTransferPassengerDetailsProvider.notifier).reset();
      ref.read(selectedAirportTransferVehicleProvider.notifier).clear();
    });

    if (_bookingId.isNotEmpty) {
      _loadDynamicDetails();
    }
  }

  Future<void> _loadDynamicDetails() async {
    try {
      final res = await ref
          .read(airportTransferRemoteDatasourceProvider)
          .verifyPayment(_bookingId);
      if (mounted) {
        setState(() {
          if (res['booking'] != null) {
            final b = res['booking'];
            if (b['bookingReference'] != null && b['bookingReference'].toString().isNotEmpty) {
              _bookingReference = b['bookingReference'].toString();
            }
            if (b['pickupLocation'] != null) _pickupLocation = b['pickupLocation'].toString();
            if (b['dropoffLocation'] != null) _dropoffLocation = b['dropoffLocation'].toString();
            if (b['pickupDateTime'] != null) _pickupDateTime = b['pickupDateTime'].toString();
            if (b['returnDateTime'] != null) _returnDateTime = b['returnDateTime'].toString();
          }
          if (res['bookingReference'] != null && res['bookingReference'].toString().isNotEmpty) {
            _bookingReference = res['bookingReference'].toString();
          }
          if (res['amount'] is num) {
            _amount = (res['amount'] as num).toDouble();
          }
        });
      }
    } catch (_) {}
  }

  void _handleDone() {
    if (widget.onDone != null) {
      widget.onDone!();
      return;
    }
    context.goNamed(RouteNames.home);
  }

  void _goToMyTransfers() {
    ref.read(historyTabSelectionProvider.notifier).state = 4;
    ref.read(homeTabIndexProvider.notifier).state = 1;
    context.goNamed(RouteNames.home);
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

    final displayBookingRef = _formatServiceId(_bookingReference, _bookingId);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleDone();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              children: [
                const SizedBox(height: 12),

                // Animated/Styled Success Icon
                Container(
                  width: 92,
                  height: 92,
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
                      size: 56,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Success Title
                Text(
                  'Payment Confirmed!',
                  style: AppTextStyles.headlineSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                Text(
                  'Your airport transfer payment has been received successfully! Your booking is pending supplier confirmation.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: secondaryTextColor,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

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
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 14,
                            color: Colors.green[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Total Amount Paid',
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
                        icon: Icons.airport_shuttle_rounded,
                      ),
                      const Divider(height: 20),
                      _buildDetailRow(
                        label: 'Service ID',
                        value: displayBookingRef,
                        textColor: textColor,
                        secondaryColor: secondaryTextColor,
                        icon: Icons.tag_rounded,
                        isMonospace: true,
                        isBold: true,
                        customValueColor: AppColors.primaryGold,
                      ),
                      if (_pickupLocation != null && _pickupLocation!.isNotEmpty) ...[
                        const Divider(height: 20),
                        _buildDetailRow(
                          label: 'Pickup',
                          value: _pickupLocation!,
                          textColor: textColor,
                          secondaryColor: secondaryTextColor,
                          icon: Icons.flight_takeoff_rounded,
                        ),
                      ],
                      if (_dropoffLocation != null && _dropoffLocation!.isNotEmpty) ...[
                        const Divider(height: 20),
                        _buildDetailRow(
                          label: 'Drop-off',
                          value: _dropoffLocation!,
                          textColor: textColor,
                          secondaryColor: secondaryTextColor,
                          icon: Icons.flight_land_rounded,
                        ),
                      ],
                      if (_pickupDateTime != null && _pickupDateTime!.isNotEmpty) ...[
                        const Divider(height: 20),
                        _buildDetailRow(
                          label: (_returnDateTime != null && _returnDateTime!.isNotEmpty)
                              ? 'First Trip Schedule'
                              : 'Schedule',
                          value: AppDateUtils.formatDateTime(_pickupDateTime),
                          textColor: textColor,
                          secondaryColor: secondaryTextColor,
                          icon: Icons.calendar_today_rounded,
                        ),
                      ],
                      if (_returnDateTime != null && _returnDateTime!.isNotEmpty) ...[
                        const Divider(height: 20),
                        _buildDetailRow(
                          label: 'Return Trip Schedule',
                          value: AppDateUtils.formatDateTime(_returnDateTime),
                          textColor: textColor,
                          secondaryColor: secondaryTextColor,
                          icon: Icons.event_repeat_rounded,
                        ),
                      ],
                      const Divider(height: 20),
                      _buildDetailRow(
                        label: 'Payment Method',
                        value: _paymentMethod
                            .replaceAll(' (Stripe)', '')
                            .replaceAll('(Stripe)', '')
                            .trim(),
                        textColor: textColor,
                        secondaryColor: secondaryTextColor,
                        icon: Icons.payment_rounded,
                      ),
                      const Divider(height: 20),
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
                                'Payment Status',
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
                              color: Colors.green.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Successful',
                              style: AppTextStyles.labelSmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.green[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _goToMyTransfers,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'View My Bookings',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: Colors.white,
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
                    onPressed: _handleDone,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Back to Home',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w600,
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
    required Color textColor,
    required Color secondaryColor,
    required IconData icon,
    bool isMonospace = false,
    bool isBold = false,
    Color? customValueColor,
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
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontFamily: isMonospace ? 'monospace' : null,
              color: customValueColor ?? textColor,
              letterSpacing: isMonospace ? 0.5 : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
