import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/asset_paths.dart';
import '../../../../core/router/route_names.dart';
import '../../data/models/reward_transaction.dart';
import '../providers/rewards_providers.dart';
import '../widgets/redeem_bottom_sheet.dart';
import '../widgets/referral_bottom_sheet.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../widgets/tier_badge.dart';

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(rewardSummaryProvider);
    final historyAsync = ref.watch(rewardHistoryProvider);
    final rulesAsync = ref.watch(rewardRulesProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        color: AppColors.primaryGold,
        backgroundColor: Theme.of(context).cardTheme.color,
        onRefresh: () async {
          ref.invalidate(rewardSummaryProvider);
          ref.read(rewardHistoryProvider.notifier).load();
          ref.invalidate(referralInfoProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // ── Gold Header ─────────────────────────────────
            SliverToBoxAdapter(
              child: summaryAsync.when(
                loading: () => _buildHeaderShimmer(),
                error: (context, error) => _buildHeaderError(ref),
                data: (summary) => _buildGoldHeader(context, ref, summary),
              ),
            ),

            // ── Action Buttons ──────────────────────────────
            SliverToBoxAdapter(
              child: summaryAsync.when(
                loading: () => const SizedBox(height: 80),
                error: (context, error) => const SizedBox.shrink(),
                data: (summary) =>
                    _buildActionButtons(context, ref, summary),
              ),
            ),

            // ── Tier Benefits ───────────────────────────────
            SliverToBoxAdapter(
              child: summaryAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (context, error) => const SizedBox.shrink(),
                data: (summary) => rulesAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (context, error) => const SizedBox.shrink(),
                  data: (rules) {
                    final currentTier = rules.tierFor(summary.tier);
                    if (currentTier == null ||
                        currentTier.benefits.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return _buildTierBenefits(
                        context, summary, currentTier);
                  },
                ),
              ),
            ),

            // ── Transaction History Header ──────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Text(
                  'Transaction History',
                  style: AppTextStyles.titleLarge,
                ),
              ),
            ),

            // ── Transaction List ────────────────────────────
            historyAsync.when(
              loading: () => SliverToBoxAdapter(
                child: buildShimmerList(
                  itemBuilder: () => const ShimmerListTile(),
                  count: 5,
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: _buildEmptyHistory(context),
              ),
              data: (transactions) {
                if (transactions.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _buildEmptyHistory(context),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == transactions.length) {
                        // Load more trigger
                        final notifier =
                            ref.read(rewardHistoryProvider.notifier);
                        if (notifier.hasMore) {
                          notifier.loadMore();
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primaryGold,
                                ),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }
                      return _TransactionCard(
                          transaction: transactions[index]);
                    },
                    childCount: transactions.length + 1,
                  ),
                );
              },
            ),

            // ── Referral Section ────────────────────────────
            SliverToBoxAdapter(
              child: _buildReferralBanner(context, ref),
            ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  // ── Gold Header ─────────────────────────────────────────

  Widget _buildGoldHeader(
      BuildContext context, WidgetRef ref, dynamic summary) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFD4A843),
            Color(0xFFF5C518),
          ],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Rewards',
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: AppColors.backgroundDark,
                    ),
                  ),
                  Semantics(
                    label: 'Rewards information',
                    button: true,
                    child: GestureDetector(
                      onTap: () =>
                          context.pushNamed(RouteNames.rewardsInfo),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.backgroundDark.withOpacity(0.15),
                        ),
                        child: const Icon(Icons.info_outline,
                            color: AppColors.backgroundDark, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Balance
              Center(
                child: Column(
                  children: [
                    Text(
                      summary.currentPoints.toStringAsFixed(
                          summary.currentPoints.truncateToDouble() ==
                                  summary.currentPoints
                              ? 0
                              : 2),
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: AppColors.backgroundDark,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Total Coins ',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.backgroundDark
                                .withOpacity(0.7),
                          ),
                        ),
                        const Icon(Icons.stars,
                            color: AppColors.backgroundDark, size: 18),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Tier badge (not shown for BRONZE)
              if (!summary.isBronze)
                Center(
                  child: TierBadge(tier: summary.tier),
                ),

              if (!summary.isBronze) const SizedBox(height: 12),

              // Progress to next tier
              if (!summary.isMaxTier) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${summary.progress.pointsNeeded.toStringAsFixed(0)} pts to ${summary.progress.nextTier ?? ""}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.backgroundDark.withOpacity(0.7),
                      ),
                    ),
                    Text(
                      '${summary.progress.progressPercent.toStringAsFixed(0)}%',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.backgroundDark.withOpacity(0.7),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: summary.progress.progressPercent / 100,
                    minHeight: 6,
                    backgroundColor:
                        AppColors.backgroundDark.withOpacity(0.15),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.backgroundDark),
                  ),
                ),
              ] else ...[
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundDark.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Maximum tier reached!',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.backgroundDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderShimmer() {
    return Container(
      height: 240,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFD4A843), Color(0xFFF5C518)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.backgroundDark),
      ),
    );
  }

  Widget _buildHeaderError(WidgetRef ref) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFD4A843), Color(0xFFF5C518)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Rewards',
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: AppColors.backgroundDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                '0',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: AppColors.backgroundDark,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Total Coins ',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.backgroundDark.withOpacity(0.7),
                    ),
                  ),
                  const Icon(Icons.stars,
                      color: AppColors.backgroundDark, size: 18),
                ],
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => ref.invalidate(rewardSummaryProvider),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundDark.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.refresh,
                          color: AppColors.backgroundDark, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Tap to refresh',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.backgroundDark,
                          fontWeight: FontWeight.w600,
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

  // ── Action Buttons ──────────────────────────────────────

  Widget _buildActionButtons(
      BuildContext context, WidgetRef ref, dynamic summary) {
    final canRedeem = summary.currentPoints >= 200;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          _ActionButton(
            icon: Icons.redeem,
            label: 'Redeem',
            enabled: canRedeem,
            tooltip: canRedeem ? null : 'Need at least 200 coins',
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const RedeemBottomSheet(),
              );
            },
          ),
          const SizedBox(width: 12),
          _ActionButton(
            icon: Icons.add_circle_outline,
            label: 'Earn More',
            onTap: () => context.pushNamed(RouteNames.rewardsInfo),
          ),
          const SizedBox(width: 12),
          _ActionButton(
            icon: Icons.share,
            label: 'Refer',
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const ReferralBottomSheet(),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Tier Benefits ───────────────────────────────────────

  Widget _buildTierBenefits(
      BuildContext context, dynamic summary, dynamic currentTier) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                TierBadge(tier: summary.tier, small: true),
                const SizedBox(width: 8),
                Text(
                  'TIER BENEFITS',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...currentTier.benefits.map<Widget>((benefit) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle,
                          color: AppColors.primaryGold, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          benefit as String,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 4),
            Semantics(
              label: 'View all tiers and benefits',
              link: true,
              child: GestureDetector(
                onTap: () => context.pushNamed(RouteNames.rewardsInfo),
                child: Text(
                  'View all tiers & benefits >',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primaryGold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty History ───────────────────────────────────────

  Widget _buildEmptyHistory(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 48,
                color: AppColors.textMuted.withOpacity(0.3)),
            const SizedBox(height: 12),
            Text(
              'No Reward History',
              style: AppTextStyles.titleMedium
                  .copyWith(color: Theme.of(context).brightness == Brightness.dark ? AppColors.textMuted : AppColors.textMutedLight),
            ),
            const SizedBox(height: 8),
            Text(
              'Start earning by completing your first ride!',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 150,
              child: OutlinedButton(
                onPressed: () => context.pushNamed(RouteNames.searchDestination),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryGold,
                  side: const BorderSide(color: AppColors.primaryGold),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Book a Ride'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Referral Banner ─────────────────────────────────────

  Widget _buildReferralBanner(BuildContext context, WidgetRef ref) {
    final referralAsync = ref.watch(referralInfoProvider);
    final rulesAsync = ref.watch(rewardRulesProvider);

    return referralAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (context, error) => const SizedBox.shrink(),
      data: (referral) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryGold.withOpacity(0.12),
                AppColors.primaryGold.withOpacity(0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AppColors.primaryGold.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.people,
                      color: AppColors.primaryGold, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Refer & Earn Big',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.primaryGold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              rulesAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (context, error) => const SizedBox.shrink(),
                data: (rules) => Text(
                  'Earn ${rules.referral.referrerBonus} GoCoins for every friend who takes their first ride. They get ${rules.referral.newUserBonus} coins!',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : AppColors.textSecondaryLight),
                ),
              ),
              const SizedBox(height: 12),

              // Code display
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      referral.referralCode,
                      style: AppTextStyles.titleMedium.copyWith(
                        letterSpacing: 2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Share button
              Center(
                child: SizedBox(
                  width: 150,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const ReferralBottomSheet(),
                      );
                    },
                    icon: const Icon(Icons.share, size: 16),
                    label: const Text('Share'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: AppColors.backgroundDark,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _referralStat(
                      'Invited', referral.totalReferrals.toString()),
                  _referralStat(
                      'Completed', referral.completedReferrals.toString()),
                  _referralStat(
                      'Earned', '${referral.earnedPoints} pts'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _referralStat(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: AppTextStyles.titleSmall
                .copyWith(color: AppColors.primaryGold)),
        Text(label, style: AppTextStyles.labelSmall.copyWith(
          color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : AppColors.textSecondaryLight,
        )),
      ],
    );
  }
}

// ── Action Button Widget ──────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final String? tooltip;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: enabled
            ? () {
                HapticFeedback.lightImpact();
                onTap();
              }
            : () {
                HapticFeedback.lightImpact();
                if (tooltip != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(tooltip!),
                      backgroundColor: AppColors.surfaceDark,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: enabled
                ? Theme.of(context).cardTheme.color
                : Theme.of(context).cardTheme.color?.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: enabled
                    ? AppColors.primaryGold
                    : AppColors.textMuted,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: enabled
                      ? (Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : AppColors.textPrimaryLight)
                      : AppColors.textMuted,
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

// ── Transaction Card ──────────────────────────────────────

class _TransactionCard extends StatelessWidget {
  final RewardTransaction transaction;

  const _TransactionCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    if (transaction.isRideRelated && transaction.pickupAddress != null) {
      return _buildRideTransactionCard();
    }
    return _buildGenericTransactionCard();
  }

  Widget _buildRideTransactionCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
      ),
      child: Row(
        children: [
          // Route info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pickup
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.error.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        transaction.pickupAddress ?? '',
                        style: AppTextStyles.bodySmall.copyWith(
                            color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : AppColors.textPrimaryLight),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Dropoff
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        transaction.dropoffAddress ?? '',
                        style: AppTextStyles.bodySmall.copyWith(
                            color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : AppColors.textPrimaryLight),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Date + fare
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 12, color: Theme.of(context).brightness == Brightness.dark ? AppColors.textMuted : AppColors.textMutedLight),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(transaction.createdAt),
                      style: AppTextStyles.labelSmall.copyWith(fontSize: 10),
                    ),
                  ],
                ),
                if (transaction.rideFare != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '\u20AC ${transaction.rideFare!.toStringAsFixed(2)}',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.primaryGold,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Right side: vehicle + reward
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Vehicle illustration
              Image.asset(
                AssetPaths.vehicleStandard,
                width: 48,
                height: 32,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.directions_car,
                  color: AppColors.primaryGold,
                  size: 28,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${transaction.points.toStringAsFixed(2)} \u20AC',
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.primaryGold,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Rewards',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primaryGold,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenericTransactionCard() {
    final isPositive = transaction.isPositive;

    IconData typeIcon;
    switch (transaction.type) {
      case 'first_ride_bonus':
        typeIcon = Icons.card_giftcard;
        break;
      case 'referral_new_user':
      case 'referral_referrer':
        typeIcon = Icons.people;
        break;
      case 'weekly_streak':
        typeIcon = Icons.local_fire_department;
        break;
      case 'redemption':
        typeIcon = Icons.sync;
        break;
      default:
        typeIcon = Icons.stars;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isPositive ? AppColors.success : AppColors.error)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              typeIcon,
              color: isPositive ? AppColors.success : AppColors.error,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.displayType,
                  style: AppTextStyles.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  transaction.description,
                  style: AppTextStyles.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(transaction.createdAt),
                  style: AppTextStyles.labelSmall.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          Text(
            '${isPositive ? "+" : ""}${transaction.points.toStringAsFixed(0)} pts',
            style: AppTextStyles.titleSmall.copyWith(
              color: isPositive ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      const months = [
        'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
        'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
      ];
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '${dt.day}-${months[dt.month - 1]}-${dt.year} at $h:$m';
    } catch (_) {
      return isoDate;
    }
  }
}
