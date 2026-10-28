import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/app_date_utils.dart';
import '../../../airport_transfer/data/datasources/airport_transfer_remote_datasource.dart';
import '../../../../core/network/socket_service.dart';
import 'airport_transfers_history_view.dart';
import 'airport_transfer_cancellation_success_screen.dart';

final airportTransferBookingDetailsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, bookingId) async {
  final datasource = ref.read(airportTransferRemoteDatasourceProvider);

  final socketService = ref.read(socketServiceProvider);
  final sub = socketService.onAirportTransferStatusChanged.listen((event) {
    if (event['bookingId'] == bookingId) {
      ref.invalidateSelf();
    }
  });

  ref.onDispose(() {
    sub.cancel();
  });

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
    return AppDateUtils.formatDateTime(dateTimeStr);
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

  Future<void> _handleCancelBooking([Map<String, dynamic>? booking]) async {
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
              'Cancel Booking',
              style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to cancel this transfer booking? Any eligible paid amount will be refunded to your original payment method within 3-5 business days.',
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

                              Map<String, dynamic>? cancelResponse;
                              String? failureError;
                              try {
                                final datasource = ref.read(airportTransferRemoteDatasourceProvider);
                                cancelResponse = await datasource.cancelBooking(
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
                                await _showCancellationFailedModal(context, failureError, booking);
                              } else {
                                final double finalRefund = (cancelResponse?['refundAmount'] is num)
                                    ? (cancelResponse!['refundAmount'] as num).toDouble()
                                    : (booking?['grandTotal'] != null
                                        ? (double.tryParse(booking!['grandTotal'].toString()) ?? 0.0)
                                        : 0.0);
                                final String refundDays = cancelResponse?['refundDays']?.toString() ?? '3-5 business days';
                                final String refundStatus = cancelResponse?['refundStatus']?.toString() ?? 'REFUNDED';

                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => AirportTransferCancellationSuccessScreen(
                                      refundAmount: finalRefund,
                                      refundDays: refundDays,
                                      refundStatus: refundStatus,
                                    ),
                                  ),
                                );
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
                              'Cancel Booking',
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

  Future<void> _showCancellationFailedModal(
      BuildContext context, String rawError, [Map<String, dynamic>? booking]) async {
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
                        _handleCancelBooking(booking);
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
                        'Retry',
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
                      'Booking Details',
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
                    Text('Failed to load booking details',
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
    final status =
        (booking['status'] ?? 'CONFIRMED').toString().trim().toUpperCase();
    final isRound =
        (booking['transferType'] ?? '').toString().trim().toUpperCase() == 'ROUND_TRIP';
    final returnStatus =
        (booking['returnStatus'] ?? status).toString().trim().toUpperCase();
    final returnStatusColor = _getStatusColor(returnStatus);
    final statusColor = _getStatusColor(status);
    final isCancelled = status == 'CANCELLED' || status == 'REFUNDED';
    final canCancel =
        status == 'PENDING_APPROVAL' || status == 'CONFIRMED';
    final isFullyCompleted = isRound
        ? (status == 'COMPLETED' && returnStatus == 'COMPLETED')
        : (status == 'COMPLETED');
    final isFullyCancelled = isRound
        ? ((status == 'CANCELLED' || status == 'REFUNDED') &&
            (returnStatus == 'CANCELLED' || returnStatus == 'REFUNDED'))
        : (status == 'CANCELLED' || status == 'REFUNDED');

    final outboundDriver = _extractDriver(booking, leg: 'OUTBOUND');
    final returnDriver = isRound ? _extractDriver(booking, leg: 'RETURN') : null;

    final hasOutboundDriver = outboundDriver != null ||
        status == 'DRIVER_ASSIGNED' ||
        status == 'EN_ROUTE_TO_PICKUP' ||
        status == 'ARRIVED_AT_AIRPORT' ||
        status == 'PASSENGER_MET' ||
        status == 'IN_TRANSIT';

    final hasReturnDriver = returnDriver != null ||
        returnStatus == 'DRIVER_ASSIGNED' ||
        returnStatus == 'EN_ROUTE_TO_PICKUP' ||
        returnStatus == 'ARRIVED_AT_AIRPORT' ||
        returnStatus == 'PASSENGER_MET' ||
        returnStatus == 'IN_TRANSIT';

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
            // Top Summary Card (Service ID & Status)
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
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
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            bookingRef,
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              color: AppColors.primaryGold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isRound && !isFullyCompleted && !isFullyCancelled) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: statusColor.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            '🛫 Out: ${status.replaceAll('_', ' ')}',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 9.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: returnStatusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: returnStatusColor.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            '🛬 Ret: ${returnStatus.replaceAll('_', ' ')}',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: returnStatusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 9.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (isFullyCompleted
                                ? AppColors.success
                                : isFullyCancelled
                                    ? AppColors.error
                                    : statusColor)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: (isFullyCompleted
                                    ? AppColors.success
                                    : isFullyCancelled
                                        ? AppColors.error
                                        : statusColor)
                                .withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        isFullyCompleted
                            ? 'COMPLETED'
                            : isFullyCancelled
                                ? 'CANCELLED'
                                : status.replaceAll('_', ' '),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isFullyCompleted
                              ? AppColors.success
                              : isFullyCancelled
                                  ? AppColors.error
                                  : statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Live Journey Status Stepper or Completed Card
            if (isFullyCompleted) ...[
              _buildRideCompletedCard(booking, isRound, isDark),
              const SizedBox(height: 14),
            ] else if (!isCancelled) ...[
              if (isRound) ...[
                _buildJourneyProgressCard(status, isDark,
                    title: 'FIRST TRIP PROGRESS'),
                const SizedBox(height: 14),
                _buildJourneyProgressCard(returnStatus, isDark,
                    title: 'RETURN TRIP PROGRESS'),
                const SizedBox(height: 14),
              ] else ...[
                _buildJourneyProgressCard(status, isDark),
                const SizedBox(height: 14),
              ],
            ],

            // 4-Digit Verification PIN Card (Shown only AFTER supplier assigned self or driver, and while leg is active)
            if (!isFullyCompleted && !isCancelled) ...[
              if (hasOutboundDriver &&
                  booking['verificationPin'] != null &&
                  status != 'COMPLETED') ...[
                _buildVerificationPinCard(
                  booking['verificationPin'].toString(),
                  status,
                  isDark,
                  legPrefix: isRound ? 'First Trip' : null,
                ),
                const SizedBox(height: 12),
              ],
              if (isRound &&
                  hasReturnDriver &&
                  booking['returnVerificationPin'] != null &&
                  returnStatus != 'COMPLETED' &&
                  returnStatus != 'CANCELLED' &&
                  returnStatus != 'REFUNDED') ...[
                _buildVerificationPinCard(
                  booking['returnVerificationPin'].toString(),
                  returnStatus,
                  isDark,
                  legPrefix: 'Return Trip',
                ),
                const SizedBox(height: 12),
              ],
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

            // Vehicle & Driver Details Card
            _buildVehicleAndDriverCard(booking, isDark),

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
                  onPressed: _isCancelling ? null : () => _handleCancelBooking(booking),
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
                          'Cancel Booking',
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

  Widget _buildRideCompletedCard(
      Map<String, dynamic> booking, bool isRound, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isRound ? 'Round Trip Completed' : 'Ride Completed',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          Text(
            isRound
                ? 'Both your first trip and return trip have been successfully completed. Safe travels and thank you for choosing GoZolt!'
                : 'You have arrived safely at your destination. Thank you for choosing GoZolt!',
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppColors.textSecondary
                  : AppColors.textSecondaryLight,
              fontSize: 11.5,
              height: 1.35,
            ),
            textAlign: TextAlign.center,
          ),
          if (isRound) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF16161A)
                    : const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.flight_takeoff_rounded,
                          size: 15, color: AppColors.success),
                      const SizedBox(width: 5),
                      Text(
                        'First Trip: Completed',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textPrimary
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 14,
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.flight_land_rounded,
                          size: 15, color: AppColors.success),
                      const SizedBox(width: 5),
                      Text(
                        'Return Trip: Completed',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textPrimary
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVerificationPinCard(
      String pin, String currentStatus, bool isDark,
      {String? legPrefix}) {
    final normalized = currentStatus.trim().toUpperCase();
    if (normalized == 'COMPLETED' ||
        normalized == 'CANCELLED' ||
        normalized == 'REFUNDED') {
      return const SizedBox.shrink();
    }

    final isMet = normalized == 'PASSENGER_MET' || normalized == 'IN_TRANSIT';

    final label = isMet
        ? (legPrefix != null
            ? '$legPrefix Ride Verified'
            : 'Ride Verified & On Board')
        : (legPrefix != null
            ? '$legPrefix Verification PIN'
            : 'Ride Verification PIN');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isMet
            ? AppColors.success.withValues(alpha: 0.08)
            : AppColors.primaryGold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isMet
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.primaryGold.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isMet ? Icons.verified_rounded : Icons.shield_rounded,
                size: 15,
                color: isMet ? AppColors.success : AppColors.primaryGold,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isMet ? AppColors.success : AppColors.primaryGold,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          if (!isMet) ...[
            Text(
              'Share this 4-digit PIN with your driver to begin:',
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 10.5,
                color: isDark
                    ? AppColors.textSecondary
                    : AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: pin.split('').map((digit) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  width: 30,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E24) : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.primaryGold,
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGold.withValues(alpha: 0.1),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    digit,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryGold,
                    ),
                  ),
                );
              }).toList(),
            ),
          ] else ...[
            Text(
              'PIN Verified. Safe travels to your destination!',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.success,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildJourneyProgressCard(String currentStatus, bool isDark,
      {String? title}) {
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
                title ?? 'TRANSFER PROGRESS',
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
                    isRound ? 'FIRST TRIP' : 'JOURNEY ROUTE',
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
                      'RETURN TRIP',
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

  Map<String, String>? _extractDriver(Map<String, dynamic> booking, {String leg = 'OUTBOUND'}) {
    final tasks = booking['tasks'] as List<dynamic>?;
    if (tasks != null && tasks.isNotEmpty) {
      final targetLeg = leg.toUpperCase();
      dynamic matchedTask;
      for (final t in tasks) {
        if (t is Map) {
          final tLeg = (t['tripLeg'] ?? 'OUTBOUND').toString().toUpperCase();
          if (tLeg == targetLeg) {
            matchedTask = t;
            break;
          }
        }
      }

      // If OUTBOUND and no explicit leg was set on single task, fallback to first task
      if (matchedTask == null && targetLeg == 'OUTBOUND') {
        matchedTask = tasks.firstWhere(
          (t) => t is Map && ((t['tripLeg'] ?? '').toString().toUpperCase() != 'RETURN'),
          orElse: () => null,
        );
      }

      if (matchedTask is Map) {
        final task = Map<String, dynamic>.from(matchedTask);
        final worker = task['worker'] as Map<String, dynamic>?;
        final isSelf = task['selfAssigned'] == true;
        final supplier = booking['supplier'] as Map<String, dynamic>?;

        String? name;
        if (worker != null && worker['name'] != null && worker['name'].toString().trim().isNotEmpty) {
          name = worker['name'].toString().trim();
        } else if (task['assignedToName'] != null && task['assignedToName'].toString().trim().isNotEmpty) {
          name = task['assignedToName'].toString().trim();
        } else if (isSelf && supplier != null) {
          name = (supplier['ownerName'] ?? supplier['companyName'])?.toString().trim();
        } else if (isSelf) {
          name = 'Supplier Chauffeur';
        }

        if (name == null || name.isEmpty) {
          if (isSelf) {
            name = (supplier?['companyName'] ?? supplier?['ownerName'] ?? 'Supplier Chauffeur').toString().trim();
            if (name.isEmpty) name = 'Supplier Chauffeur';
          } else if (worker != null) {
            name = 'Assigned Driver';
          }
        }

        String? phone;
        if (worker != null && worker['phone'] != null && worker['phone'].toString().trim().isNotEmpty) {
          phone = worker['phone'].toString().trim();
        } else if (supplier != null && supplier['contactPhone'] != null && supplier['contactPhone'].toString().trim().isNotEmpty) {
          phone = supplier['contactPhone'].toString().trim();
        }

        String? email;
        if (worker != null && worker['email'] != null && worker['email'].toString().trim().isNotEmpty) {
          email = worker['email'].toString().trim();
        } else if (task['assignedToEmail'] != null && task['assignedToEmail'].toString().trim().isNotEmpty) {
          email = task['assignedToEmail'].toString().trim();
        } else if (supplier != null && supplier['email'] != null && supplier['email'].toString().trim().isNotEmpty) {
          email = supplier['email'].toString().trim();
        }

        if (name != null && name.isNotEmpty) {
          final result = <String, String>{
            'name': name,
            'role': isSelf ? 'Supplier Chauffeur' : 'Assigned Driver',
          };
          if (phone != null && phone.isNotEmpty) {
            result['phone'] = phone;
          }
          if (email != null && email.isNotEmpty) {
            result['email'] = email;
          }
          return result;
        }
      }
    }

    final driver = booking['driver'] as Map<String, dynamic>?;
    if (driver != null) {
      final first = (driver['firstName'] ?? '').toString().trim();
      final last = (driver['lastName'] ?? '').toString().trim();
      final name = '$first $last'.trim();
      final phone = (driver['phone'] ?? '').toString().trim();
      final email = (driver['email'] ?? '').toString().trim();

      if (name.isNotEmpty) {
        final result = <String, String>{
          'name': name,
          'role': 'Assigned Driver',
        };
        if (phone.isNotEmpty) {
          result['phone'] = phone;
        }
        if (email.isNotEmpty) {
          result['email'] = email;
        }
        return result;
      }
    }

    return null;
  }

  Future<void> _makePhoneCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri(scheme: 'tel', path: cleanPhone);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(uri);
      }
    } catch (_) {
      try {
        await launchUrl(uri);
      } catch (_) {
        await Clipboard.setData(ClipboardData(text: phone));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Phone number copied to clipboard: $phone'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _sendEmail(String email) async {
    final cleanEmail = email.trim();
    final uri = Uri(scheme: 'mailto', path: cleanEmail);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(uri);
      }
    } catch (_) {
      try {
        await launchUrl(uri);
      } catch (_) {
        await Clipboard.setData(ClipboardData(text: cleanEmail));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Email copied to clipboard: $cleanEmail'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildDriverBox({
    required String title,
    required Map<String, String> driverInfo,
    required bool isDark,
  }) {
    final name = driverInfo['name'] ?? 'Driver';
    final phone = driverInfo['phone'];
    final email = driverInfo['email'];

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 22,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
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
                      name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.textPrimary
                            : AppColors.textPrimaryLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        size: 11, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text(
                      'Assigned',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if ((phone != null && phone.isNotEmpty) ||
              (email != null && email.isNotEmpty)) ...[
            const SizedBox(height: 10),
            Divider(
              height: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            const SizedBox(height: 8),
          ],

          // Phone / Mobile Row
          if (phone != null && phone.isNotEmpty) ...[
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _makePhoneCall(phone),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.phone_rounded,
                          size: 15,
                          color: Colors.blue.shade400,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mobile Number',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: isDark
                                    ? AppColors.textSecondary
                                    : AppColors.textSecondaryLight,
                                fontSize: 9.5,
                              ),
                            ),
                            Text(
                              phone,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: isDark
                                    ? AppColors.textPrimary
                                    : AppColors.textPrimaryLight,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.call, size: 12, color: Colors.blue.shade400),
                            const SizedBox(width: 4),
                            Text(
                              'Call',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: Colors.blue.shade400,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          // Email Row
          if (email != null && email.isNotEmpty) ...[
            if (phone != null && phone.isNotEmpty) const SizedBox(height: 6),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _sendEmail(email),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.mail_outline_rounded,
                          size: 15,
                          color: Colors.purpleAccent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Email Address',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: isDark
                                    ? AppColors.textSecondary
                                    : AppColors.textSecondaryLight,
                                fontSize: 9.5,
                              ),
                            ),
                            Text(
                              email,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: isDark
                                    ? AppColors.textPrimary
                                    : AppColors.textPrimaryLight,
                                fontWeight: FontWeight.w500,
                                fontSize: 11.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.send_rounded,
                                size: 11, color: Colors.purpleAccent),
                            SizedBox(width: 4),
                            Text(
                              'Email',
                              style: TextStyle(
                                color: Colors.purpleAccent,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAwaitingDriverBox(bool isDark) {
    return Container(
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
              color: Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.schedule_rounded,
              size: 20,
              color: Colors.amber,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ASSIGNED DRIVER',
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
                  'Driver details will appear once assigned by the supplier.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondary
                        : AppColors.textSecondaryLight,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleAndDriverCard(
      Map<String, dynamic> booking, bool isDark) {
    final vehicle = booking['vehicle'] as Map<String, dynamic>?;
    final isRound =
        (booking['transferType'] ?? '').toString().toUpperCase() == 'ROUND_TRIP';

    final vehicleName = vehicle != null && vehicle['make'] != null
        ? '${vehicle['make']} ${vehicle['model'] ?? ''}'.trim()
        : 'Airport Transfer Vehicle';
    final registration = vehicle?['registrationNo']?.toString() ??
        vehicle?['vehicleType']?.toString() ??
        'N/A';

    final outboundDriver = _extractDriver(booking, leg: 'OUTBOUND');
    final returnDriver = isRound ? _extractDriver(booking, leg: 'RETURN') : null;

    final hasDriver = outboundDriver != null || returnDriver != null;

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
                'VEHICLE & DRIVER DETAILS',
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

          // Box 2: Driver Details (Supplier Partner Card removed)
          if (hasDriver) ...[
            const SizedBox(height: 10),
            if (outboundDriver != null) ...[
              _buildDriverBox(
                title: isRound ? 'FIRST TRIP DRIVER' : 'ASSIGNED DRIVER',
                driverInfo: outboundDriver,
                isDark: isDark,
              ),
            ],
            if (isRound &&
                returnDriver != null &&
                (returnDriver['name'] != outboundDriver?['name'] ||
                    returnDriver['phone'] != outboundDriver?['phone'])) ...[
              const SizedBox(height: 10),
              _buildDriverBox(
                title: 'RETURN TRIP DRIVER',
                driverInfo: returnDriver,
                isDark: isDark,
              ),
            ],
          ] else ...[
            const SizedBox(height: 10),
            _buildAwaitingDriverBox(isDark),
          ],
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
