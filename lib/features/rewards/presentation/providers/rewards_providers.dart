import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/dio_provider.dart';
import '../../data/datasources/rewards_remote_datasource.dart';
import '../../data/models/referral_info.dart';
import '../../data/models/reward_rules.dart';
import '../../data/models/reward_summary.dart';
import '../../data/models/reward_transaction.dart';

// ── Datasource ──────────────────────────────────────────

final rewardsRemoteDatasourceProvider =
    Provider<RewardsRemoteDatasource>((ref) {
  return RewardsRemoteDatasource(ref.read(dioProvider));
});

// ── Reward Summary ──────────────────────────────────────

final rewardSummaryProvider = FutureProvider.autoDispose<RewardSummary>((ref) async {
  if (AppConstants.kDevBypass) {
    await Future.delayed(const Duration(milliseconds: 400));
    return const RewardSummary(
      tier: 'GOLD',
      totalPoints: 5620,
      currentPoints: 2450,
      earningMultiplier: 1.0,
      discountCap: 99999,
      completedRides: 55,
      nextTierAt: 100,
      ridesRemaining: 45,
      progress: RewardProgress(
        nextTier: 'PLATINUM',
        pointsNeeded: 45,
        progressPercent: 10.0,
      ),
    );
  }
  try {
    final ds = ref.read(rewardsRemoteDatasourceProvider);
    return await ds.getRewardSummary();
  } catch (_) {
    return const RewardSummary(
      tier: 'BRONZE',
      totalPoints: 0,
      currentPoints: 0,
      earningMultiplier: 1.0,
      discountCap: 99999,
      completedRides: 0,
      nextTierAt: 25,
      ridesRemaining: 25,
      progress: RewardProgress(
        nextTier: 'SILVER',
        pointsNeeded: 25,
        progressPercent: 0,
      ),
    );
  }
});

// ── Reward Rules (cached) ───────────────────────────────

final rewardRulesProvider = FutureProvider<RewardRules>((ref) async {
  if (AppConstants.kDevBypass) {
    await Future.delayed(const Duration(milliseconds: 300));
    return const RewardRules(
      earning: EarningRules(
        pointsPerEur: 10,
        firstRideBonus: 0,
        fiveStarRatingBonus: 0,
        scheduledRideBonus: 0,
        weeklyStreakThreshold: 9999,
        weeklyStreakBonus: 0,
      ),
      referral: ReferralRules(
        newUserBonus: 200,
        referrerBonus: 200,
      ),
      redemption: RedemptionRules(
        minimumPoints: 200,
        pointsToEurRatio: 400,
        description:
            '400 GoCoins = €1 wallet credit. Redeem coins directly to your wallet.',
      ),
      tiers: [
        TierInfo(
          tier: 'BRONZE',
          minPoints: 0,
          minRides: 0,
          multiplier: 1.0,
          maxDiscount: 99999,
          benefits: [
            'Earn 10 coins for every €1 spent on rides',
            'Bronze loyalty status',
          ],
        ),
        TierInfo(
          tier: 'SILVER',
          minPoints: 25,
          minRides: 25,
          multiplier: 1.0,
          maxDiscount: 99999,
          benefits: [
            'Earn 10 coins for every €1 spent on rides',
            'Silver loyalty status',
            'Redemption rate: 100 Coins = €0.50',
          ],
        ),
        TierInfo(
          tier: 'GOLD',
          minPoints: 50,
          minRides: 50,
          multiplier: 1.0,
          maxDiscount: 99999,
          benefits: [
            'Earn 10 coins for every €1 spent on rides',
            'Gold loyalty status',
            'Redemption rate: 100 Coins = €0.75',
          ],
        ),
        TierInfo(
          tier: 'PLATINUM',
          minPoints: 100,
          minRides: 100,
          multiplier: 1.0,
          maxDiscount: 99999,
          benefits: [
            'Earn 10 coins for every €1 spent on rides',
            'Platinum loyalty status',
            'Redemption rate: 100 Coins = €1.00',
          ],
        ),
      ],
      expiry: ExpiryRules(
        inactivityMonths: 6,
        description:
            'Coins expire after 6 months of account inactivity.',
      ),
    );
  }
  try {
    final ds = ref.read(rewardsRemoteDatasourceProvider);
    return await ds.getRewardRules();
  } catch (_) {
    return const RewardRules(
      earning: EarningRules(
        pointsPerEur: 10,
        firstRideBonus: 0,
        fiveStarRatingBonus: 0,
        scheduledRideBonus: 0,
        weeklyStreakThreshold: 9999,
        weeklyStreakBonus: 0,
      ),
      referral: ReferralRules(
        newUserBonus: 200,
        referrerBonus: 200,
      ),
      redemption: RedemptionRules(
        minimumPoints: 200,
        pointsToEurRatio: 400,
        description: '400 GoCoins = €1 wallet credit. Redeem coins directly to your wallet.',
      ),
      tiers: [
        TierInfo(
          tier: 'BRONZE',
          minPoints: 0,
          minRides: 0,
          multiplier: 1.0,
          maxDiscount: 99999,
          benefits: [
            'Earn 10 coins for every €1 spent on rides',
            'Bronze loyalty status',
          ],
        ),
        TierInfo(
          tier: 'SILVER',
          minPoints: 25,
          minRides: 25,
          multiplier: 1.0,
          maxDiscount: 99999,
          benefits: [
            'Earn 10 coins for every €1 spent on rides',
            'Silver loyalty status',
            'Redemption rate: 100 Coins = €0.50',
          ],
        ),
        TierInfo(
          tier: 'GOLD',
          minPoints: 50,
          minRides: 50,
          multiplier: 1.0,
          maxDiscount: 99999,
          benefits: [
            'Earn 10 coins for every €1 spent on rides',
            'Gold loyalty status',
            'Redemption rate: 100 Coins = €0.75',
          ],
        ),
        TierInfo(
          tier: 'PLATINUM',
          minPoints: 100,
          minRides: 100,
          multiplier: 1.0,
          maxDiscount: 99999,
          benefits: [
            'Earn 10 coins for every €1 spent on rides',
            'Platinum loyalty status',
            'Redemption rate: 100 Coins = €1.00',
          ],
        ),
      ],
      expiry: ExpiryRules(
        inactivityMonths: 6,
        description: 'Coins expire after 6 months of account inactivity.',
      ),
    );
  }
});

