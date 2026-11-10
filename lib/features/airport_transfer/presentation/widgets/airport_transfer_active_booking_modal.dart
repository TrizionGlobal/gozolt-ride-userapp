import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/gozolt_button.dart';

void showActiveAirportTransferModal(
  BuildContext context,
  Map<String, dynamic> activeBooking,
) {
  final vehicle = activeBooking['vehicle'] as Map<String, dynamic>? ?? {};
  final vehicleName = vehicle['name']?.toString() ??
      vehicle['model']?.toString() ??
      'Airport Transfer Vehicle';
  final bookingRef = activeBooking['bookingReference']?.toString() ??
      activeBooking['id']?.toString() ??
      'Active Booking';
  final pickupLocation =
      activeBooking['pickupLocation']?.toString() ?? 'Airport';
  final dropoffLocation =
      activeBooking['dropoffLocation']?.toString() ?? 'Destination';

  final isRoundTrip =
      activeBooking['transferType']?.toString().toUpperCase() == 'ROUND_TRIP';
  final status = activeBooking['status']?.toString().toUpperCase() ?? 'ACTIVE';
  final returnStatus =
      activeBooking['returnStatus']?.toString().toUpperCase() ?? '';

  final isOutboundCompleted = status == 'COMPLETED';
  final isReturnPending =
      isRoundTrip && isOutboundCompleted && returnStatus != 'COMPLETED';

  DateTime? pickupDate;
  final pickupDateStr = activeBooking['pickupDateTime']?.toString();
  if (pickupDateStr != null && pickupDateStr.isNotEmpty) {
    try {
      pickupDate = DateTime.parse(pickupDateStr).toLocal();
    } catch (_) {}
  }

  DateTime? returnDate;
  final returnDateStr = activeBooking['returnDateTime']?.toString();
  if (returnDateStr != null && returnDateStr.isNotEmpty) {
    try {
      returnDate = DateTime.parse(returnDateStr).toLocal();
    } catch (_) {}
  }

  final isDark = Theme.of(context).brightness == Brightness.dark;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (ctx) => PopScope(
      canPop: false,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ??
              (isDark ? AppColors.cardDark : Colors.white),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.textSecondary
                        : AppColors.textSecondaryLight.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.amber,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                isReturnPending
                    ? 'Return Trip Pending'
                    : (isRoundTrip
                        ? 'Active Round Trip Detected'
                        : 'Active Booking Detected'),
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              Text(
                isReturnPending
                    ? 'Your outbound trip is completed, but your return trip is still active. Both one-way and return trips must be completed or cancelled before booking another transfer.'
                    : (isRoundTrip
                        ? 'Both one-way and return trips must be completed or cancelled before booking another transfer.'
                        : 'Please complete or cancel your current airport transfer before booking another one.'),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Booking Details Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.backgroundDark
                      : AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).dividerTheme.color ??
                        AppColors.borderDark,
                  ),
                ),
                child: Column(
                  children: [
                    _buildRow(context, 'Booking ID', bookingRef, isBold: true),
                    const Divider(height: 20),
                    if (isRoundTrip) ...[
                      _buildRow(
                        context,
                        'Transfer Type',
                        isReturnPending
                            ? 'Round Trip (Return Pending)'
                            : 'Round Trip',
                      ),
                      const SizedBox(height: 10),
                    ],
                    _buildRow(context, 'Vehicle', vehicleName),
                    const SizedBox(height: 10),
                    _buildRow(context, 'From', pickupLocation, maxLines: 1),
                    const SizedBox(height: 10),
                    _buildRow(context, 'To', dropoffLocation, maxLines: 1),
                    if (isReturnPending && returnDate != null) ...[
                      const SizedBox(height: 10),
                      _buildRow(
                        context,
                        'Return Pickup Time',
                        DateFormat('dd MMM yyyy, hh:mm a').format(returnDate),
                      ),
                    ] else if (pickupDate != null) ...[
                      const SizedBox(height: 10),
                      _buildRow(
                        context,
                        'Pickup Time',
                        DateFormat('dd MMM yyyy, hh:mm a').format(pickupDate),
                      ),
                    ],
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Status',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isReturnPending
                                ? 'Return: ${returnStatus.replaceAll('_', ' ')}'
                                : (isRoundTrip
                                    ? 'Outbound: ${status.replaceAll('_', ' ')}'
                                    : status.replaceAll('_', ' ')),
                            style: AppTextStyles.labelLarge.copyWith(
                              color: Colors.amber[800],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // View Active Booking Button
              GozoltButton(
                label: 'View Active Booking',
                width: double.infinity,
                onPressed: () {
                  Navigator.of(ctx).pop();
                  final bookingId = activeBooking['id']?.toString() ?? '';
                  if (bookingId.isNotEmpty) {
                    context.pushNamed(
                      RouteNames.airportTransferHistoryDetails,
                      extra: bookingId,
                    );
                  }
                },
              ),
              const SizedBox(height: 10),

              // Go to Home
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.goNamed(RouteNames.home);
                  },
                  child: Text(
                    'Go to Home',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
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

Widget _buildRow(
  BuildContext context,
  String label,
  String value, {
  bool isBold = false,
  int maxLines = 2,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          value,
          textAlign: TextAlign.end,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    ],
  );
}
