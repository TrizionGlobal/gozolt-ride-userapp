import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/network/socket_service.dart';
import '../../../../core/utils/app_date_utils.dart';
import '../../../airport_transfer/data/datasources/airport_transfer_remote_datasource.dart';

final airportTransfersHistoryProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final datasource = ref.read(airportTransferRemoteDatasourceProvider);

  final socketService = ref.read(socketServiceProvider);
  final sub = socketService.onAirportTransferStatusChanged.listen((_) {
    ref.invalidateSelf();
  });

  ref.onDispose(() {
    sub.cancel();
  });

  return datasource.getMyBookings();
});

class AirportTransfersHistoryView extends ConsumerStatefulWidget {
  const AirportTransfersHistoryView({super.key});

  @override
  ConsumerState<AirportTransfersHistoryView> createState() =>
      _AirportTransfersHistoryViewState();
}

class _AirportTransfersHistoryViewState
    extends ConsumerState<AirportTransfersHistoryView> {
  String _selectedFilter = 'All';
  StreamSubscription? _socketSub;

  final List<String> _filters = [
    'All',
    'Pending',
    'Confirmed',
    'In Progress',
    'Completed',
    'Cancelled'
  ];

  @override
  void initState() {
    super.initState();
    // 1. Ensure user socket connection is active
    ref.read(socketServiceProvider).connect();

    // 2. Real-time WebSocket listener for immediate instant updates
    _socketSub = ref.read(socketServiceProvider).onAirportTransferStatusChanged.listen((_) {
      if (mounted) {
        ref.invalidate(airportTransfersHistoryProvider);
      }
    });
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    super.dispose();
  }

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

  String _getStatusLabel(String status) {
    switch (status) {
      case 'PENDING_APPROVAL':
        return 'Pending Approval';
      case 'CONFIRMED':
        return 'Confirmed';
      case 'DRIVER_ASSIGNED':
        return 'Driver Assigned';
      case 'EN_ROUTE_TO_PICKUP':
        return 'En Route to Pickup';
      case 'ARRIVED_AT_AIRPORT':
        return 'Arrived at Pickup';
      case 'PASSENGER_MET':
        return 'Passenger Boarded';
      case 'IN_TRANSIT':
        return 'In Transit';
      case 'COMPLETED':
        return 'Completed';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status.replaceAll('_', ' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(airportTransfersHistoryProvider);

    return historyAsync.when(
      skipLoadingOnReload: true,
      data: (bookings) {
        if (bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_taxi_rounded,
                    color: AppColors.primaryGold,
                    size: 42,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No Airport Transfers Yet',
                  style: AppTextStyles.titleMedium
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your booked airport rides will appear here',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        final filteredBookings = bookings.where((b) {
          final status = (b['status'] ?? '').toString();
          final returnStatus = (b['returnStatus'] ?? '').toString();
          final isRound = (b['transferType'] ?? '').toString().toUpperCase() == 'ROUND_TRIP';

          if (_selectedFilter == 'All') return true;
          if (_selectedFilter == 'Pending') {
            return status == 'PENDING_APPROVAL' ||
                status == 'PENDING_PAYMENT' ||
                (isRound &&
                    (returnStatus == 'PENDING_APPROVAL' ||
                        returnStatus == 'PENDING_PAYMENT'));
          }
          if (_selectedFilter == 'Confirmed') {
            return status == 'CONFIRMED' ||
                status == 'DRIVER_ASSIGNED' ||
                (isRound &&
                    (returnStatus == 'CONFIRMED' ||
                        returnStatus == 'DRIVER_ASSIGNED'));
          }
          if (_selectedFilter == 'In Progress') {
            const inProgress = [
              'EN_ROUTE_TO_PICKUP',
              'ARRIVED_AT_AIRPORT',
              'PASSENGER_MET',
              'IN_TRANSIT'
            ];
            return inProgress.contains(status) ||
                (isRound && inProgress.contains(returnStatus));
          }
          if (_selectedFilter == 'Completed') {
            return isRound
                ? (status == 'COMPLETED' && returnStatus == 'COMPLETED')
                : (status == 'COMPLETED');
          }
          if (_selectedFilter == 'Cancelled') {
            return status == 'CANCELLED' ||
                status == 'REFUNDED' ||
                (isRound &&
                    (returnStatus == 'CANCELLED' ||
                        returnStatus == 'REFUNDED'));
          }
          return true;
        }).toList();

        return RefreshIndicator(
          color: AppColors.primaryGold,
          onRefresh: () => ref.refresh(airportTransfersHistoryProvider.future),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Filter Tabs
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedFilter = filter;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryGold
                                  : Theme.of(context).cardTheme.color,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryGold
                                    : (Theme.of(context).dividerTheme.color ??
                                        AppColors.borderDark),
                              ),
                            ),
                            child: Text(
                              filter,
                              style: AppTextStyles.labelLarge.copyWith(
                                color: isSelected
                                    ? Theme.of(context).scaffoldBackgroundColor
                                    : (Theme.of(context).brightness == Brightness.dark
                                        ? AppColors.textSecondary
                                        : AppColors.textSecondaryLight),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Bookings List
              Expanded(
                child: filteredBookings.isEmpty
                    ? Center(
                        child: Text(
                          'No transfers matching "$_selectedFilter"',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                        itemCount: filteredBookings.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final booking = filteredBookings[index];
                          return _buildTransferCard(context, booking);
                        },
                      ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryGold),
      ),
      error: (err, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 12),
            Text(
              'Failed to load transfer history',
              style: AppTextStyles.titleSmall,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () =>
                  ref.refresh(airportTransfersHistoryProvider.future),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferCard(
      BuildContext context, Map<String, dynamic> booking) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bookingId = (booking['id'] ?? '').toString();
    final status = (booking['status'] ?? 'CONFIRMED').toString();
    final vehicle = booking['vehicle'] as Map<String, dynamic>?;
    final vehicleName = vehicle != null && vehicle['make'] != null
        ? '${vehicle['make']} ${vehicle['model'] ?? ''}'.trim()
        : 'Airport Transfer Vehicle';
    final registration = vehicle?['registrationNo']?.toString() ??
        vehicle?['registration_no']?.toString() ??
        vehicle?['registration']?.toString() ??
        vehicle?['plateNumber']?.toString() ??
        vehicle?['plate_number']?.toString() ??
        booking['registrationNo']?.toString() ??
        booking['registration_no']?.toString() ??
        '';

    String vehicleImageUrl = '';
    if (vehicle != null) {
      if (vehicle['images'] is List && (vehicle['images'] as List).isNotEmpty) {
        final first = (vehicle['images'] as List).first?.toString() ?? '';
        if (first.trim().isNotEmpty) {
          vehicleImageUrl = ApiConstants.fullUrl(first.trim());
        }
      }
      if (vehicleImageUrl.isEmpty) {
        final raw = (vehicle['imageUrl'] ?? vehicle['image'] ?? '').toString().trim();
        if (raw.isNotEmpty) {
          vehicleImageUrl = ApiConstants.fullUrl(raw);
        }
      }
    }

    final grandTotal =
        double.tryParse((booking['grandTotal'] ?? 0).toString()) ?? 0.0;
    final currency = (booking['currency'] ?? 'EUR').toString();
    final pickupDateTimeStr = booking['pickupDateTime'];
    final pickupLocation = (booking['pickupLocation'] ?? '').toString();
    final dropoffLocation = (booking['dropoffLocation'] ?? '').toString();

    final isRound = (booking['transferType'] ?? '') == 'ROUND_TRIP';
    final returnStatus = (booking['returnStatus'] ?? status).toString();
    final returnStatusColor = _getStatusColor(returnStatus);
    final returnStatusLabel = _getStatusLabel(returnStatus);
    final statusColor = _getStatusColor(status);
    final statusLabel = _getStatusLabel(status);
    final isFullyCompleted = isRound
        ? (status == 'COMPLETED' && returnStatus == 'COMPLETED')
        : (status == 'COMPLETED');
    final isFullyCancelled = isRound
        ? ((status == 'CANCELLED' || status == 'REFUNDED') &&
            (returnStatus == 'CANCELLED' || returnStatus == 'REFUNDED'))
        : (status == 'CANCELLED' || status == 'REFUNDED');

    return InkWell(
      onTap: () async {
        await context.pushNamed(
          RouteNames.airportTransferHistoryDetails,
          extra: bookingId,
        );
        if (context.mounted) {
          ref.invalidate(airportTransfersHistoryProvider);
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Vehicle Details (Top Left) & Confirmation Status (Top Right)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 52,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF262626)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : const Color(0xFFCBD5E1),
                        width: 0.8,
                      ),
                    ),
                    child: vehicleImageUrl.isNotEmpty
                        ? Image.network(
                            vehicleImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              color:
                                  AppColors.primaryGold.withValues(alpha: 0.12),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.directions_car_filled_rounded,
                                size: 20,
                                color: AppColors.primaryGold,
                              ),
                            ),
                          )
                        : Container(
                            color:
                                AppColors.primaryGold.withValues(alpha: 0.12),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.directions_car_filled_rounded,
                              size: 20,
                              color: AppColors.primaryGold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicleName,
                        style: AppTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (registration.isNotEmpty &&
                          registration != 'N/A') ...[
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF262626)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : const Color(0xFFCBD5E1),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            registration,
                            style: AppTextStyles.labelSmall.copyWith(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                              letterSpacing: 0.5,
                              color: isDark
                                  ? AppColors.textPrimary
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                        ),
                      ],
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
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          '🛫 $statusLabel',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: returnStatusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: returnStatusColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          '🛬 $returnStatusLabel',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: returnStatusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isFullyCompleted
                              ? AppColors.success
                              : isFullyCancelled
                                  ? AppColors.error
                                  : statusColor)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: (isFullyCompleted
                                ? AppColors.success
                                : isFullyCancelled
                                    ? AppColors.error
                                    : statusColor)
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5.5,
                          height: 5.5,
                          decoration: BoxDecoration(
                            color: isFullyCompleted
                                ? AppColors.success
                                : isFullyCancelled
                                    ? AppColors.error
                                    : statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4.5),
                        Text(
                          isFullyCompleted
                              ? 'Completed'
                              : isFullyCancelled
                                  ? 'Cancelled'
                                  : statusLabel,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: isFullyCompleted
                                ? AppColors.success
                                : isFullyCancelled
                                    ? AppColors.error
                                    : statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 10),

            // 2. Booked Date
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 13,
                  color: isDark
                      ? AppColors.textSecondary
                      : AppColors.textSecondaryLight,
                ),
                const SizedBox(width: 6),
                Text(
                  'Booked Date: ',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondary
                        : AppColors.textSecondaryLight,
                    fontSize: 12,
                  ),
                ),
                Expanded(
                  child: Text(
                    _formatDateTime(pickupDateTimeStr),
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimary
                          : AppColors.textPrimaryLight,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            Divider(
              height: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            const SizedBox(height: 10),

            // 3. From / To Locations
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    const Icon(
                      Icons.trip_origin_rounded,
                      size: 12,
                      color: Color(0xFF10B981),
                    ),
                    Container(
                      width: 1.5,
                      height: 16,
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                    const Icon(
                      Icons.place_rounded,
                      size: 13,
                      color: Colors.redAccent,
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pickupLocation,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.textPrimary
                              : AppColors.textPrimaryLight,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        dropoffLocation,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.textPrimary
                              : AppColors.textPrimaryLight,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            Divider(
              height: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            const SizedBox(height: 10),

            // 4. Bottom Row: Amount Paid & Grand Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.payments_outlined,
                      size: 15,
                      color: isDark
                          ? AppColors.textSecondary
                          : AppColors.textSecondaryLight,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      status == 'PENDING_PAYMENT'
                          ? 'Total Amount'
                          : 'Total Paid',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isDark
                            ? AppColors.textSecondary
                            : AppColors.textSecondaryLight,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Text(
                  '$currency ${grandTotal.toStringAsFixed(2)}',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.primaryGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
