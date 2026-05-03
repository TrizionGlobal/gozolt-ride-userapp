import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../providers/active_ride_state.dart';

class RideStatusBar extends StatelessWidget {
  final ActiveRideStatus status;

  /// Optional list of stop addresses for multi-stop rides.
  /// When provided and the ride is in progress, shows stop progression.
  final List<String>? stops;

  /// Index of the current stop being navigated to (0-based).
  final int currentStopIndex;

  const RideStatusBar({
    super.key,
    required this.status,
    this.stops,
    this.currentStopIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Main 3-step status bar
        Row(
          children: [
            _buildStep(
              label: 'En Route',
              isActive: status == ActiveRideStatus.driverEnRoute,
              isCompleted:
                  status.index > ActiveRideStatus.driverEnRoute.index,
            ),
            _buildConnector(
              isCompleted:
                  status.index > ActiveRideStatus.driverEnRoute.index,
            ),
            _buildStep(
              label: 'Arrived',
              isActive: status == ActiveRideStatus.driverArrived,
              isCompleted:
                  status.index > ActiveRideStatus.driverArrived.index,
            ),
            _buildConnector(
              isCompleted:
                  status.index > ActiveRideStatus.driverArrived.index,
            ),
            _buildStep(
              label: 'In Progress',
              isActive: status == ActiveRideStatus.inProgress,
              isCompleted: status == ActiveRideStatus.completed,
            ),
          ],
        ),

        // Multi-stop indicator (shown during in-progress when stops exist)
        if (stops != null &&
            stops!.isNotEmpty &&
            status == ActiveRideStatus.inProgress) ...[
          const SizedBox(height: 12),
          _buildMultiStopIndicator(),
        ],
      ],
    );
  }

  Widget _buildMultiStopIndicator() {
    final allStops = stops!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: [
          const Icon(Icons.route, color: AppColors.primaryGold, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Multi-stop ride',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.textMuted, fontSize: 10),
                ),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(allStops.length, (i) {
                    final isCompleted = i < currentStopIndex;
                    final isCurrent = i == currentStopIndex;
                    return Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCompleted || isCurrent
                                  ? AppColors.primaryGold
                                  : Colors.transparent,
                              border: Border.all(
                                color: isCompleted || isCurrent
                                    ? AppColors.primaryGold
                                    : AppColors.textMuted,
                                width: 1.5,
                              ),
                            ),
                            child: isCompleted
                                ? const Icon(Icons.check,
                                    size: 9,
                                    color: AppColors.backgroundDark)
                                : isCurrent
                                    ? Container(
                                        margin: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.backgroundDark,
                                        ),
                                      )
                                    : null,
                          ),
                          if (i < allStops.length - 1)
                            Expanded(
                              child: Container(
                                height: 1.5,
                                color: isCompleted
                                    ? AppColors.primaryGold
                                    : AppColors.borderDark,
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 4),
                Text(
                  'Stop ${currentStopIndex + 1} of ${allStops.length}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primaryGold,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required String label,
    required bool isActive,
    required bool isCompleted,
  }) {
    final color = isActive || isCompleted
        ? AppColors.primaryGold
        : AppColors.textMuted;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive || isCompleted
                  ? AppColors.primaryGold
                  : Colors.transparent,
              border: Border.all(
                color: color,
                width: 2,
              ),
            ),
            child: isCompleted
                ? const Icon(Icons.check,
                    size: 14, color: AppColors.backgroundDark)
                : isActive
                    ? Container(
                        margin: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.backgroundDark,
                        ),
                      )
                    : null,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildConnector({required bool isCompleted}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        color: isCompleted ? AppColors.primaryGold : AppColors.borderDark,
      ),
    );
  }
}
