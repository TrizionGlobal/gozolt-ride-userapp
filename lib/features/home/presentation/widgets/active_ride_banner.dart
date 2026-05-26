import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../../ride/presentation/providers/active_ride_provider.dart';
import '../../../ride/presentation/providers/active_ride_state.dart';
import '../../../ride/data/models/ride.dart';

class ActiveRideBanner extends ConsumerWidget {
  const ActiveRideBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rideState = ref.watch(activeRideProvider);

    // Only show when there's an active ride that isn't completed/cancelled
    if (rideState.ride == null ||
        rideState.isCompleted ||
        rideState.isCancelled) {
      return const SizedBox.shrink();
    }

    final statusLabel = _statusLabel(rideState.status, rideState.ride);
    final statusIcon = _statusIcon(rideState.status);
    final statusColor = _statusColor(rideState.status);
    final eta = rideState.etaMinutes;
    final driverName = rideState.driverInfo?.name;
    final dropoff = rideState.ride?.dropoffAddress;

    // Build subtitle with contextual details
    final subtitleParts = <String>[statusLabel];
    if (eta != null && eta > 0) subtitleParts.add('$eta min');
    if (driverName != null && driverName.isNotEmpty && driverName != 'Driver') {
      subtitleParts.add(driverName);
    }
    final subtitle = subtitleParts.join(' \u2022 ');

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.pushNamed(RouteNames.rideActive);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark 
                ? [Theme.of(context).cardTheme.color ?? const Color(0xFF1C2333), Theme.of(context).cardTheme.color?.withOpacity(0.8) ?? const Color(0xFF161B22)]
                : [Colors.white, const Color(0xFFF6F8FA)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: statusColor.withOpacity(isDark ? 0.4 : 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: statusColor.withOpacity(isDark ? 0.15 : 0.08),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Animated status icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor.withOpacity(0.15),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _bannerTitle(rideState.status),
                        style: AppTextStyles.titleSmall.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Theme.of(context).scaffoldBackgroundColor,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Show destination for context
            if (dropoff != null && dropoff.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const SizedBox(width: 48), // align with text above
                  Icon(Icons.location_on, color: Theme.of(context).brightness == Brightness.dark ? AppColors.textMuted : AppColors.textMutedLight, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      dropoff,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  String _bannerTitle(ActiveRideStatus status) {
    switch (status) {
      case ActiveRideStatus.scheduled:
        return 'Ride Scheduled';
      case ActiveRideStatus.driverEnRoute:
        return 'Your Driver is Coming';
      case ActiveRideStatus.driverArrived:
        return 'Driver Has Arrived';
      case ActiveRideStatus.inProgress:
        return 'Ride in Progress';
      case ActiveRideStatus.completed:
        return 'Ride Completed';
      case ActiveRideStatus.cancelled:
        return 'Ride Cancelled';
    }
  }

  String _statusLabel(ActiveRideStatus status, Ride? ride) {
    switch (status) {
      case ActiveRideStatus.scheduled:
        if (ride?.scheduledAt != null) {
          try {
            final dt = DateTime.parse(ride!.scheduledAt!).toLocal();
            final now = DateTime.now();
            final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
            final pad = (int n) => n.toString().padLeft(2, '0');
            final timeStr = '${pad(dt.hour)}:${pad(dt.minute)}';
            if (isToday) {
              return 'Today at $timeStr';
            } else {
              final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
              return '${months[dt.month - 1]} ${dt.day} at $timeStr';
            }
          } catch (_) {
            return 'Scheduled ride';
          }
        }
        return 'Scheduled ride';
      case ActiveRideStatus.driverEnRoute:
        return 'En route to pickup';
      case ActiveRideStatus.driverArrived:
        return 'Waiting at pickup';
      case ActiveRideStatus.inProgress:
        return 'On the way to destination';
      case ActiveRideStatus.completed:
        return 'Completed';
      case ActiveRideStatus.cancelled:
        return 'Cancelled';
    }
  }

  IconData _statusIcon(ActiveRideStatus status) {
    switch (status) {
      case ActiveRideStatus.scheduled:
        return Icons.access_time_rounded;
      case ActiveRideStatus.driverEnRoute:
        return Icons.directions_car;
      case ActiveRideStatus.driverArrived:
        return Icons.person_pin_circle;
      case ActiveRideStatus.inProgress:
        return Icons.navigation_rounded;
      case ActiveRideStatus.completed:
        return Icons.check_circle;
      case ActiveRideStatus.cancelled:
        return Icons.cancel;
    }
  }

  Color _statusColor(ActiveRideStatus status) {
    switch (status) {
      case ActiveRideStatus.scheduled:
        return AppColors.primaryGold;
      case ActiveRideStatus.driverEnRoute:
        return AppColors.primaryGold;
      case ActiveRideStatus.driverArrived:
        return const Color(0xFF4CAF50); // green
      case ActiveRideStatus.inProgress:
        return const Color(0xFF2196F3); // blue
      case ActiveRideStatus.completed:
        return const Color(0xFF4CAF50);
      case ActiveRideStatus.cancelled:
        return AppColors.error;
    }
  }
}