// ── Reward History (paginated) ──────────────────────────

final rewardHistoryProvider =
    StateNotifierProvider<RewardHistoryNotifier, AsyncValue<List<RewardTransaction>>>(
        (ref) {
  return RewardHistoryNotifier(ref);
});

class RewardHistoryNotifier
    extends StateNotifier<AsyncValue<List<RewardTransaction>>> {
  final Ref _ref;
  int _page = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  RewardHistoryNotifier(this._ref) : super(const AsyncValue.loading()) {
    load();
  }

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  Future<void> load() async {
    state = const AsyncValue.loading();
    _page = 1;
    _hasMore = true;
    try {
      final items = await _fetchPage(1);
      state = AsyncValue.data(items);
    } catch (e) {
      // Return empty list for new users instead of error
      state = const AsyncValue.data([]);
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    try {
      final items = await _fetchPage(_page + 1);
      if (items.isEmpty) {
        _hasMore = false;
      } else {
        _page++;
        state = AsyncValue.data([...state.value ?? [], ...items]);
      }
    } catch (_) {
      // Keep existing data on pagination error
    }
    _isLoadingMore = false;
  }

  Future<List<RewardTransaction>> _fetchPage(int page) async {
    final ds = _ref.read(rewardsRemoteDatasourceProvider);
    return ds.getRewardHistory(page: page);
  }
}

// ── Referral Info ───────────────────────────────────────

final referralInfoProvider = FutureProvider<ReferralInfo>((ref) async {
  if (AppConstants.kDevBypass) {
    await Future.delayed(const Duration(milliseconds: 300));
    return const ReferralInfo(
      referralCode: 'GOCOIN-MRK42',
      totalReferrals: 8,
      completedReferrals: 5,
      earnedPoints: 250,
      referralsList: [],
    );
  }
  try {
    final ds = ref.read(rewardsRemoteDatasourceProvider);
    return await ds.getReferralInfo();
  } catch (_) {
    return const ReferralInfo(
      referralCode: 'GOZOLT-TEMP',
      totalReferrals: 0,
      completedReferrals: 0,
      earnedPoints: 0,
      referralsList: [],
    );
  }
});
