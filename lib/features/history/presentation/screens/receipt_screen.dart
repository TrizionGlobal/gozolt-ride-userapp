import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/models/ride_history_item.dart';
import '../providers/history_providers.dart';

class ReceiptScreen extends ConsumerWidget {
  final String rideId;
  const ReceiptScreen({super.key, required this.rideId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rideAsync = ref.watch(selectedRideDetailProvider(rideId));

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: rideAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryGold),
        ),
        error: (e, _) => SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.cardDark,
                        ),
                        child: const Icon(Icons.arrow_back,
                            color: AppColors.textPrimary, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('Receipt',
                        style: AppTextStyles.headlineSmall),
                  ],
                ),
              ),
              const Spacer(),
              const Icon(Icons.receipt_long,
                  color: AppColors.textMuted, size: 48),
              const SizedBox(height: 16),
              Text('Failed to load receipt',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(selectedRideDetailProvider(rideId)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: AppColors.backgroundDark,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Retry'),
              ),
              const Spacer(),
            ],
          ),
        ),
        data: (ride) => _buildContent(context, ride),
      ),
    );
  }

  Widget _buildContent(BuildContext context, RideHistoryItem ride) {
    final actualFare = ride.actualFare ?? ride.estimatedFare ?? 0.0;
    final baseFare = ride.baseFare ?? 0.0;
    final distanceFare = ride.distanceFare ?? 0.0;
    final timeFare = ride.timeFare ?? 0.0;
    final bookingFee = ride.bookingFee ?? 0.0;
    final surgeMultiplier = ride.surgeMultiplier ?? 1.0;
    final tip = ride.tipAmount ?? 0.0;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Header
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
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
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
                          'Receipt',
                          style: AppTextStyles.headlineSmall.copyWith(
                            color: AppColors.backgroundDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Icon(Icons.receipt_long,
                        color: AppColors.backgroundDark, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      '\u20AC${actualFare.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: AppColors.backgroundDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Body
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Ride info
              _sectionTitle('Ride Info'),
              const SizedBox(height: 10),
              _infoCard([
                _row('Ride ID', ride.id),
                _row('Date', _formatDate(ride.createdAt)),
                _row('Vehicle', ride.displayVehicle),
                if (ride.distanceKm != null)
                  _row('Distance',
                      '${ride.distanceKm!.toStringAsFixed(1)} km'),
                if (ride.durationMinutes != null)
                  _row('Duration', '${ride.durationMinutes} min'),
              ]),
              const SizedBox(height: 24),

              // Route
              _sectionTitle('Route'),
              const SizedBox(height: 10),
              _infoCard([
                _row('Pickup', ride.pickupAddress),
                _row('Drop-off', ride.dropoffAddress),
              ]),
              const SizedBox(height: 24),

              // Fare breakdown
              _sectionTitle('Fare Breakdown'),
              const SizedBox(height: 10),
              _infoCard([
                _row('Base Fare', '\u20AC${baseFare.toStringAsFixed(2)}'),
                _row('Distance',
                    '\u20AC${distanceFare.toStringAsFixed(2)}'),
                _row('Time', '\u20AC${timeFare.toStringAsFixed(2)}'),
                _row('Booking Fee',
                    '\u20AC${bookingFee.toStringAsFixed(2)}'),
                if (surgeMultiplier > 1.0)
                  _row('Surge', '${surgeMultiplier.toStringAsFixed(1)}x'),
                if (tip > 0) _row('Tip', '\u20AC${tip.toStringAsFixed(2)}'),
                const Divider(color: AppColors.borderDark, height: 16),
                _row('Total', '\u20AC${actualFare.toStringAsFixed(2)}',
                    highlight: true),
              ]),
              const SizedBox(height: 24),

              // Payment
              _sectionTitle('Payment'),
              const SizedBox(height: 10),
              _infoCard([
                _row('Method',
                    _formatPayment(ride.paymentMethod ?? 'cash')),
                _row('Status', ride.isCompleted ? 'Paid' : 'Pending'),
              ]),
              const SizedBox(height: 24),

              // Driver
              if (ride.driverName != null) ...[
                _sectionTitle('Driver'),
                const SizedBox(height: 10),
                _infoCard([
                  _row('Name', ride.driverName!),
                  if (ride.driverPlate != null)
                    _row('Plate', ride.driverPlate!),
                  if (ride.driverVehicle != null)
                    _row('Vehicle', ride.driverVehicle!),
                ]),
                const SizedBox(height: 24),
              ],

              // Share button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Receipt sharing coming soon'),
                        backgroundColor: AppColors.surfaceDark,
                      ),
                    );
                  },
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: const Text('Share Receipt'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryGold,
                    side: const BorderSide(color: AppColors.primaryGold),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

              // Download PDF
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('PDF download coming soon'),
                        backgroundColor: AppColors.surfaceDark,
                      ),
                    );
                  },
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Download PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    foregroundColor: AppColors.backgroundDark,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text, style: AppTextStyles.titleLarge);
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(children: children),
    );
  }

  Widget _row(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textMuted)),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                color: highlight
                    ? AppColors.primaryGold
                    : AppColors.textPrimary,
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
