import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/models/driver_info.dart';

class DriverInfoCard extends StatelessWidget {
  final DriverInfo driverInfo;
  final VoidCallback onCall;
  final VoidCallback onMessage;

  const DriverInfoCard({
    super.key,
    required this.driverInfo,
    required this.onCall,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
      ),
      child: Row(
        children: [
          // Driver avatar
          GestureDetector(
            onTap: () => _showDriverProfile(context),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGold.withOpacity(0.15),
                border: Border.all(
                    color: AppColors.primaryGold.withOpacity(0.3)),
              ),
              child: Center(
                child: Text(
                  driverInfo.name.isNotEmpty
                      ? driverInfo.name[0].toUpperCase()
                      : 'D',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.primaryGold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Driver info
          Expanded(
            child: GestureDetector(
              onTap: () => _showDriverProfile(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    driverInfo.name,
                    style: AppTextStyles.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.star,
                          color: AppColors.primaryGold, size: 14),
                      const SizedBox(width: 3),
                      Text(
                        driverInfo.rating.toStringAsFixed(1),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${driverInfo.vehicleColor} ${driverInfo.vehicleDescription}',
                        style: AppTextStyles.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    driverInfo.formattedPlate,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.primaryGold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildActionButton(
                context,
                icon: Icons.chat_bubble_outline,
                onTap: onMessage,
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                context,
                icon: Icons.phone,
                onTap: onCall,
                isGold: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
    bool isGold = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isGold
              ? AppColors.primaryGold.withOpacity(0.15)
              : Theme.of(context).brightness == Brightness.dark
                  ? AppColors.inputDark
                  : Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isGold
                ? AppColors.primaryGold.withOpacity(0.3)
                : (Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isGold ? AppColors.primaryGold : AppColors.textPrimary,
        ),
      ),
    );
  }

  void _showDriverProfile(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Avatar
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGold.withOpacity(0.15),
                border: Border.all(
                    color: AppColors.primaryGold.withOpacity(0.3),
                    width: 2),
              ),
              child: Center(
                child: Text(
                  driverInfo.name.isNotEmpty
                      ? driverInfo.name[0].toUpperCase()
                      : 'D',
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: AppColors.primaryGold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(driverInfo.name, style: AppTextStyles.headlineSmall),
            const SizedBox(height: 8),

            // Rating + rides
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: AppColors.primaryGold, size: 18),
                const SizedBox(width: 4),
                Text(
                  driverInfo.rating.toStringAsFixed(1),
                  style: AppTextStyles.titleMedium,
                ),
                const SizedBox(width: 16),
                Icon(Icons.directions_car,
                    color: AppColors.textSecondary, size: 18),
                const SizedBox(width: 4),
                Text(
                  '${driverInfo.totalRides} rides',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Vehicle info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
              ),
              child: Column(
                children: [
                  _profileRow('Vehicle',
                      '${driverInfo.vehicleColor} ${driverInfo.vehicleDescription}'),
                  Divider(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark, height: 16),
                  _profileRow('Plate Number', driverInfo.formattedPlate),
                  Divider(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark, height: 16),
                  _profileRow('Type', driverInfo.vehicleType),
                  if (driverInfo.memberSince != null) ...[
                    Divider(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark, height: 16),
                    _profileRow('Member Since', driverInfo.memberSince!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _profileRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary)),
        Text(value,
            style: AppTextStyles.bodyMedium
                .copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
