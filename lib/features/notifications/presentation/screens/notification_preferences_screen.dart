import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../providers/notification_providers.dart';

class NotificationPreferencesScreen extends ConsumerWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(notificationPreferencesProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ─────────────────────────────────
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
                  padding: const EdgeInsets.fromLTRB(16, 8, 20, 20),
                  child: Row(
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
                        'Notification Preferences',
                        style: AppTextStyles.headlineSmall.copyWith(
                          color: AppColors.backgroundDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Toggles ────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  'Choose which notifications you\'d like to receive.',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                _toggleTile(
                  ref: ref,
                  icon: Icons.directions_car,
                  iconColor: AppColors.info,
                  title: 'Ride Updates',
                  subtitle:
                      'Driver status, arrival, ride completion',
                  value: prefs.rideUpdates,
                  onChanged: (v) => ref
                      .read(notificationPreferencesProvider.notifier)
                      .update(prefs.copyWith(rideUpdates: v)),
                ),
                _toggleTile(
                  ref: ref,
                  icon: Icons.payment,
                  iconColor: AppColors.success,
                  title: 'Payments',
                  subtitle: 'Payment confirmations, receipts',
                  value: prefs.payments,
                  onChanged: (v) => ref
                      .read(notificationPreferencesProvider.notifier)
                      .update(prefs.copyWith(payments: v)),
                ),
                _toggleTile(
                  ref: ref,
                  icon: Icons.local_offer,
                  iconColor: AppColors.primaryGold,
                  title: 'Promotions',
                  subtitle: 'Deals, discounts, special offers',
                  value: prefs.promotions,
                  onChanged: (v) => ref
                      .read(notificationPreferencesProvider.notifier)
                      .update(prefs.copyWith(promotions: v)),
                ),

                _toggleTile(
                  ref: ref,
                  icon: Icons.settings,
                  iconColor: AppColors.textSecondary,
                  title: 'System Alerts',
                  subtitle: 'App updates, maintenance notices',
                  value: prefs.systemAlerts,
                  onChanged: (v) => ref
                      .read(notificationPreferencesProvider.notifier)
                      .update(prefs.copyWith(systemAlerts: v)),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleTile({
    required WidgetRef ref,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleSmall),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.7,
            child: Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeTrackColor: AppColors.primaryGold,
              inactiveTrackColor: Theme.of(context).dividerTheme.color,
            ),
          ),
        ],
      ),
    );
  }
}
