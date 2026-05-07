import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../data/models/notification_item.dart';
import '../providers/notification_providers.dart';
import '../widgets/notification_card.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  static const _filters = [
    _FilterTab(label: 'All', value: null),
    _FilterTab(label: 'Rides', value: 'RIDE_UPDATE'),
    _FilterTab(label: 'Promotions', value: 'PROMOTION'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(notificationFilterProvider);
    final notifState = ref.watch(notificationsProvider);
    final hasUnread =
        notifState.notifications.any((n) => !n.read);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: RefreshIndicator(
        color: AppColors.primaryGold,
        backgroundColor: AppColors.surfaceDark,
        onRefresh: () => ref.read(notificationsProvider.notifier).load(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
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
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    child: Row(
                      children: [
                        Semantics(
                          label: 'Go back',
                          button: true,
                          child: GestureDetector(
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
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Notifications',
                          style: AppTextStyles.headlineSmall.copyWith(
                            color: AppColors.backgroundDark,
                          ),
                        ),
                        const Spacer(),
                        if (hasUnread)
                          Semantics(
                            label: 'Mark all notifications as read',
                            button: true,
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                ref
                                    .read(notificationsProvider.notifier)
                                    .markAllAsRead();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundDark
                                      .withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Mark All Read',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.backgroundDark,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Filter Tabs ────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: _filters.map((filter) {
                    final isSelected = currentFilter == filter.value;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          ref
                              .read(notificationFilterProvider.notifier)
                              .state = filter.value;
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryGold
                                : AppColors.cardDark,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryGold
                                  : AppColors.borderDark,
                            ),
                          ),
                          child: Text(
                            filter.label,
                            style: AppTextStyles.labelLarge.copyWith(
                              color: isSelected
                                  ? AppColors.backgroundDark
                                  : AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // ── Content ────────────────────────────────
            if (notifState.isLoading && notifState.notifications.isEmpty)
              SliverToBoxAdapter(
                child: buildShimmerList(
                  itemBuilder: () => const ShimmerNotificationCard(),
                  count: 5,
                ),
              )
            else if (notifState.notifications.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.notifications_none,
                          color: AppColors.textMuted, size: 56),
                      const SizedBox(height: 16),
                      Text(
                        'No notifications',
                        style: AppTextStyles.titleMedium
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'You\'ll see ride updates and promotions here',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final notification = notifState.notifications[index];
                      return NotificationCard(
                        notification: notification,
                        onTap: () {
                          ref
                              .read(notificationsProvider.notifier)
                              .markAsRead(notification.id);
                          _handleNotificationTap(context, ref, notification);
                        },
                      );
                    },
                    childCount: notifState.notifications.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handleNotificationTap(
      BuildContext context, WidgetRef ref, NotificationItem notification) {
    final data = notification.data ?? {};
    final subtype = data['subtype'] as String? ?? '';
    final rideId = data['rideId'] as String? ?? '';

    if (subtype == 'ride_completed' || subtype == 'ride_cancelled') {
      // Navigate to trip summary / ride detail
      if (rideId.isNotEmpty) {
        context.pushNamed(RouteNames.tripSummary, extra: rideId);
      } else {
        // No rideId — go to My Rides tab
        context.goNamed(RouteNames.myRides);
      }
    } else if (subtype == 'scheduled_ride') {
      _showScheduledRideDetail(context, ref, notification);
    }
    // For other types (PROMOTION, SYSTEM, PAYMENT) — just mark as read (already done)
  }

  void _showScheduledRideDetail(
      BuildContext context, WidgetRef ref, NotificationItem notification) {
    final data = notification.data ?? {};
    final pickup = data['pickup'] as String? ?? '';
    final dropoff = data['dropoff'] as String? ?? '';
    final fare = data['fare'] as String? ?? '';
    final vehicleType = data['vehicleType'] as String? ?? '';
    final scheduledAtStr = data['scheduledAt'] as String?;
    String scheduledDisplay = '';
    if (scheduledAtStr != null) {
      try {
        final dt = DateTime.parse(scheduledAtStr);
        scheduledDisplay =
            '${dt.day}/${dt.month}/${dt.year} at ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {
        scheduledDisplay = scheduledAtStr;
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Scheduled Ride',
                style: AppTextStyles.headlineSmall
                    .copyWith(color: Colors.white)),
            const SizedBox(height: 16),
            _detailRow(Icons.location_on, 'Pickup', pickup),
            const SizedBox(height: 10),
            _detailRow(Icons.flag, 'Dropoff', dropoff),
            const SizedBox(height: 10),
            _detailRow(Icons.access_time, 'Scheduled', scheduledDisplay),
            const SizedBox(height: 10),
            _detailRow(Icons.euro, 'Fare', fare),
            if (vehicleType.isNotEmpty) ...[
              const SizedBox(height: 10),
              _detailRow(
                  Icons.directions_car, 'Vehicle', vehicleType),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.pushNamed(RouteNames.searchDestination);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: AppColors.backgroundDark,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Reschedule'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Dismiss',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryGold, size: 18),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: AppTextStyles.labelSmall
                    .copyWith(color: AppColors.textMuted, fontSize: 10)),
            Text(value,
                style: AppTextStyles.bodySmall
                    .copyWith(color: Colors.white)),
          ],
        ),
      ],
    );
  }
}

class _FilterTab {
  final String label;
  final String? value;
  const _FilterTab({required this.label, required this.value});
}
