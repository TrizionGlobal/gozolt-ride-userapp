import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/models/ride_history_item.dart';

class RideHistoryCard extends StatelessWidget {
  final RideHistoryItem ride;
  final VoidCallback? onTap;
  final VoidCallback? onReschedule;
  final VoidCallback? onCancel;

  const RideHistoryCard({super.key, required this.ride, this.onTap, this.onReschedule, this.onCancel});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Row: Date + Status Badge ─────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(ride.createdAt),
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textMuted),
                ),
                _StatusBadge(status: ride.status),
              ],
            ),
            const SizedBox(height: 12),

            // ── Route ────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Route dots
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Column(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.success.withOpacity(0.3),
                              width: 2),
                        ),
                      ),
                      Container(
                          width: 1.5,
                          height: 20,
                          color: AppColors.borderDark),
                      Container(
                        width: 10,
                        height: 10,
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
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride.pickupAddress,
                        style: AppTextStyles.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        ride.dropoffAddress,
                        style: AppTextStyles.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Bottom Row: Vehicle + Fare ───────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _vehicleIcon(ride.vehicleType),
                        color: AppColors.textMuted,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        ride.displayVehicle,
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                  Text(
                    '\u20AC${ride.displayFare.toStringAsFixed(2)}',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.primaryGold,
                    ),
                  ),
                ],
              ),
            ),
            // Scheduled ride actions
            if (ride.status == 'SCHEDULED' && (onReschedule != null || onCancel != null)) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (onReschedule != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onReschedule,
                        icon: const Icon(Icons.schedule, size: 16),
                        label: const Text('Reschedule'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryGold,
                          side: const BorderSide(color: AppColors.primaryGold),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  if (onReschedule != null && onCancel != null)
                    const SizedBox(width: 8),
                  if (onCancel != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onCancel,
                        icon: const Icon(Icons.cancel_outlined, size: 16),
                        label: const Text('Cancel'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
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

  IconData _vehicleIcon(String type) {
    switch (type) {
      case 'ECONOMY':
        return Icons.directions_car_filled;
      case 'PREMIUM':
        return Icons.star;
      case 'XL':
        return Icons.airport_shuttle;
      case 'ELECTRIC':
        return Icons.electric_car;
      default:
        return Icons.directions_car;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, String label) = _statusStyle(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }

  (Color, Color, String) _statusStyle(String status) {
    switch (status) {
      case 'COMPLETED':
        return (
          AppColors.success.withOpacity(0.15),
          AppColors.success,
          'Completed',
        );
      case 'CANCELLED':
        return (
          AppColors.error.withOpacity(0.15),
          AppColors.error,
          'Cancelled',
        );
      case 'SCHEDULED':
        return (
          AppColors.info.withOpacity(0.15),
          AppColors.info,
          'Scheduled',
        );
      case 'IN_PROGRESS':
        return (
          AppColors.primaryGold.withOpacity(0.15),
          AppColors.primaryGold,
          'In Progress',
        );
      default:
        return (
          AppColors.textMuted.withOpacity(0.15),
          AppColors.textMuted,
          status,
        );
    }
  }
}
