class EarningRules {
  final int pointsPerEur;
  final int firstRideBonus;
  final int fiveStarRatingBonus;
  final int scheduledRideBonus;
  final int weeklyStreakThreshold;
  final int weeklyStreakBonus;

  const EarningRules({
    required this.pointsPerEur,
    required this.firstRideBonus,
    required this.fiveStarRatingBonus,
    required this.scheduledRideBonus,
    required this.weeklyStreakThreshold,
    required this.weeklyStreakBonus,
  });

  factory EarningRules.fromJson(Map<String, dynamic> json) {
    return EarningRules(
      pointsPerEur: (json['pointsPerEur'] as num?)?.toInt() ?? 1,
      firstRideBonus: (json['firstRideBonus'] as num?)?.toInt() ?? 50,
      fiveStarRatingBonus: (json['fiveStarRatingBonus'] as num?)?.toInt() ?? 5,
      scheduledRideBonus: (json['scheduledRideBonus'] as num?)?.toInt() ?? 10,
      weeklyStreakThreshold:
          (json['weeklyStreakThreshold'] as num?)?.toInt() ?? 5,
      weeklyStreakBonus: (json['weeklyStreakBonus'] as num?)?.toInt() ?? 25,
    );
  }
}

class ReferralRules {
  final int newUserBonus;
  final int referrerBonus;

  const ReferralRules({
    required this.newUserBonus,
    required this.referrerBonus,
  });

  factory ReferralRules.fromJson(Map<String, dynamic> json) {
    return ReferralRules(
      newUserBonus: (json['newUserBonus'] as num?)?.toInt() ?? 100,
      referrerBonus: (json['referrerBonus'] as num?)?.toInt() ?? 50,
    );
  }
}

class RedemptionRules {
  final int minimumPoints;
  final double pointsToEurRatio;
  final String description;

  const RedemptionRules({
    required this.minimumPoints,
    required this.pointsToEurRatio,
    required this.description,
  });

  factory RedemptionRules.fromJson(Map<String, dynamic> json) {
    return RedemptionRules(
      minimumPoints: (json['minimumPoints'] as num?)?.toInt() ?? 200,
      pointsToEurRatio:
          (json['pointsToEurRatio'] as num?)?.toDouble() ?? 200.0,
      description: json['description'] as String? ?? '',
    );
  }
}

class TierInfo {
  final String tier;
  final int minPoints;
  final int minRides;
  final double multiplier;
  final double maxDiscount;
  final List<String> benefits;

  const TierInfo({
    required this.tier,
    required this.minPoints,
    required this.minRides,
    required this.multiplier,
    required this.maxDiscount,
    required this.benefits,
  });

  String get displayName {
    switch (tier) {
      case 'BRONZE':
        return 'Bronze';
      case 'SILVER':
        return 'Silver';
      case 'GOLD':
        return 'Gold';
      case 'PLATINUM':
        return 'Platinum';
      default:
        return tier;
    }
  }

  factory TierInfo.fromJson(Map<String, dynamic> json) {
    final minPts = (json['minPoints'] as num?)?.toInt() ?? 0;
    return TierInfo(
      tier: json['tier'] as String? ?? 'BRONZE',
      minPoints: minPts,
      minRides: (json['minRides'] as num?)?.toInt() ?? minPts,
      multiplier: (json['multiplier'] as num?)?.toDouble() ?? 1.0,
      maxDiscount: (json['maxDiscount'] as num?)?.toDouble() ?? 5.0,
      benefits: (json['benefits'] as List<dynamic>?)
              ?.map((b) => b as String)
              .toList() ??
          [],
    );
  }
}

class ExpiryRules {
  final int inactivityMonths;
  final String description;

  const ExpiryRules({
    required this.inactivityMonths,
    required this.description,
  });

  factory ExpiryRules.fromJson(Map<String, dynamic> json) {
    return ExpiryRules(
      inactivityMonths: (json['inactivityMonths'] as num?)?.toInt() ?? 6,
      description: json['description'] as String? ?? '',
    );
  }
}

class RewardRules {
  final EarningRules earning;
  final ReferralRules referral;
  final RedemptionRules redemption;
  final List<TierInfo> tiers;
  final ExpiryRules expiry;

  const RewardRules({
    required this.earning,
    required this.referral,
    required this.redemption,
    required this.tiers,
    required this.expiry,
  });

  TierInfo? tierFor(String tierName) {
    try {
      return tiers.firstWhere((t) => t.tier == tierName);
    } catch (_) {
      return null;
    }
  }

  factory RewardRules.fromJson(Map<String, dynamic> json) {
    return RewardRules(
      earning: EarningRules.fromJson(
          json['earning'] as Map<String, dynamic>? ?? {}),
      referral: ReferralRules.fromJson(
          json['referral'] as Map<String, dynamic>? ?? {}),
      redemption: RedemptionRules.fromJson(
          json['redemption'] as Map<String, dynamic>? ?? {}),
      tiers: (json['tiers'] as List<dynamic>?)
              ?.map((t) => TierInfo.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
      expiry: ExpiryRules.fromJson(
          json['expiry'] as Map<String, dynamic>? ?? {}),
    );
  }
}
