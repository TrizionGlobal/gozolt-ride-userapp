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
      earningMultiplier: 1.5,
      discountCap: 20,
      progress: RewardProgress(
        nextTier: 'PLATINUM',
        pointsNeeded: 9380,
        progressPercent: 37.5,
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
      discountCap: 5,
      progress: RewardProgress(
        nextTier: 'SILVER',
        pointsNeeded: 1000,
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
        pointsPerEur: 2,
        firstRideBonus: 100,
        fiveStarRatingBonus: 5,
        scheduledRideBonus: 15,
        weeklyStreakThreshold: 5,
        weeklyStreakBonus: 50,
      ),
      referral: ReferralRules(
        newUserBonus: 150,
        referrerBonus: 200,
      ),
      redemption: RedemptionRules(
        minimumPoints: 200,
        pointsToEurRatio: 100,
        description:
            '100 GoCoins = €1 ride credit. Apply at checkout with the Use Coins toggle.',
      ),
      tiers: [
        TierInfo(
          tier: 'BRONZE',
          minPoints: 0,
          multiplier: 1.0,
          maxDiscount: 5,
          benefits: [
            'Earn 2 coins per €1 spent',
            'Basic support',
          ],
        ),
        TierInfo(
          tier: 'SILVER',
          minPoints: 1000,
          multiplier: 1.2,
          maxDiscount: 10,
          benefits: [
            '1.2x earning multiplier',
            'Up to €10 discount per ride',
            'Priority support',
          ],
        ),
        TierInfo(
          tier: 'GOLD',
          minPoints: 5000,
          multiplier: 1.5,
          maxDiscount: 20,
          benefits: [
            '1.5x earning multiplier',
            'Up to €20 discount per ride',
            'Priority support',
            'Exclusive promotions',
          ],
        ),
        TierInfo(
          tier: 'PLATINUM',
          minPoints: 15000,
          multiplier: 2.0,
          maxDiscount: 50,
          benefits: [
            '2x earning multiplier',
            'Up to €50 discount per ride',
            'Dedicated support line',
            'Exclusive promotions',
            'Early access to new features',
            'Airport lounge access',
          ],
        ),
      ],
      expiry: ExpiryRules(
        inactivityMonths: 12,
        description:
            'Points expire after 12 months of account inactivity.',
      ),
    );
  }
  try {
    final ds = ref.read(rewardsRemoteDatasourceProvider);
    return await ds.getRewardRules();
  } catch (_) {
    return const RewardRules(
      earning: EarningRules(
        pointsPerEur: 2,
        firstRideBonus: 100,
        fiveStarRatingBonus: 5,
        scheduledRideBonus: 15,
        weeklyStreakThreshold: 5,
        weeklyStreakBonus: 50,
      ),
      referral: ReferralRules(
        newUserBonus: 150,
        referrerBonus: 200,
      ),
      redemption: RedemptionRules(
        minimumPoints: 200,
        pointsToEurRatio: 100,
        description: '100 GoCoins = €1 ride credit. Apply at checkout with the Use Coins toggle.',
      ),
      tiers: [],
      expiry: ExpiryRules(
        inactivityMonths: 12,
        description: 'Points expire after 12 months of account inactivity.',
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
    );
  }
  try {
    final ds = ref.read(rewardsRemoteDatasourceProvider);
    return await ds.getReferralInfo();
  } catch (_) {
    return const ReferralInfo(
      referralCode: '',
      totalReferrals: 0,
      completedReferrals: 0,
      earnedPoints: 0,
    );
  }
});
