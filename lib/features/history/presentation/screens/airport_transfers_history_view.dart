import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../../airport_transfer/data/datasources/airport_transfer_remote_datasource.dart';

final airportTransfersHistoryProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final datasource = ref.read(airportTransferRemoteDatasourceProvider);
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

  final List<String> _filters = [
    'All',
    'Pending',
    'Confirmed',
    'In Progress',
    'Completed',
    'Cancelled'
  ];

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

  String _getStatusLabel(String status) {
    switch (status) {
      case 'PENDING_APPROVAL':
        return 'Pending Approval';
      case 'CONFIRMED':
        return 'Confirmed';
      case 'DRIVER_ASSIGNED':
        return 'Chauffeur Assigned';
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
                    color: AppColors.primaryGold.withOpacity(0.12),
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
                  'Your chauffeured airport rides will appear here',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        final filteredBookings = bookings.where((b) {
          final status = (b['status'] ?? '').toString();
          if (_selectedFilter == 'All') return true;
          if (_selectedFilter == 'Pending') {
            return status == 'PENDING_APPROVAL' || status == 'PENDING_PAYMENT';
          }
          if (_selectedFilter == 'Confirmed') {
            return status == 'CONFIRMED' || status == 'DRIVER_ASSIGNED';
          }
          if (_selectedFilter == 'In Progress') {
            return status == 'EN_ROUTE_TO_PICKUP' ||
                status == 'ARRIVED_AT_AIRPORT' ||
                status == 'PASSENGER_MET' ||
                status == 'IN_TRANSIT';
          }
          if (_selectedFilter == 'Completed') {
            return status == 'COMPLETED';
          }
          if (_selectedFilter == 'Cancelled') {
            return status == 'CANCELLED' || status == 'REFUNDED';
          }
          return true;
        }).toList();

        return RefreshIndicator(
          color: AppColors.primaryGold,
          onRefresh: () => ref.refresh(airportTransfersHistoryProvider.future),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
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
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color ??
                                      AppColors.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
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
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
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
    final bookingRef =
        (booking['bookingReference'] ?? 'GZLT-TRF').toString();
    final status = (booking['status'] ?? 'CONFIRMED').toString();
    final isRound = (booking['transferType'] ?? '') == 'ROUND_TRIP';
    final vehicle = booking['vehicle'] as Map<String, dynamic>?;
    final vehicleName = vehicle != null && vehicle['make'] != null
        ? '${vehicle['make']} ${vehicle['model'] ?? ''}'
        : 'Airport Transfer Vehicle';
    final flightNumber = booking['flightNumber']?.toString();
    final grandTotal =
        double.tryParse((booking['grandTotal'] ?? 0).toString()) ?? 0.0;
    final currency = (booking['currency'] ?? 'EUR').toString();
    final pickupDateTimeStr = booking['pickupDateTime'];
    final pickupLocation = (booking['pickupLocation'] ?? '').toString();
    final dropoffLocation = (booking['dropoffLocation'] ?? '').toString();

    final statusColor = _getStatusColor(status);
    final statusLabel = _getStatusLabel(status);

    return InkWell(
      onTap: () {
        context.pushNamed(
          RouteNames.airportTransferHistoryDetails,
          extra: bookingId,
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : Colors.grey.shade300,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Reference, Round/One-way, Status
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    bookingRef,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primaryGold,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: isRound
                        ? Colors.indigo.withOpacity(0.12)
                        : Colors.teal.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isRound ? 'ROUND TRIP' : 'ONE WAY',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isRound ? Colors.indigo : Colors.teal,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withOpacity(0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        statusLabel,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Vehicle Name + Flight Badge
            Row(
              children: [
                const Icon(
                  Icons.directions_car_filled_rounded,
                  size: 18,
                  color: AppColors.primaryGold,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    vehicleName,
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (flightNumber != null && flightNumber.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.flight_takeoff_rounded,
                          size: 12,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          flightNumber,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.blue,
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

            // Schedule Date & Time
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: isDark
                      ? AppColors.textSecondary
                      : AppColors.textSecondaryLight,
                ),
                const SizedBox(width: 6),
                Text(
                  _formatDateTime(pickupDateTimeStr),
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimary
                        : AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Route Timeline
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    const Icon(
                      Icons.trip_origin_rounded,
                      size: 13,
                      color: Color(0xFF10B981),
                    ),
                    Container(
                      width: 1.5,
                      height: 20,
                      color: Colors.grey.withOpacity(0.4),
                    ),
                    const Icon(
                      Icons.place_rounded,
                      size: 14,
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
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        dropoffLocation,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Bottom Row: Chauffeur notice & Grand Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.person_pin_circle_rounded,
                      size: 14,
                      color: AppColors.primaryGold,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Chauffeured Transfer',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primaryGold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Text(
                  '$currency ${grandTotal.toStringAsFixed(2)}',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.primaryGold,
                    fontWeight: FontWeight.bold,
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
