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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Keep Booking',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Cancel Transfer'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isCancelling = true);
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

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Airport transfer cancelled successfully'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cancel booking: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isCancelling = false);
      }
    }
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
                          color: AppColors.backgroundDark.withOpacity(0.15),
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Summary Card with QR Code
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : Colors.grey.shade300,
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Booking Reference',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
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
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: statusColor.withOpacity(0.4)),
                        ),
                        child: Text(
                          status.replaceAll('_', ' '),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 130.0,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Present this QR code to your chauffeur upon pickup',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Chauffeur Transport Notice
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primaryGold.withOpacity(0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.primaryGold,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chauffeured Passenger Service',
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Your chauffeur meets you at the designated pickup point, assists with baggage, drives you to your destination, and completes drop-off. No vehicle handover or return required.',
                          style: AppTextStyles.bodySmall.copyWith(
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Live Journey Status Stepper
            if (!isCancelled) ...[
              _buildJourneyProgressCard(status, isDark),
              const SizedBox(height: 16),
            ],

            // Route Details Card
            _buildRouteCard(booking, isDark, isRound),

            const SizedBox(height: 16),

            // Flight & Meet & Greet Details Card
            _buildFlightDetailsCard(booking, isDark),

            const SizedBox(height: 16),

            // Vehicle & Chauffeur Card
            _buildVehicleAndDriverCard(vehicle, driver, isDark),

            const SizedBox(height: 16),

            // Passenger & Luggage Card
            _buildPassengerDetailsCard(booking, isDark),

            const SizedBox(height: 16),

            // Fare & Payment Breakdown Card
            _buildPaymentCard(booking, isDark),

            const SizedBox(height: 24),

            // Cancellation Button if eligible
            if (canCancel) ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: _isCancelling ? null : _handleCancelBooking,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
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
                            color: AppColors.error,
                          ),
                        )
                      : Text(
                          'Cancel Transfer Booking',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.error,
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transfer Progress',
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
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
                                  : Colors.grey.withOpacity(0.3),
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
                                  : Colors.grey.withOpacity(0.3),
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
                                    ? Colors.white
                                    : Colors.black)
                                : Colors.grey),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isRound ? 'Outbound Transfer' : 'Transfer Route',
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const Icon(
                    Icons.trip_origin_rounded,
                    size: 16,
                    color: Color(0xFF10B981),
                  ),
                  Container(
                    width: 2,
                    height: 28,
                    color: Colors.grey.withOpacity(0.35),
                  ),
                  const Icon(
                    Icons.place_rounded,
                    size: 16,
                    color: Colors.redAccent,
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pickup Location',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      booking['pickupLocation'] ?? 'N/A',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Drop-off Destination',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      booking['dropoffLocation'] ?? 'N/A',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isRound && booking['returnDateTime'] != null) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Return Transfer',
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _formatDateTime(booking['returnDateTime']),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.indigo,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    const Icon(
                      Icons.trip_origin_rounded,
                      size: 16,
                      color: Colors.indigo,
                    ),
                    Container(
                      width: 2,
                      height: 28,
                      color: Colors.grey.withOpacity(0.35),
                    ),
                    const Icon(
                      Icons.flight_land_rounded,
                      size: 16,
                      color: Colors.blueAccent,
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pickup for Return',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        booking['dropoffLocation'] ?? 'N/A',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Drop-off at Airport',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        booking['pickupLocation'] ?? 'N/A',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
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

  Widget _buildFlightDetailsCard(
      Map<String, dynamic> booking, bool isDark) {
    final flightNumber = booking['flightNumber']?.toString();
    final returnFlight = booking['returnFlightNumber']?.toString();
    final specialRequests = booking['specialRequests']?.toString();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.flight_takeoff_rounded,
                size: 18,
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              Text(
                'Flight & Meet & Greet',
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Outbound Flight',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(
                      flightNumber != null && flightNumber.isNotEmpty
                          ? flightNumber
                          : 'Not Provided',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: flightNumber != null ? Colors.blue : null,
                      ),
                    ),
                  ],
                ),
              ),
              if (returnFlight != null && returnFlight.isNotEmpty) ...[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Return Flight',
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        returnFlight,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.indigo,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (specialRequests != null && specialRequests.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Text(
              'Meet & Greet / Instructions',
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              specialRequests,
              style: AppTextStyles.bodySmall.copyWith(
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVehicleAndDriverCard(
      Map<String, dynamic>? vehicle, Map<String, dynamic>? driver, bool isDark) {
    final vehicleName = vehicle != null && vehicle['make'] != null
        ? '${vehicle['make']} ${vehicle['model'] ?? ''}'
        : 'Airport Transfer Vehicle';
    final registration = vehicle?['registrationNo']?.toString() ??
        vehicle?['vehicleType']?.toString() ??
        'N/A';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.directions_car_filled_rounded,
                size: 18,
                color: AppColors.primaryGold,
              ),
              const SizedBox(width: 8),
              Text(
                'Vehicle & Chauffeur',
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicleName,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.borderDark
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      'Plate: $registration',
                      style: AppTextStyles.labelSmall.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Assigned Chauffeur',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    driver != null
                        ? '${driver['firstName'] ?? ''} ${driver['lastName'] ?? ''}'
                        : 'Supplier Fleet',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: driver != null
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                  ),
                  if (driver?['phone'] != null)
                    Text(
                      driver!['phone'].toString(),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerDetailsCard(
      Map<String, dynamic> booking, bool isDark) {
    final leadName = (booking['leadPassengerName'] ?? 'Passenger').toString();
    final leadPhone = (booking['leadPassengerPhone'] ?? 'N/A').toString();
    final leadEmail = (booking['leadPassengerEmail'] ?? 'N/A').toString();
    final adults = booking['adults'] ?? 1;
    final children = booking['children'] ?? 0;
    final infants = booking['infants'] ?? 0;
    final standardLuggage = booking['standardLuggage'] ?? 0;
    final largeLuggage = booking['largeLuggage'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.people_alt_rounded,
                size: 18,
                color: AppColors.primaryGold,
              ),
              const SizedBox(width: 8),
              Text(
                'Lead Passenger & Guests',
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            leadName,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$leadPhone · $leadEmail',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.borderDark.withOpacity(0.4)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '$adults Adult${adults == 1 ? '' : 's'}${children > 0 ? ', $children Ch' : ''}${infants > 0 ? ', $infants Inf' : ''}',
                        style: AppTextStyles.labelSmall
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.borderDark.withOpacity(0.4)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.luggage_rounded, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '${standardLuggage + largeLuggage} Bag${(standardLuggage + largeLuggage) == 1 ? '' : 's'}',
                        style: AppTextStyles.labelSmall
                            .copyWith(fontWeight: FontWeight.w600),
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

  Widget _buildPaymentCard(
      Map<String, dynamic> booking, bool isDark) {
    final basePrice =
        double.tryParse((booking['basePrice'] ?? 0).toString()) ?? 0.0;
    final extrasFee =
        double.tryParse((booking['extrasFee'] ?? 0).toString()) ?? 0.0;
    final discount =
        double.tryParse((booking['discountAmount'] ?? 0).toString()) ?? 0.0;
    final grandTotal =
        double.tryParse((booking['grandTotal'] ?? 0).toString()) ?? 0.0;
    final currency = (booking['currency'] ?? 'EUR').toString();
    final paymentMethod =
        (booking['paymentMethod'] ?? 'CARD').toString();
    final paymentStatus =
        (booking['paymentStatus'] ?? 'PENDING').toString();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tariff & Payment',
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: paymentStatus == 'PAID'
                      ? AppColors.success.withOpacity(0.12)
                      : Colors.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  paymentStatus,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: paymentStatus == 'PAID'
                        ? AppColors.success
                        : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildPaymentRow('Base Transfer Tariff', '$currency ${basePrice.toStringAsFixed(2)}'),
          if (extrasFee > 0) ...[
            const SizedBox(height: 6),
            _buildPaymentRow('Extras / Meet & Greet', '$currency ${extrasFee.toStringAsFixed(2)}'),
          ],
          if (discount > 0) ...[
            const SizedBox(height: 6),
            _buildPaymentRow('Discount', '-$currency ${discount.toStringAsFixed(2)}', color: AppColors.success),
          ],
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount ($paymentMethod)',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$currency ${grandTotal.toStringAsFixed(2)}',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
