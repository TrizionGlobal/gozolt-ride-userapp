import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/models/reward_rules.dart';
import '../providers/rewards_providers.dart';
import '../widgets/tier_badge.dart';

class RewardsInfoScreen extends ConsumerWidget {
  const RewardsInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(rewardRulesProvider);
    final summaryAsync = ref.watch(rewardSummaryProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Gold Header ─────────────────────────────────
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
                  padding: const EdgeInsets.fromLTRB(16, 8, 20, 24),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
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
                        'Rewards Info',
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

          // ── Body ────────────────────────────────────────
          rulesAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(
                child:
                    CircularProgressIndicator(color: AppColors.primaryGold),
              ),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.textMuted, size: 40),
                    const SizedBox(height: 8),
                    Text('Failed to load rules',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textSecondary)),
                    TextButton(
                      onPressed: () => ref.invalidate(rewardRulesProvider),
                      child: Text('Retry',
                          style:
                              TextStyle(color: AppColors.primaryGold)),
                    ),
                  ],
                ),
              ),
            ),
            data: (rules) {
              final currentTier =
                  summaryAsync.value?.tier ?? 'BRONZE';
              return SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Section 1: How to Earn
                    _sectionTitle('Collect coins on every ride and turn them into wallet cash'),
                    const SizedBox(height: 16),
                    _bulletPoint(
                        context,
                        'Earn ${rules.earning.pointsPerEur} coins for every \u20AC1 spent on completed rides.'),
                 
                    _bulletPoint(
                        context,
                        'Wallet cash can be used to pay for any of your rides without limit.'),
                    _bulletPoint(
                        context,
                        'Rewards are added automatically after each completed ride.'),
                    _bulletPoint(
                        context,
                        'Reward rules are set by the app admin and may be updated anytime.'),

                    const SizedBox(height: 28),

                    // Section 2: Referral Program
                    _sectionHeader('Referral Program'),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.people,
                                  color: AppColors.primaryGold, size: 20),
                              const SizedBox(width: 8),
                              Text('Invite friends and earn!',
                                  style: AppTextStyles.titleSmall),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _bulletPoint(
                              context,
                              'You get: ${rules.referral.referrerBonus} coins when your friend completes their first ride'),
                          _bulletPoint(
                              context,
                              'They get: ${rules.referral.newUserBonus} coins as a welcome bonus'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Section 3: Tier Table
                    _sectionHeader('Tier Levels'),
                    const SizedBox(height: 12),
                    ...rules.tiers.map((tier) =>
                        _tierCard(context, tier, tier.tier == currentTier)),

                    const SizedBox(height: 28),

                    // Section 4: Redemption Rules
                    _sectionHeader('How to Redeem'),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _bulletPoint(
                              context,
                              'Minimum ${rules.redemption.minimumPoints} coins to redeem'),
                          _bulletPoint(
                              context,
                              'Redeem rate depends on your active tier (up to 100 coins = \u20AC1.00 for Platinum)'),
                          _bulletPoint(
                              context,
                              'Redeemed cash is instantly credited to your wallet balance and can be used on any future bookings.'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Section 6: Expiry
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color:
                                AppColors.warning.withOpacity(0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: AppColors.warning, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Coins expire after ${rules.expiry.inactivityMonths} months of account inactivity.',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                  ]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: AppTextStyles.headlineSmall.copyWith(
        height: 1.3,
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Text(text, style: AppTextStyles.titleLarge);
  }

  Widget _bulletPoint(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bonusCard(
      BuildContext context, IconData icon, String title, String value, Color accentColor) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accentColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleSmall),
                Text(value,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : AppColors.textSecondaryLight)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tierCard(BuildContext context, TierInfo tier, bool isCurrent) {
    final tierColor = _getTierColor(tier.tier);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent ? tierColor : (Theme.of(context).dividerTheme.color ?? Colors.transparent),
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              TierBadge(tier: tier.tier, small: true),
              const Spacer(),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: tierColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'YOUR TIER',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: tierColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 9,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Details
          _tierDetailRow(
              context, 'Minimum requirement', '${tier.minRides} completed rides'),
          if (tier.benefits.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...tier.benefits.map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: tierColor, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        b,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tierDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTextStyles.bodySmall
                  .copyWith(color: Theme.of(context).brightness == Brightness.dark ? AppColors.textMuted : AppColors.textMutedLight)),
          Text(value,
              style: AppTextStyles.bodySmall
                  .copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Color _getTierColor(String tier) {
    switch (tier) {
      case 'BRONZE':
        return const Color(0xFFCD7F32);
      case 'SILVER':
        return const Color(0xFFC0C0C0);
      case 'GOLD':
        return const Color(0xFFF5C518);
      case 'PLATINUM':
        return const Color(0xFFB388FF);
      default:
        return const Color(0xFFCD7F32);
    }
  }

  String _getTierRedeemRate(String tier) {
    switch (tier) {
      case 'PLATINUM':
        return '100 Coins = \u20AC1.00';
      case 'GOLD':
        return '100 Coins = \u20AC0.75';
      case 'SILVER':
        return '100 Coins = \u20AC0.50';
      case 'BRONZE':
      default:
        return '100 Coins = \u20AC0.25';
    }
  }
}
