import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../airport_transfer/data/datasources/airport_transfer_remote_datasource.dart';
import 'airport_transfers_history_view.dart';

final airportTransferBookingDetailsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, bookingId) async {
  final datasource = ref.read(airportTransferRemoteDatasourceProvider);
  return datasource.getBookingDetails(bookingId);
});

class AirportTransferHistoryDetailsScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const AirportTransferHistoryDetailsScreen({
    super.key,
    required this.bookingId,
  });

  @override
  ConsumerState<AirportTransferHistoryDetailsScreen> createState() =>
      _AirportTransferHistoryDetailsScreenState();
}

class _AirportTransferHistoryDetailsScreenState
    extends ConsumerState<AirportTransferHistoryDetailsScreen> {
  bool _isCancelling = false;

  String _formatDateTime(dynamic dateTimeStr) {
    if (dateTimeStr == null) return 'N/A';
    try {
      final dt = DateTime.parse(dateTimeStr.toString().replaceAll('Z', ''));
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    } catch (_) {
      return dateTimeStr.toString();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'CONFIRMED':
      case 'DRIVER_ASSIGNED':
        return Colors.blue;
      case 'EN_ROUTE_TO_PICKUP':
      case 'ARRIVED_AT_AIRPORT':
        return Colors.orange;
      case 'PASSENGER_MET':
      case 'IN_TRANSIT':
        return Colors.purple;
      case 'COMPLETED':
        return AppColors.success;
      case 'CANCELLED':
      case 'REFUNDED':
        return AppColors.error;
      case 'PENDING_PAYMENT':
      case 'PENDING_APPROVAL':
      default:
        return AppColors.primaryGold;
    }
  }

  int _getStatusStepIndex(String status) {
    switch (status) {
      case 'PENDING_APPROVAL':
      case 'PENDING_PAYMENT':
        return 0;
      case 'CONFIRMED':
      case 'DRIVER_ASSIGNED':
        return 1;
      case 'EN_ROUTE_TO_PICKUP':
        return 2;
      case 'ARRIVED_AT_AIRPORT':
        return 3;
      case 'PASSENGER_MET':
      case 'IN_TRANSIT':
        return 4;
      case 'COMPLETED':
        return 5;
      default:
        return 1;
    }
  }

  Future<void> _handleCancelBooking() async {
    final reasonController = TextEditingController();
    bool isCancellingInsideDialog = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: Theme.of(context).cardTheme.color,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Cancel Airport Transfer',
              style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to cancel this transfer booking?',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: reasonController,
                  enabled: !isCancellingInsideDialog,
                  decoration: InputDecoration(
                    hintText: 'Reason for cancellation (optional)',
                    hintStyle: AppTextStyles.bodySmall,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
            actionsPadding:
                const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 4),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isCancellingInsideDialog
                          ? null
                          : () => Navigator.pop(dialogCtx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Keep Booking',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isCancellingInsideDialog
                          ? null
                          : () async {
                              setDialogState(() => isCancellingInsideDialog = true);
                              setState(() => _isCancelling = true);

                              String? failureError;
                              try {
                                final datasource = ref.read(airportTransferRemoteDatasourceProvider);
                                await datasource.cancelBooking(
                                  widget.bookingId,
                                  reason: reasonController.text.trim().isNotEmpty
                                      ? reasonController.text.trim()
                                      : 'Customer requested cancellation',
                                );

                                ref.invalidate(
                                    airportTransferBookingDetailsProvider(widget.bookingId));
                                ref.invalidate(airportTransfersHistoryProvider);
                              } catch (e) {
                                failureError = e.toString().replaceAll('Exception: ', '').trim();
                                if (failureError.isEmpty) {
                                  failureError = 'Unable to cancel this booking. Please try again.';
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => _isCancelling = false);
                                }
                              }

                              if (dialogCtx.mounted) {
                                Navigator.of(dialogCtx).pop();
                              }

                              if (!mounted) return;

                              if (failureError != null) {
                                await _showCancellationFailedModal(context, failureError);
                              } else {
                                await _showCancellationSuccessModal(context);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: isCancellingInsideDialog
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Cancel Transfer',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showCancellationSuccessModal(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF10B981),
                    size: 44,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Booking Cancelled',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Your airport transfer booking has been cancelled successfully.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'If payment was completed, any eligible refund will be credited to your original payment method.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: (isDark ? AppColors.textSecondary : AppColors.textSecondaryLight).withValues(alpha: 0.8),
                  fontSize: 12,
                  height: 1.35,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
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

  Future<void> _showCancellationFailedModal(BuildContext context, String rawError) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String cleanMessage = rawError
        .replaceAll('Exception:', '')
        .replaceAll('DioException', '')
        .replaceAll('response:', '')
        .trim();
    if (cleanMessage.isEmpty) {
      cleanMessage = 'Unable to cancel this booking. Please check your connection and try again.';
    }

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.error,
                    size: 44,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Cancellation Failed',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                cleanMessage,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Dismiss',
                        style: TextStyle(
                          color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _handleCancelBooking();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Try Again',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asyncDetails =
        ref.watch(airportTransferBookingDetailsProvider(widget.bookingId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFD4A843), Color(0xFFF5C518)],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 20, 20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.backgroundDark.withValues(alpha: 0.15),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: AppColors.backgroundDark,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Transfer Details',
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.backgroundDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: asyncDetails.when(
              skipLoadingOnReload: true,
              data: (booking) => _buildContent(context, booking, isDark),
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primaryGold),
              ),
              error: (err, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.error, size: 48),
                    const SizedBox(height: 12),
                    Text('Failed to load transfer details',
                        style: AppTextStyles.titleSmall),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => ref.refresh(
                          airportTransferBookingDetailsProvider(
                              widget.bookingId)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGold,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, Map<String, dynamic> booking, bool isDark) {
    final bookingRef =
        (booking['bookingReference'] ?? 'GZLT-TRF').toString();
    final status = (booking['status'] ?? 'CONFIRMED').toString();
    final isRound = (booking['transferType'] ?? '') == 'ROUND_TRIP';
    final vehicle = booking['vehicle'] as Map<String, dynamic>?;
    final driver = booking['driver'] as Map<String, dynamic>?;
    final statusColor = _getStatusColor(status);
    final isCancelled = status == 'CANCELLED' || status == 'REFUNDED';
    final canCancel =
        status == 'PENDING_APPROVAL' || status == 'CONFIRMED';

    final qrData = '''
GOZOLT AIRPORT TRANSFER
Ref: $bookingRef
Passenger: ${booking['leadPassengerName'] ?? ''}
Type: ${isRound ? 'Round Trip' : 'One Way'}
Status: $status
'''
        .trim();

    return RefreshIndicator(
      color: AppColors.primaryGold,
      onRefresh: () => ref.refresh(
          airportTransferBookingDetailsProvider(widget.bookingId).future),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 26),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Summary Card with QR Code
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Service ID',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: isDark
                                  ? AppColors.textSecondary
                                  : AppColors.textSecondaryLight,
                              fontSize: 10,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            bookingRef,
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              color: AppColors.primaryGold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: statusColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          status.replaceAll('_', ' '),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                      ),
                      child: QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 130.0,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Present this QR code to your driver upon pickup',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textSecondary
                          : AppColors.textSecondaryLight,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Live Journey Status Stepper
            if (!isCancelled) ...[
              _buildJourneyProgressCard(status, isDark),
              const SizedBox(height: 14),
            ],

            // Route Details Card
            _buildRouteCard(booking, isDark, isRound),

            const SizedBox(height: 14),

            // Passenger & Contact Card
            _buildPassengerDetailsCard(booking, isDark),

            const SizedBox(height: 14),

            // Flight & Meet Details Card
            _buildFlightDetailsCard(booking, isDark, isRound),

            const SizedBox(height: 14),

            // Vehicle & Supplier Details Card
            _buildVehicleAndDriverCard(
                vehicle, driver, booking['supplier'] as Map<String, dynamic>?, isDark),

            const SizedBox(height: 14),

            // Fare & Payment Breakdown Card
            _buildPaymentCard(booking, isDark),

            const SizedBox(height: 20),

            // Cancellation Button if eligible
            if (canCancel) ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isCancelling ? null : _handleCancelBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isCancelling
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Cancel Transfer Booking',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildJourneyProgressCard(String currentStatus, bool isDark) {
    final stepIndex = _getStatusStepIndex(currentStatus);

    final steps = [
      'Confirmed',
      'En Route',
      'At Pickup',
      'In Transit',
      'Completed'
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.timeline_rounded,
                size: 19,
                color: AppColors.primaryGold,
              ),
              const SizedBox(width: 7),
              Text(
                'TRANSFER PROGRESS',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primaryGold,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(steps.length, (idx) {
              final isReached = idx < stepIndex;
              final isCurrent = idx == stepIndex - 1;

              return Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        if (idx > 0)
                          Expanded(
                            child: Container(
                              height: 3,
                              color: isReached
                                  ? AppColors.primaryGold
                                  : Colors.grey.withValues(alpha: 0.3),
                            ),
                          ),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isReached
                                ? AppColors.primaryGold
                                : (isDark
                                    ? AppColors.borderDark
                                    : Colors.grey.shade300),
                            border: isCurrent
                                ? Border.all(
                                    color: Colors.white, width: 2)
                                : null,
                          ),
                          child: Center(
                            child: isReached
                                ? const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.white,
                                  )
                                : Text(
                                    '${idx + 1}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                          ),
                        ),
                        if (idx < steps.length - 1)
                          Expanded(
                            child: Container(
                              height: 3,
                              color: (idx + 1 < stepIndex)
                                  ? AppColors.primaryGold
                                  : Colors.grey.withValues(alpha: 0.3),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      steps[idx],
                      textAlign: TextAlign.center,
                      style: AppTextStyles.labelSmall.copyWith(
                        fontSize: 9.5,
                        fontWeight:
                            isCurrent ? FontWeight.bold : FontWeight.w500,
                        color: isCurrent
                            ? AppColors.primaryGold
                            : (isReached
                                ? (isDark
                                    ? AppColors.textPrimary
                                    : AppColors.textPrimaryLight)
                                : (isDark
                                    ? AppColors.textSecondary
                                    : AppColors.textSecondaryLight)),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(
      Map<String, dynamic> booking, bool isDark, bool isRound) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isRound ? Icons.flight_takeoff_rounded : Icons.route_outlined,
                    size: 19,
                    color: AppColors.primaryGold,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    isRound ? 'OUTBOUND TRANSFER' : 'JOURNEY ROUTE',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.primaryGold,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.7,
                    ),
                  ),
                ],
              ),
              Text(
                _formatDateTime(booking['pickupDateTime']),
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primaryGold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const Icon(
                    Icons.radio_button_checked,
                    size: 18,
                    color: Color(0xFF43A047),
                  ),
                  Container(
                    width: 2,
                    height: 28,
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                  const Icon(
                    Icons.location_on_rounded,
                    size: 18,
                    color: Color(0xFFE15B5B),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PICKUP',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isDark
                            ? AppColors.textSecondary
                            : AppColors.textSecondaryLight,
                        letterSpacing: 0.7,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      booking['pickupLocation'] ?? 'N/A',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textPrimary
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'DROP-OFF',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isDark
                            ? AppColors.textSecondary
                            : AppColors.textSecondaryLight,
                        letterSpacing: 0.7,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      booking['dropoffLocation'] ?? 'N/A',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textPrimary
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isRound && booking['returnDateTime'] != null) ...[
            const SizedBox(height: 13),
            Divider(
              height: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            const SizedBox(height: 13),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.flight_land_rounded,
                      size: 19,
                      color: AppColors.primaryGold,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'RETURN TRANSFER',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.primaryGold,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ],
                ),
                Text(
                  _formatDateTime(booking['returnDateTime']),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primaryGold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    const Icon(
                      Icons.radio_button_checked,
                      size: 18,
                      color: Color(0xFF43A047),
                    ),
                    Container(
                      width: 2,
                      height: 28,
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                    const Icon(
                      Icons.location_on_rounded,
                      size: 18,
                      color: Color(0xFFE15B5B),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PICKUP',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.textSecondary
                              : AppColors.textSecondaryLight,
                          letterSpacing: 0.7,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        booking['dropoffLocation'] ?? 'N/A',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textPrimary
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'DROP-OFF',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.textSecondary
                              : AppColors.textSecondaryLight,
                          letterSpacing: 0.7,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        booking['pickupLocation'] ?? 'N/A',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textPrimary
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Map<String, dynamic> _parseSpecialRequests(String? specialRequests) {
    final parsed = <String, String>{};
    final extraNotes = <String>[];

    if (specialRequests != null && specialRequests.trim().isNotEmpty) {
      final parts = specialRequests.split(RegExp(r'\s*\|\s*|\n+'));
      for (final rawPart in parts) {
        final part = rawPart.trim();
        if (part.isEmpty) continue;
        final colonIdx = part.indexOf(':');
        if (colonIdx > 0) {
          final key = part.substring(0, colonIdx).trim().toLowerCase();
          final val = part.substring(colonIdx + 1).trim();
          parsed[key] = val;
        } else {
          extraNotes.add(part);
        }
      }
    }

    String? findVal(List<String> keys) {
      for (final k in keys) {
        final v = parsed[k.toLowerCase()];
        if (v != null && v.isNotEmpty) return v;
      }
      return null;
    }

    return {
      'airline': findVal(['Airline', 'Flight Airline']),
      'terminal': findVal(['Terminal', 'Arrival Terminal', 'Gate']),
      'nationality': findVal(['Nationality', 'Country']),
      'whatsApp': findVal([
        'WhatsApp',
        'Whatsapp Number',
        'WhatsApp Phone',
        'Phone'
      ]),
      'welcomeSign': findVal([
        'Meet & Greet Sign',
        'Welcome Sign',
        'Driver Welcome Sign',
        'Driver Sign',
        'Sign Name',
        'Sign'
      ]),
      'meetInstructions': findVal([
        'Meet Instructions',
        'Meeting Instructions',
        'Instructions',
        'Pickup Instructions'
      ]),
      'specialAssistance': findVal([
        'Special Assistance',
        'Special Assistance & Requirements',
        'Assistance',
        'Special Requests',
        'Child Seat'
      ]),
      'extraNotes': extraNotes,
    };
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    String? value,
    Widget? trailing,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppColors.textSecondary
                  : AppColors.textSecondaryLight,
              fontWeight: FontWeight.w400,
              height: 1.3,
            ),
          ),
        ),
        const SizedBox(width: 12),
        if (trailing != null)
          trailing
        else if (value != null)
          Text(
            value.isEmpty ? 'Not provided' : value,
            textAlign: TextAlign.right,
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppColors.textPrimary
                  : AppColors.textPrimaryLight,
              height: 1.3,
            ),
          ),
      ],
    );
  }

  Widget _buildPassengerDetailsCard(
      Map<String, dynamic> booking, bool isDark) {
    final leadName = (booking['leadPassengerName'] ?? 'Passenger').toString();
    final leadPhone = (booking['leadPassengerPhone'] ?? 'N/A').toString();
    final leadEmail = (booking['leadPassengerEmail'] ?? 'N/A').toString();
    final special = _parseSpecialRequests(booking['specialRequests']?.toString());
    final whatsApp = special['whatsApp'] as String?;
    final nationality = special['nationality'] as String?;
    final displayWhatsApp = (whatsApp != null && whatsApp.isNotEmpty)
        ? whatsApp
        : leadPhone;
    final displayNationality = (nationality != null && nationality.isNotEmpty)
        ? nationality
        : 'Maltese';

    final int adults = booking['adults'] is int
        ? booking['adults'] as int
        : int.tryParse(booking['adults']?.toString() ?? '1') ?? 1;
    final int children = booking['children'] is int
        ? booking['children'] as int
        : int.tryParse(booking['children']?.toString() ?? '0') ?? 0;
    final int infants = booking['infants'] is int
        ? booking['infants'] as int
        : int.tryParse(booking['infants']?.toString() ?? '0') ?? 0;

    final passengerParts = <String>[];
    if (adults > 0) {
      passengerParts.add('$adults ${adults == 1 ? 'Adult' : 'Adults'}');
    }
    if (children > 0) {
      passengerParts.add('$children ${children == 1 ? 'Child' : 'Children'}');
    }
    if (infants > 0) {
      passengerParts.add('$infants ${infants == 1 ? 'Infant' : 'Infants'}');
    }
    final passengerSummary = passengerParts.isNotEmpty
        ? passengerParts.join(', ')
        : '1 Adult';

    final standardLuggage = booking['standardLuggage'] ?? 0;
    final largeLuggage = booking['largeLuggage'] ?? 0;
    final sLug = standardLuggage is int
        ? standardLuggage
        : int.tryParse(standardLuggage.toString()) ?? 0;
    final lLug = largeLuggage is int
        ? largeLuggage
        : int.tryParse(largeLuggage.toString()) ?? 0;
    final totalBags = sLug + lLug;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.person_outline_rounded,
                size: 19,
                color: AppColors.primaryGold,
              ),
              const SizedBox(width: 7),
              Text(
                'PASSENGER & CONTACT',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primaryGold,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),

          // Primary passenger
          _buildInfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Primary passenger',
            value: leadName,
            isDark: isDark,
          ),
          Divider(
            height: 20,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),

          // Phone
          _buildInfoRow(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: leadPhone,
            isDark: isDark,
          ),
          Divider(
            height: 20,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),

          // Email
          _buildInfoRow(
            icon: Icons.mail_outline_rounded,
            label: 'Email',
            value: leadEmail,
            isDark: isDark,
          ),
          Divider(
            height: 20,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),

          // WhatsApp
          _buildInfoRow(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'WhatsApp',
            value: displayWhatsApp,
            isDark: isDark,
          ),
          Divider(
            height: 20,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),

          // Nationality
          _buildInfoRow(
            icon: Icons.public_rounded,
            label: 'Nationality',
            value: displayNationality,
            isDark: isDark,
          ),

          // Guests & Luggage summary row
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.inputDark.withValues(alpha: 0.5)
                        : const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_rounded,
                        size: 16,
                        color: AppColors.primaryGold,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          passengerSummary,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.textPrimary
                                : AppColors.textPrimaryLight,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.inputDark.withValues(alpha: 0.5)
                        : const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.luggage_rounded,
                        size: 16,
                        color: AppColors.primaryGold,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$totalBags Bag${totalBags == 1 ? '' : 's'}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.textPrimary
                                : AppColors.textPrimaryLight,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFlightDetailsCard(
      Map<String, dynamic> booking, bool isDark, bool isRound) {
    final flightNumber = booking['flightNumber']?.toString();
    final returnFlight = booking['returnFlightNumber']?.toString();
    final special = _parseSpecialRequests(booking['specialRequests']?.toString());
    final airline = special['airline'] as String?;
    final terminal = special['terminal'] as String?;
    final welcomeSign = special['welcomeSign'] as String?;
    final meetInstructions = special['meetInstructions'] as String?;
    final specialAssistance = special['specialAssistance'] as String?;
    final extraNotes = (special['extraNotes'] as List<String>?) ?? [];

    final leadName = (booking['leadPassengerName'] ?? 'Passenger').toString();
    final rawSign = (welcomeSign != null && welcomeSign.trim().isNotEmpty)
        ? welcomeSign.trim().replaceAll('"', '')
        : leadName;
    final displaySign = '"$rawSign"';

    final displayMeetInstructions =
        (meetInstructions != null && meetInstructions.trim().isNotEmpty)
            ? meetInstructions.trim()
            : 'Meet driver at the arrivals hall with your welcome sign';

    final displaySpecialAssistance =
        (specialAssistance != null && specialAssistance.trim().isNotEmpty)
            ? specialAssistance.trim()
            : '1 Child seat, chair assistance';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.flight_rounded,
                size: 19,
                color: AppColors.primaryGold,
              ),
              const SizedBox(width: 7),
              Text(
                'FLIGHT & MEET DETAILS',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primaryGold,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),

          // Flight number (Incoming flight)
          _buildInfoRow(
            icon: Icons.flight_land_rounded,
            label: isRound ? 'Incoming flight' : 'Flight number',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.primaryGold.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Text(
                flightNumber != null && flightNumber.isNotEmpty
                    ? flightNumber
                    : 'N/A',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primaryGold,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            isDark: isDark,
          ),

          // Return flight number (Outgoing flight for return transfer)
          if (isRound && returnFlight != null && returnFlight.isNotEmpty) ...[
            Divider(
              height: 20,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            _buildInfoRow(
              icon: Icons.flight_takeoff_rounded,
              label: 'Return flight',
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.indigo.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Text(
                  returnFlight,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.indigo,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              isDark: isDark,
            ),
          ],

          // Airline
          if (airline != null && airline.isNotEmpty) ...[
            Divider(
              height: 20,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            _buildInfoRow(
              icon: Icons.airlines_outlined,
              label: 'Airline',
              value: airline,
              isDark: isDark,
            ),
          ],

          // Terminal
          if (terminal != null && terminal.isNotEmpty) ...[
            Divider(
              height: 20,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            _buildInfoRow(
              icon: Icons.meeting_room_outlined,
              label: 'Terminal',
              value: terminal,
              isDark: isDark,
            ),
          ],

          // Meet & Greet
          Divider(
            height: 20,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          _buildInfoRow(
            icon: Icons.handshake_outlined,
            label: 'Meet & Greet',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 12,
                    color: Color(0xFF10B981),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Included',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: const Color(0xFF10B981),
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            isDark: isDark,
          ),

          // 1. DRIVER WELCOME SIGN Box
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryGold.withValues(alpha: isDark ? 0.08 : 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primaryGold.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.badge_outlined,
                    size: 18,
                    color: AppColors.primaryGold,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DRIVER WELCOME SIGN',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.textSecondary
                              : AppColors.textSecondaryLight,
                          fontSize: 10,
                          letterSpacing: 0.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        displaySign,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textPrimary
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Meeting Instructions Box
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.backgroundDark.withValues(alpha: 0.5)
                  : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.directions_walk_rounded,
                  size: 18,
                  color: AppColors.primaryGold,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Meeting Instructions',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.textSecondary
                              : AppColors.textSecondaryLight,
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displayMeetInstructions,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.textPrimary
                              : AppColors.textPrimaryLight,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. Special Assistance Box
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceDark
                  : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.accessible_rounded,
                    size: 16,
                    color: Color(0xFF2196F3),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SPECIAL ASSISTANCE & REQUIREMENTS',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.textSecondary
                              : AppColors.textSecondaryLight,
                          fontSize: 10,
                          letterSpacing: 0.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        displaySpecialAssistance,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.textPrimary
                              : AppColors.textPrimaryLight,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Any extra unparsed notes
          for (final note in extraNotes) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                note,
                style: AppTextStyles.bodySmall.copyWith(
                  height: 1.35,
                  color: isDark
                      ? AppColors.textSecondary
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVehicleAndDriverCard(
      Map<String, dynamic>? vehicle,
      Map<String, dynamic>? driver,
      Map<String, dynamic>? supplier,
      bool isDark) {
    final vehicleName = vehicle != null && vehicle['make'] != null
        ? '${vehicle['make']} ${vehicle['model'] ?? ''}'.trim()
        : 'Airport Transfer Vehicle';
    final registration = vehicle?['registrationNo']?.toString() ??
        vehicle?['vehicleType']?.toString() ??
        'N/A';

    final supplierName = supplier?['companyName']?.toString() ??
        vehicle?['supplier']?['companyName']?.toString() ??
        'Supplier Partner';
    final driverName = driver != null
        ? '${driver['firstName'] ?? ''} ${driver['lastName'] ?? ''}'.trim()
        : null;

    final hasDriver = driverName != null && driverName.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.airport_shuttle_outlined,
                size: 19,
                color: AppColors.primaryGold,
              ),
              const SizedBox(width: 7),
              Text(
                'VEHICLE & SUPPLIER DETAILS',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primaryGold,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),

          // Box 1: Assigned Vehicle
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.inputDark.withValues(alpha: 0.5)
                  : const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.airport_shuttle_rounded,
                    size: 20,
                    color: AppColors.primaryGold,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ASSIGNED VEHICLE',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.textSecondary
                              : AppColors.textSecondaryLight,
                          fontSize: 10,
                          letterSpacing: 0.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        vehicleName,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.textPrimary
                              : AppColors.textPrimaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          registration,
                          style: AppTextStyles.labelSmall.copyWith(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            letterSpacing: 0.5,
                            color: isDark
                                ? AppColors.textPrimary
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Box 2: Supplier Partner / Assigned Driver
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.inputDark.withValues(alpha: 0.5)
                  : const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    hasDriver ? Icons.person_rounded : Icons.business_rounded,
                    size: 20,
                    color: Colors.blue.shade600,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasDriver ? 'ASSIGNED DRIVER' : 'SUPPLIER PARTNER',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.textSecondary
                              : AppColors.textSecondaryLight,
                          fontSize: 10,
                          letterSpacing: 0.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        hasDriver ? driverName : supplierName,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.textPrimary
                              : AppColors.textPrimaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(
      Map<String, dynamic> booking, bool isDark) {
    final extrasFee =
        double.tryParse((booking['extrasFee'] ?? 0).toString()) ?? 0.0;
    final discount =
        double.tryParse((booking['discountAmount'] ?? 0).toString()) ?? 0.0;
    final grandTotal =
        double.tryParse((booking['grandTotal'] ?? 0).toString()) ?? 0.0;
    final currency = (booking['currency'] ?? 'EUR').toString();
    final rawPaymentMethod =
        (booking['paymentMethod'] ?? 'CARD').toString();
    final paymentMethod = rawPaymentMethod.toUpperCase() == 'CARD'
        ? 'Card'
        : (rawPaymentMethod.toUpperCase() == 'ONLINE'
            ? 'Online'
            : (rawPaymentMethod.toUpperCase() == 'CASH'
                ? 'Cash'
                : rawPaymentMethod));
    final paymentStatus =
        (booking['paymentStatus'] ?? 'PENDING').toString().toUpperCase();
    final isPaid = paymentStatus == 'PAID' || paymentStatus == 'COMPLETED';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.receipt_long_outlined,
                size: 19,
                color: AppColors.primaryGold,
              ),
              const SizedBox(width: 7),
              Text(
                'PAYMENT SUMMARY',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primaryGold,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),

          // 1. Payment Status row
          _buildInfoRow(
            icon: isPaid
                ? Icons.check_circle_outline_rounded
                : Icons.schedule_rounded,
            label: 'Payment Status',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isPaid
                    ? const Color(0xFF10B981).withValues(alpha: 0.12)
                    : Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isPaid
                      ? const Color(0xFF10B981).withValues(alpha: 0.35)
                      : Colors.orange.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPaid
                        ? Icons.check_circle_rounded
                        : Icons.schedule_rounded,
                    size: 12,
                    color: isPaid
                        ? const Color(0xFF10B981)
                        : Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    paymentStatus,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isPaid
                          ? const Color(0xFF10B981)
                          : Colors.orange,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            isDark: isDark,
          ),

          // 2. Payment Method row
          Divider(
            height: 20,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          _buildInfoRow(
            icon: Icons.credit_card_outlined,
            label: 'Payment Method',
            trailing: Text(
              paymentMethod,
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? AppColors.textPrimary
                    : AppColors.textPrimaryLight,
                height: 1.3,
              ),
            ),
            isDark: isDark,
          ),

          // Extra Services row if fee > 0
          if (extrasFee > 0) ...[
            Divider(
              height: 20,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            _buildInfoRow(
              icon: Icons.add_circle_outline_rounded,
              label: 'Extra Services',
              trailing: Text(
                '$currency ${extrasFee.toStringAsFixed(2)}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.textPrimary
                      : AppColors.textPrimaryLight,
                  height: 1.3,
                ),
              ),
              isDark: isDark,
            ),
          ],

          // Discount row if applicable
          if (discount > 0) ...[
            Divider(
              height: 20,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            _buildInfoRow(
              icon: Icons.local_offer_outlined,
              label: 'Discount',
              trailing: Text(
                '-$currency ${discount.toStringAsFixed(2)}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: const Color(0xFF10B981),
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
              isDark: isDark,
            ),
          ],

          // Total Highlight Row (matching Review & Book)
          const SizedBox(height: 3),
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: Text(
                  isPaid ? 'Total Paid' : 'Total Amount',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.textPrimary
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$currency ${grandTotal.toStringAsFixed(2)}',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.primaryGold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
