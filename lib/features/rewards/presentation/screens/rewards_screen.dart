import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/asset_paths.dart';
import '../../../../core/router/route_names.dart';
import '../../data/models/reward_transaction.dart';
import '../../data/models/reward_summary.dart';
import '../providers/rewards_providers.dart';
import '../widgets/redeem_bottom_sheet.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../widgets/tier_badge.dart';

class RewardsScreen extends ConsumerStatefulWidget {
  const RewardsScreen({super.key});

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen> {
  String? _previousTier;

  String _tierRedeemRateText(String tier) {
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

  int _tierWeight(String tier) {
    switch (tier) {
      case 'BRONZE':
        return 0;
      case 'SILVER':
        return 1;
      case 'GOLD':
        return 2;
      case 'PLATINUM':
        return 3;
      default:
        return 0;
    }
  }

  LinearGradient _tierGradient(String tier) {
    switch (tier) {
      case 'BRONZE':
        return const LinearGradient(
          colors: [Color(0xFF8C5A3C), Color(0xFF5A3825)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'SILVER':
        return const LinearGradient(
          colors: [Color(0xFFBDC3C7), Color(0xFF7F8C8D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'GOLD':
        return const LinearGradient(
          colors: [Color(0xFFF5C518), Color(0xFFD4A843)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'PLATINUM':
        return const LinearGradient(
          colors: [Color(0xFF1E272C), Color(0xFF0F1416)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF8C5A3C), Color(0xFF5A3825)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  void _showCelebrationDialog(String tierName) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Celebration',
      barrierColor: Colors.black.withOpacity(0.85),
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (context, anim1, anim2) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final curve = CurvedAnimation(parent: anim1, curve: Curves.elasticOut);
        return Transform.scale(
          scale: curve.value,
          child: FadeTransition(
            opacity: anim1,
            child: AlertDialog(
              backgroundColor: Colors.transparent,
              contentPadding: EdgeInsets.zero,
              content: _buildCelebrationContent(tierName),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCelebrationContent(String tierName) {
    final gradient = _tierGradient(tierName);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        border: tierName == 'PLATINUM'
            ? Border.all(color: const Color(0xFF8E2DE2), width: 2)
            : Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
          if (tierName == 'PLATINUM')
            BoxShadow(
              color: const Color(0xFF4A00E0).withOpacity(0.5),
              blurRadius: 15,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.15),
            ),
            child: Icon(
              tierName == 'PLATINUM'
                  ? Icons.diamond
                  : tierName == 'GOLD'
                      ? Icons.workspace_premium
                      : Icons.shield,
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'CONGRATULATIONS!',
            style: AppTextStyles.labelLarge.copyWith(
              color: Colors.white.withOpacity(0.9),
              letterSpacing: 2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tier Upgraded to $tierName',
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'You have unlocked exclusive $tierName benefits!',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'AWESOME',
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCoinsCard(BuildContext context, RewardSummary summary) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOTAL COINS',
                style: AppTextStyles.labelSmall.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: summary.currentPoints),
                    duration: const Duration(seconds: 1),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Text(
                        value.toStringAsFixed(0),
                        style: const TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryGold,
                          fontFamily: 'Roboto',
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Coins',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Lifetime earned: ${summary.totalPoints.toStringAsFixed(0)}',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryGold.withOpacity(0.1),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGold.withOpacity(0.2),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.stars,
              color: AppColors.primaryGold,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTierCard(BuildContext context, RewardSummary summary) {
    final tier = summary.tier;
    final gradient = _tierGradient(tier);
    final isPlatinum = tier == 'PLATINUM';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        border: isPlatinum
            ? Border.all(color: const Color(0xFF8E2DE2), width: 1.5)
            : Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          if (isPlatinum)
            BoxShadow(
              color: const Color(0xFF4A00E0).withOpacity(0.4),
              blurRadius: 12,
              spreadRadius: 1,
            )
          else
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'CURRENT STATUS',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  summary.displayTier,
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                if (tier != 'BRONZE') ...[
                  const SizedBox(height: 6),
                  Text(
                    isPlatinum
                        ? 'Elite Level Member'
                        : 'Multiplier: ${summary.earningMultiplier.toStringAsFixed(1)}x Earnings',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.currency_exchange, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            _tierRedeemRateText(tier),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.15),
            ),
            child: Icon(
              tier == 'PLATINUM'
                  ? Icons.diamond
                  : tier == 'GOLD'
                      ? Icons.workspace_premium
                      : Icons.shield,
              color: Colors.white,
              size: 36,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierProgressSection(BuildContext context, RewardSummary summary) {
    if (summary.isMaxTier) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
        ),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.stars, color: AppColors.primaryGold, size: 28),
              const SizedBox(height: 8),
              Text(
                'Maximum Tier Reached!',
                style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'You are currently at the highest loyalty status.',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    final nextTierName = summary.progress.nextTier == 'BRONZE'
        ? 'Bronze'
        : summary.progress.nextTier == 'SILVER'
            ? 'Silver'
            : summary.progress.nextTier == 'GOLD'
                ? 'Gold'
                : summary.progress.nextTier == 'PLATINUM'
                    ? 'Platinum'
                    : (summary.progress.nextTier ?? '');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tier Progress',
                style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                '${summary.completedRides} / ${summary.nextTierAt} Rides',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primaryGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: summary.progress.progressPercent / 100),
              duration: const Duration(seconds: 1),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.inputDark : Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Complete ${summary.ridesRemaining} more rides to unlock $nextTierName Tier!',
            style: AppTextStyles.bodySmall.copyWith(
              color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRedeemCoinsButton(BuildContext context, RewardSummary summary) {
    final canRedeem = summary.currentPoints >= 200;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: canRedeem
                ? () {
                    HapticFeedback.mediumImpact();
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const RedeemBottomSheet(),
                    );
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              foregroundColor: AppColors.backgroundDark,
              disabledBackgroundColor: AppColors.primaryGold.withOpacity(0.15),
              disabledForegroundColor: AppColors.textMuted,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: canRedeem ? 2 : 0,
            ),
            child: Text(
              'Redeem Coins',
              style: AppTextStyles.button.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          if (!canRedeem) ...[
            const SizedBox(height: 6),
            Center(
              child: Text(
                'Need at least 200 coins to redeem.',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.error.withOpacity(0.8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEarnMoreCoinsInfoCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryGold.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryGold.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: AppColors.primaryGold,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Earn More Coins',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.primaryGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Earn 10 coins for every \u20AC1 spent on rides. Coins are credited automatically upon completion.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierBenefitsSection(
      BuildContext context, RewardSummary summary, dynamic rules) {
    final currentTier = rules.tierFor(summary.tier);
    if (currentTier == null || currentTier.benefits.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
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
                  color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                  letterSpacing: 1,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...currentTier.benefits.map<Widget>((benefit) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppColors.primaryGold, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        benefit as String,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => context.pushNamed(RouteNames.rewardsInfo),
            child: Row(
              children: [
                Text(
                  'View all tiers & benefits',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primaryGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 10,
                  color: AppColors.primaryGold,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralSection(BuildContext context, WidgetRef ref) {
    final referralAsync = ref.watch(referralInfoProvider);
    final rulesAsync = ref.watch(rewardRulesProvider);

    return referralAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (context, error) => const SizedBox.shrink(),
      data: (referral) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people, color: AppColors.primaryGold, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Invite Friends',
                  style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            rulesAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (context, error) => const SizedBox.shrink(),
              data: (rules) => Text(
                'Invite friends and earn ${rules.referral.referrerBonus} coins. They get ${rules.referral.newUserBonus} coins after their first completed ride!',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? AppColors.inputDark : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      referral.referralCode,
                      style: AppTextStyles.titleMedium.copyWith(
                        letterSpacing: 2,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryGold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: referral.referralCode));
                      HapticFeedback.lightImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Referral code copied to clipboard!'),
                          backgroundColor: AppColors.success,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    tooltip: 'Copy Code',
                  ),
                  Builder(
                    builder: (context) {
                      return IconButton(
                        icon: const Icon(Icons.share, size: 20),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          final box = context.findRenderObject() as RenderBox?;
                          final rect = box != null ? box.localToGlobal(Offset.zero) & box.size : null;
                          Share.share(
                            'Use my referral code ${referral.referralCode} to get 200 GoCoins on your first Gozolt ride!',
                            subject: 'Join Gozolt Rewards',
                            sharePositionOrigin: rect,
                          );
                        },
                        tooltip: 'Share Code',
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _referralStat(context, 'Invited', referral.totalReferrals.toString()),
                _referralStat(context, 'Completed', referral.completedReferrals.toString()),
                _referralStat(context, 'Earned', '${referral.earnedPoints} coins'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _referralStat(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(value,
            style: AppTextStyles.titleSmall
                .copyWith(color: AppColors.primaryGold, fontWeight: FontWeight.bold)),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      height: 100,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
      ),
      child: ShimmerWrap(
        child: Row(
          children: [
            const ShimmerCircle(radius: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  ShimmerText(width: 140, height: 16),
                  SizedBox(height: 8),
                  ShimmerText(width: 80, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.invalidate(rewardSummaryProvider);
              ref.read(rewardHistoryProvider.notifier).load();
            },
            child: const Text(
              'Retry',
              style: TextStyle(color: AppColors.primaryGold, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

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

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(rewardSummaryProvider);
    final historyAsync = ref.watch(rewardHistoryProvider);
    final rulesAsync = ref.watch(rewardRulesProvider);

    ref.listen<AsyncValue<RewardSummary>>(rewardSummaryProvider, (previous, next) {
      if (next.hasValue) {
        final nextVal = next.value!;
        final prevVal = previous?.value;
        if (prevVal != null) {
          if (prevVal.tier != nextVal.tier &&
              _tierWeight(nextVal.tier) > _tierWeight(prevVal.tier)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showCelebrationDialog(nextVal.tier);
            });
          }
        } else if (_previousTier != null && _previousTier != nextVal.tier) {
          if (_tierWeight(nextVal.tier) > _tierWeight(_previousTier!)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showCelebrationDialog(nextVal.tier);
            });
          }
        }
        _previousTier = nextVal.tier;
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFD4A843), Color(0xFFF5C518)],
            ),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
          ),
        ),
        title: Text(
          'Rewards',
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.backgroundDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: AppColors.backgroundDark),
            onPressed: () => context.pushNamed(RouteNames.rewardsInfo),
          ),
        ],
      ),
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
            // 1. Total Coins Card
            SliverToBoxAdapter(
              child: summaryAsync.when(
                loading: () => _buildShimmerCard(),
                error: (err, _) => _buildErrorCard('Failed to load balance'),
                data: (summary) => _buildTotalCoinsCard(context, summary),
              ),
            ),

            // 2. Current Tier Card
            SliverToBoxAdapter(
              child: summaryAsync.when(
                loading: () => _buildShimmerCard(),
                error: (err, _) => _buildErrorCard('Failed to load tier'),
                data: (summary) => _buildCurrentTierCard(context, summary),
              ),
            ),

            // 3. Tier Progress Section
            SliverToBoxAdapter(
              child: summaryAsync.when(
                loading: () => _buildShimmerCard(),
                error: (err, _) => _buildErrorCard('Failed to load progress'),
                data: (summary) => _buildTierProgressSection(context, summary),
              ),
            ),

            // 4. Redeem Coins Button
            SliverToBoxAdapter(
              child: summaryAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (err, _) => const SizedBox.shrink(),
                data: (summary) => _buildRedeemCoinsButton(context, summary),
              ),
            ),

            // 5. Earn More Coins Info Card
            SliverToBoxAdapter(
              child: _buildEarnMoreCoinsInfoCard(context),
            ),

            // 6. Tier Benefits Section
            SliverToBoxAdapter(
              child: summaryAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (err, _) => const SizedBox.shrink(),
                data: (summary) => rulesAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (err, _) => const SizedBox.shrink(),
                  data: (rules) => _buildTierBenefitsSection(context, summary, rules),
                ),
              ),
            ),

            // 7. Referral Section
            SliverToBoxAdapter(
              child: _buildReferralSection(context, ref),
            ),

            // 8. Rewards History Title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Text(
                  'Transaction History',
                  style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // 9. Rewards History Transactions List
            historyAsync.when(
              loading: () => SliverToBoxAdapter(
                child: buildShimmerList(
                  itemBuilder: () => const ShimmerListTile(),
                  count: 3,
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
                        final notifier = ref.read(rewardHistoryProvider.notifier);
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
                      return _TransactionCard(transaction: transactions[index]);
                    },
                    childCount: transactions.length + 1,
                  ),
                );
              },
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
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
      return _buildRideTransactionCard(context);
    }
    return _buildGenericTransactionCard(context);
  }

  Widget _buildRideTransactionCard(BuildContext context) {
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
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

  Widget _buildGenericTransactionCard(BuildContext context) {
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
            '${isPositive ? "+" : ""}${transaction.points.toStringAsFixed(0)} coins',
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
