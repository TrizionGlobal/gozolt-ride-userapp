import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class RideInProgressView extends StatelessWidget {
  final int etaMinutes;
  final double? remainingKm;
  final String dropoffAddress;
  final VoidCallback onSos;
  final VoidCallback onCancel;
  final VoidCallback? onChangeDestination;

  const RideInProgressView({
    super.key,
    required this.etaMinutes,
    this.remainingKm,
    this.dropoffAddress = 'Destination',
    required this.onSos,
    required this.onCancel,
    this.onChangeDestination,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Trip progress card ──────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primaryGold.withOpacity(0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withOpacity(0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ride in Progress',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.navigation_rounded,
                    color: AppColors.primaryGold.withOpacity(0.6),
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ETA & Distance metrics
              Row(
                children: [
                  // Time remaining
                  Expanded(
                    child: _MetricTile(
                      icon: Icons.schedule_rounded,
                      value: '$etaMinutes',
                      unit: 'min',
                      label: 'Time left',
                    ),
                  ),
                  // Divider
                  Container(
                    width: 1,
                    height: 48,
                    color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark.withOpacity(0.5),
                  ),
                  // Distance remaining
                  Expanded(
                    child: _MetricTile(
                      icon: Icons.route_rounded,
                      value: remainingKm != null
                          ? remainingKm!.toStringAsFixed(1)
                          : '--',
                      unit: 'km',
                      label: 'Distance',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Destination
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      color: AppColors.primaryGold,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        dropoffAddress,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Action buttons ──────────────────────────────
        Row(
          children: [
            // SOS button
            _ActionButton(
              icon: Icons.sos,
              label: 'SOS',
              color: AppColors.error,
              onTap: onSos,
            ),
            if (onChangeDestination != null) ...[
              const SizedBox(width: 8),
              _ActionButton(
                icon: Icons.edit_location_alt_outlined,
                label: 'Change',
                color: AppColors.primaryGold,
                onTap: onChangeDestination!,
              ),
            ],
            const SizedBox(width: 8),
            _ActionButton(
              icon: Icons.close_rounded,
              label: 'Cancel',
              color: AppColors.textMuted,
              onTap: onCancel,
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String unit;
  final String label;

  const _MetricTile({
    required this.icon,
    required this.value,
    required this.unit,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.primaryGold,
                fontWeight: FontWeight.w800,
                fontSize: 28,
                height: 1,
              ),
            ),
            const SizedBox(width: 3),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                unit,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primaryGold.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textMuted,
            fontSize: 10,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
            color: color.withOpacity(0.06),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
