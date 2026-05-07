import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/models/fare_estimate.dart';

class FareBreakdownCard extends StatelessWidget {
  final FareEstimate estimate;
  final double? promoDiscount;
  final double? coinsDiscount;
  final bool useCoins;

  const FareBreakdownCard({
    super.key,
    required this.estimate,
    this.promoDiscount,
    this.coinsDiscount,
    this.useCoins = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDark, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Estimated Arrival
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.access_time,
                    color: AppColors.primaryGold, size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estimated Arrival',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.success),
                  ),
                  Text(
                    _estimatedArrivalText(),
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.borderDark, height: 1),
          const SizedBox(height: 14),

          // Fare lines
          _FareLine(label: 'Base Fare', amount: estimate.baseFare),
          _FareLine(
            label: 'Distance (${estimate.distanceKm.toStringAsFixed(1)}km)',
            amount: estimate.distanceFare,
          ),
          if (estimate.hasSurge)
            _FareLine(
              label: 'Surge Adjustment (${estimate.surgeMultiplier}x)',
              amount: estimate.surgeAmount,
              color: AppColors.primaryGold,
            ),
          if (useCoins && coinsDiscount != null && coinsDiscount! > 0)
            _FareLine(
              label: 'Rewards coins',
              amount: -coinsDiscount!,
              color: AppColors.success,
            ),
          if (promoDiscount != null && promoDiscount! > 0)
            _FareLine(
              label: 'Promo discount',
              amount: -promoDiscount!,
              color: AppColors.success,
            ),
          _FareLine(label: 'Booking Fee', amount: estimate.bookingFee),

          const SizedBox(height: 6),
          const Divider(color: AppColors.borderDark, height: 1),
          const SizedBox(height: 10),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Estimated Total',
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '€ ${_totalFare.toStringAsFixed(2)}',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.primaryGold,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double get _totalFare {
    double total = estimate.estimatedFare;
    if (useCoins && coinsDiscount != null && coinsDiscount! > 0) {
      total -= coinsDiscount!;
    }
    if (promoDiscount != null && promoDiscount! > 0) {
      total -= promoDiscount!;
    }
    return total < 0 ? 0 : total;
  }

  String _estimatedArrivalText() {
    final now = DateTime.now();
    final arrival = now.add(Duration(minutes: estimate.etaMinutes));
    final h = arrival.hour;
    final m = arrival.minute;
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '${hour12.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $period (${estimate.etaMinutes} Mins Away)';
  }
}

class _FareLine extends StatelessWidget {
  final String label;
  final double amount;
  final Color? color;

  const _FareLine({
    required this.label,
    required this.amount,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isNegative = amount < 0;
    final displayColor = color ?? AppColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(color: displayColor),
          ),
          Text(
            '${isNegative ? '-' : ''}€ ${amount.abs().toStringAsFixed(2)}',
            style: AppTextStyles.bodySmall.copyWith(
              color: displayColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
