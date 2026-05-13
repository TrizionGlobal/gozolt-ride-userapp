import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/models/notification_item.dart';

class NotificationCard extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback? onTap;

  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notification.read
                ? (Theme.of(context).dividerTheme.color ?? AppColors.borderDark)
                : AppColors.primaryGold.withOpacity(0.3),
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Unread indicator
              if (!notification.read)
                Container(
                  width: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryGold,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    notification.read ? 14 : 10,
                    12,
                    14,
                    12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type icon
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _typeColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(_typeIcon, color: _typeColor, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    notification.title,
                                    style: AppTextStyles.titleSmall.copyWith(
                                      fontWeight: notification.read
                                          ? FontWeight.w500
                                          : FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatTime(notification.createdAt),
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: Theme.of(context).brightness == Brightness.dark ? AppColors.textMuted : AppColors.textMutedLight,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notification.body,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: notification.read
                                    ? (Theme.of(context).brightness == Brightness.dark ? AppColors.textMuted : AppColors.textMutedLight)
                                    : (Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : AppColors.textSecondaryLight),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData get _typeIcon {
    switch (notification.type) {
      case 'RIDE_UPDATE':
        return Icons.directions_car;
      case 'PROMOTION':
        return Icons.local_offer;
      case 'PAYMENT':
        return Icons.payment;
      case 'SYSTEM':
        return Icons.info_outline;
      default:
        return Icons.notifications;
    }
  }

  Color get _typeColor {
    switch (notification.type) {
      case 'RIDE_UPDATE':
        return AppColors.info;
      case 'PROMOTION':
        return AppColors.primaryGold;
      case 'PAYMENT':
        return AppColors.success;
      case 'SYSTEM':
        return AppColors.primaryGold; // use gold for system in both themes? or secondary?
      default:
        return AppColors.textMuted;
    }
  }

  String _formatTime(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';

      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[dt.month - 1]} ${dt.day}';
    } catch (_) {
      return '';
    }
  }
}
