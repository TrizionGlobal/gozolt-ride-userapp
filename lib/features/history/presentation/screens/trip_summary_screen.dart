import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../data/models/ride_history_item.dart';
import '../providers/history_providers.dart';

class TripSummaryScreen extends ConsumerWidget {
  final String rideId;
  const TripSummaryScreen({super.key, required this.rideId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rideAsync = ref.watch(selectedRideDetailProvider(rideId));

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: rideAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: AppColors.primaryGold),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: AppColors.textMuted, size: 48),
              const SizedBox(height: 12),
              Text('Failed to load ride details',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary)),
              TextButton(
                onPressed: () => ref.invalidate(selectedRideDetailProvider(rideId)),
                child: Text('Retry',
                    style: TextStyle(color: AppColors.primaryGold)),
              ),
            ],
          ),
        ),
        data: (ride) => _buildContent(context, ride),
      ),
    );
  }

  Widget _buildContent(BuildContext context, RideHistoryItem ride) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Gold Header ──────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFD4A843), Color(0xFFF5C518)],
              ),
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.backgroundDark
                                  .withOpacity(0.15),
                            ),
                            child: const Icon(Icons.arrow_back,
                                color: AppColors.backgroundDark, size: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Trip Summary',
                          style: AppTextStyles.headlineSmall.copyWith(
                            color: AppColors.backgroundDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Fare display
                    Center(
                      child: Column(
                        children: [
                          Text(
                            '\u20AC${ride.displayFare.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: AppColors.backgroundDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.backgroundDark.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              ride.displayStatus,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.backgroundDark,
                                fontWeight: FontWeight.w700,
                              ),
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
        ),

        // ── Body ─────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // GoCoins earned
              if (ride.goCoinsEarned != null && ride.goCoinsEarned! > 0) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.primaryGold.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.stars,
                          color: AppColors.primaryGold, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '+${ride.goCoinsEarned} GoCoins earned',
                        style: AppTextStyles.titleSmall.copyWith(
                          color: AppColors.primaryGold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Route card
              _sectionTitle('Route'),
              const SizedBox(height: 10),
              _routeCard(ride),
              const SizedBox(height: 24),

              // Ride details
              _sectionTitle('Ride Details'),
              const SizedBox(height: 10),
              _detailsCard(ride),
              const SizedBox(height: 24),

              // Driver info
              if (ride.driverName != null) ...[
                _sectionTitle('Driver'),
                const SizedBox(height: 10),
                _driverCard(ride),
                const SizedBox(height: 24),
              ],

              // Payment breakdown
              _sectionTitle('Payment'),
              const SizedBox(height: 10),
              _paymentCard(ride),
              const SizedBox(height: 24),

              // Rating
              if (ride.isCompleted && ride.rating != null) ...[
                _sectionTitle('Your Rating'),
                const SizedBox(height: 10),
                _ratingCard(ride),
                const SizedBox(height: 24),
              ],

              // Cancellation reason
              if (ride.isCancelled && ride.cancelReason != null) ...[
                _sectionTitle('Cancellation'),
                const SizedBox(height: 10),
                _cancelCard(ride),
                const SizedBox(height: 24),
              ],

              // Actions
              if (ride.isCompleted) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context.pushNamed(
                            RouteNames.receipt,
                            extra: ride.id,
                          );
                        },
                        icon: const Icon(Icons.receipt_long, size: 18),
                        label: Text('Receipt'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: const BorderSide(color: AppColors.borderDark),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context.pushNamed(
                            RouteNames.createTicket,
                            extra: ride.id,
                          );
                        },
                        icon: const Icon(Icons.flag_outlined, size: 18),
                        label: Text('Report'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: const BorderSide(color: AppColors.borderDark),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.goNamed(RouteNames.searchDestination);
                    },
                    icon: const Icon(Icons.replay, size: 18),
                    label: Text('Book Same Route'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: AppColors.backgroundDark,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ]),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text, style: AppTextStyles.titleLarge);
  }

  Widget _routeCard(RideHistoryItem ride) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.success.withOpacity(0.3),
                        width: 2),
                  ),
                ),
                Container(
                    width: 2, height: 28, color: AppColors.borderDark),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.error.withOpacity(0.3),
                        width: 2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pickup',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.textMuted, fontSize: 10)),
                Text(ride.pickupAddress, style: AppTextStyles.bodyMedium),
                const SizedBox(height: 16),
                Text('Drop-off',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.textMuted, fontSize: 10)),
                Text(ride.dropoffAddress, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailsCard(RideHistoryItem ride) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        children: [
          _detailRow('Ride ID', ride.id),
          _detailRow('Vehicle', ride.displayVehicle),
          _detailRow('Date', _formatDate(ride.createdAt)),
          if (ride.distanceKm != null)
            _detailRow('Distance', '${ride.distanceKm!.toStringAsFixed(1)} km'),
          if (ride.durationMinutes != null)
            _detailRow('Duration', '${ride.durationMinutes} min'),
          if (ride.isScheduled && ride.scheduledAt != null)
            _detailRow('Scheduled For', _formatDate(ride.scheduledAt!)),
        ],
      ),
    );
  }

  Widget _driverCard(RideHistoryItem ride) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primaryGold.withOpacity(0.15),
            child: Text(
              ride.driverName?.substring(0, 1) ?? 'D',
              style: AppTextStyles.titleMedium
                  .copyWith(color: AppColors.primaryGold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ride.driverName ?? '', style: AppTextStyles.titleSmall),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (ride.driverRating != null) ...[
                      const Icon(Icons.star,
                          color: AppColors.primaryGold, size: 14),
                      const SizedBox(width: 3),
                      Text(
                        ride.driverRating!.toStringAsFixed(1),
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (ride.driverVehicle != null)
                      Text(ride.driverVehicle!,
                          style: AppTextStyles.bodySmall),
                  ],
                ),
              ],
            ),
          ),
          if (ride.driverPlate != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: AppColors.primaryGold.withOpacity(0.3)),
              ),
              child: Text(
                ride.driverPlate!,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primaryGold,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _paymentCard(RideHistoryItem ride) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        children: [
          if (ride.estimatedFare != null)
            _detailRow('Estimated Fare',
                '\u20AC${ride.estimatedFare!.toStringAsFixed(2)}'),
          if (ride.baseFare != null)
            _detailRow('Base Fare', '\u20AC${ride.baseFare!.toStringAsFixed(2)}'),
          if (ride.distanceFare != null)
            _detailRow('Distance', '\u20AC${ride.distanceFare!.toStringAsFixed(2)}'),
          if (ride.waitTimeFee != null && ride.waitTimeFee! > 0)
            _detailRow('Wait Time Fee', '\u20AC${ride.waitTimeFee!.toStringAsFixed(2)}'),
          if (ride.bookingFee != null)
            _detailRow('Booking Fee', '\u20AC${ride.bookingFee!.toStringAsFixed(2)}'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1),
          ),
          if (ride.actualFare != null)
            _detailRow('Final Fare',
                '\u20AC${ride.actualFare!.toStringAsFixed(2)}',
                highlight: true),
          if (ride.paymentMethod != null)
            _detailRow('Payment Method', _formatPayment(ride.paymentMethod!)),
        ],
      ),
    );
  }

  Widget _ratingCard(RideHistoryItem ride) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (i) {
          return Icon(
            i < (ride.rating ?? 0) ? Icons.star : Icons.star_border,
            color: AppColors.primaryGold,
            size: 28,
          );
        }),
      ),
    );
  }

  Widget _cancelCard(RideHistoryItem ride) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cancel_outlined, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              ride.cancelReason ?? 'Ride was cancelled',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textMuted)),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                color: highlight ? AppColors.primaryGold : AppColors.textPrimary,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year} \u2022 $hour:$minute';
    } catch (_) {
      return isoDate;
    }
  }

  String _formatPayment(String method) {
    switch (method.toLowerCase()) {
      case 'visa':
        return 'Visa ****';
      case 'mastercard':
        return 'Mastercard ****';
      case 'cash':
        return 'Cash';
      default:
        return method;
    }
  }
}
