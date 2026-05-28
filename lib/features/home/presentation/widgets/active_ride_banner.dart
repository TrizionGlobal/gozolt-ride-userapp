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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerTheme.color ?? AppColors.borderLight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Vehicle Image Container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGold.withOpacity(0.15),
              ),
              child: Center(
                child: Image.asset(
                  _getVehicleAsset(rideState.ride?.vehicleType),
                  width: 32,
                  height: 32,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.directions_car,
                    color: AppColors.primaryGold,
                    size: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _bannerTitle(rideState.status),
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.primaryGold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (dropoff != null && dropoff.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            dropoff,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
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
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryGold,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                color: Theme.of(context).scaffoldBackgroundColor,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getVehicleAsset(String? vehicleType) {
    switch (vehicleType?.toUpperCase()) {
      case 'COMFORT':
        return 'assets/images/icon_vehicle_comfort.png';
      case 'XL':
        return 'assets/images/icon_vehicle_xl.png';
      case 'LUXURY':
        return 'assets/images/icon_vehicle_luxury.png';
      case 'ACCESSIBLE':
        return 'assets/images/icon_vehicle_accessible.png';
      case 'GO':
      default:
        return 'assets/images/icon_vehicle_standard.png';
    }
  }

  String _bannerTitle(ActiveRideStatus status) {
    switch (status) {
      case ActiveRideStatus.scheduled:
        return 'Ride Scheduled';
      case ActiveRideStatus.searching:
        return 'Finding Driver';
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
      case ActiveRideStatus.searching:
        return 'Contacting nearby drivers';
      case ActiveRideStatus.driverEnRoute:
        return 'On the way';
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
      case ActiveRideStatus.searching:
        return Icons.search_rounded;
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
      case ActiveRideStatus.searching:
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
