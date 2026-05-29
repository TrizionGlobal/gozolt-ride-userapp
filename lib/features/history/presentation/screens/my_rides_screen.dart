import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../data/models/ride_history_item.dart';
import '../providers/history_providers.dart';
import '../widgets/reschedule_bottom_sheet.dart';
import '../widgets/ride_history_card.dart';

class MyRidesScreen extends ConsumerWidget {
  const MyRidesScreen({super.key});

  static const _filters = [
    _FilterTab(label: 'All', value: null),
    _FilterTab(label: 'Completed', value: 'COMPLETED'),
    _FilterTab(label: 'Cancelled', value: 'CANCELLED'),
    _FilterTab(label: 'Scheduled', value: 'SCHEDULED'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(rideHistoryFilterProvider);
    final historyState = ref.watch(rideHistoryProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        color: AppColors.primaryGold,
        backgroundColor: Theme.of(context).cardTheme.color,
        onRefresh: () => ref.read(rideHistoryProvider.notifier).load(),
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
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Text(
                      'My Rides',
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.backgroundDark,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Filter Tabs ────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((filter) {
                      final isSelected = currentFilter == filter.value;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            ref
                                .read(rideHistoryFilterProvider.notifier)
                                .state = filter.value;
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryGold
                                  : Theme.of(context).cardTheme.color,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryGold
                                    : (Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
                              ),
                            ),
                            child: Text(
                              filter.label,
                              style: AppTextStyles.labelLarge.copyWith(
                                color: isSelected
                                    ? Theme.of(context).scaffoldBackgroundColor
                                    : (Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : AppColors.textSecondaryLight),
                                fontSize: 12,
                              ),
                            ),
                          ),

                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

            // ── Content ────────────────────────────────
            if (historyState.isLoading && historyState.rides.isEmpty)
              SliverToBoxAdapter(
                child: buildShimmerList(
                  itemBuilder: () => const ShimmerRideCard(),
                  count: 4,
                ),
              )
            else if (historyState.error != null && historyState.rides.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.textMuted, size: 48),
                      const SizedBox(height: 12),
                      Text('Failed to load rides',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () =>
                            ref.read(rideHistoryProvider.notifier).load(),
                        child: Text('Retry',
                            style: TextStyle(color: AppColors.primaryGold)),
                      ),
                    ],
                  ),
                ),
              )
            else if (historyState.rides.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        currentFilter == 'SCHEDULED'
                            ? Icons.schedule
                            : Icons.directions_car_outlined,
                        color: AppColors.textMuted,
                        size: 56,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        currentFilter == null
                            ? 'No rides yet'
                            : 'No ${_filters.firstWhere((f) => f.value == currentFilter).label.toLowerCase()} rides',
                        style: AppTextStyles.titleMedium
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Your ride history will appear here',
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 32,
                        width: 150,
                        child: ElevatedButton(
                          onPressed: () =>
                              context.pushNamed(RouteNames.searchDestination),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGold,
                            foregroundColor: AppColors.backgroundDark,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            'Book a Ride',
                            style: AppTextStyles.labelLarge.copyWith(
                              fontSize: 12,
                              color: AppColors.backgroundDark,
                            ),
                          ),
                        ),
                      ),

                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= historyState.rides.length) {
                        if (historyState.hasMore) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            ref
                                .read(rideHistoryProvider.notifier)
                                .loadMore();
                          });
                          return Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.primaryGold,
                                  strokeWidth: 2),
                            ),
                          );
                        }
                        return null;
                      }
                      final ride = historyState.rides[index];
                      return RideHistoryCard(
                        ride: ride,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          context.pushNamed(
                            RouteNames.tripSummary,
                            extra: ride.id,
                          );
                        },
                        onReschedule: ride.status == 'SCHEDULED'
                            ? () => _showRescheduleSheet(
                                context, ref, ride)
                            : null,
                        onCancel: ride.status == 'SCHEDULED'
                            ? () => _showCancelConfirmation(
                                context, ref, ride.id)
                            : null,
                      );
                    },
                    childCount: historyState.rides.length +
                        (historyState.hasMore ? 1 : 0),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showRescheduleSheet(
      BuildContext context, WidgetRef ref, RideHistoryItem ride) {
    final scheduledAt = ride.scheduledAt != null
        ? DateTime.tryParse(ride.scheduledAt!) ?? DateTime.now()
        : DateTime.now();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => RescheduleBottomSheet(
        currentSchedule: scheduledAt,
        onConfirm: (newTime) {
          ref
              .read(rideHistoryProvider.notifier)
              .rescheduleRide(ride.id, newTime);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ride rescheduled successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        },
      ),
    );
  }

  void _showCancelConfirmation(
      BuildContext context, WidgetRef ref, String rideId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cancel Scheduled Ride',
            style: AppTextStyles.titleMedium
                .copyWith(color: AppColors.textPrimary)),
        content: Text(
          'Are you sure you want to cancel this scheduled ride?',
          style: AppTextStyles.bodyMedium
              .copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Keep',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(rideHistoryProvider.notifier)
                  .cancelScheduledRide(rideId);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Scheduled ride cancelled'),
                  backgroundColor: AppColors.error,
                ),
              );
            },
            child:
                Text('Cancel Ride', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _FilterTab {
  final String label;
  final String? value;
  const _FilterTab({required this.label, required this.value});
}
