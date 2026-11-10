class RewardProgress {
  final String? nextTier;
  final int pointsNeeded;
  final double progressPercent;

  const RewardProgress({
    this.nextTier,
    required this.pointsNeeded,
    required this.progressPercent,
  });

  factory RewardProgress.fromJson(Map<String, dynamic> json) {
    return RewardProgress(
      nextTier: json['nextTier'] as String?,
      pointsNeeded: (json['pointsNeeded'] as num?)?.toInt() ?? 0,
      progressPercent: (json['progressPercent'] as num?)?.toDouble() ?? 0,
    );
  }
}

class RewardSummary {
  final String tier;
  final double totalPoints;
  final double currentPoints;
  final double earningMultiplier;
  final double discountCap;
  final RewardProgress progress;
  final int completedBookings;
  final int completedRides;
  final int nextTierAt;
  final int ridesRemaining;
  final double tierRedemptionRate;
  final double euroPerPoint;
  final int coinsToEurRatio;
  final Map<String, double>? tierRedemptionRates;

  const RewardSummary({
    required this.tier,
    required this.totalPoints,
    required this.currentPoints,
    required this.earningMultiplier,
    required this.discountCap,
    required this.progress,
    this.completedBookings = 0,
    this.completedRides = 0,
    this.nextTierAt = 0,
    this.ridesRemaining = 0,
    this.tierRedemptionRate = 1.0,
    this.euroPerPoint = 0.01,
    this.coinsToEurRatio = 100,
    this.tierRedemptionRates,
  });

  bool get isBronze => tier == 'BRONZE';
  bool get isMaxTier => progress.nextTier == null;

  double get coinValueInEur {
    if (euroPerPoint > 0) return euroPerPoint;
    if (tierRedemptionRate > 0) return tierRedemptionRate / 100.0;
    switch (tier) {
      case 'PLATINUM':
        return 0.07;
      case 'GOLD':
        return 0.05;
      case 'SILVER':
        return 0.03;
      default:
        return 0.01;
    }
  }

  String get displayTier {
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

  factory RewardSummary.fromJson(Map<String, dynamic> json) {
    final bookings = (json['completedBookings'] ?? json['completedRides'] as num?)?.toInt() ?? 0;
    
    Map<String, double>? rates;
    if (json['tierRedemptionRates'] is Map) {
      rates = (json['tierRedemptionRates'] as Map).map(
        (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
      );
    }

    final tier = json['tier'] as String? ?? 'BRONZE';
    final dynamicRate = (json['tierRedemptionRate'] as num?)?.toDouble() ??
        rates?[tier] ??
        (tier == 'PLATINUM'
            ? 7.0
            : tier == 'GOLD'
                ? 5.0
                : tier == 'SILVER'
                    ? 3.0
                    : 1.0);

    final perPoint = (json['euroPerPoint'] as num?)?.toDouble() ?? (dynamicRate / 100.0);

    return RewardSummary(
      tier: tier,
      totalPoints: (json['totalPoints'] as num?)?.toDouble() ?? 0,
      currentPoints: (json['currentPoints'] as num?)?.toDouble() ?? 0,
      earningMultiplier: (json['earningMultiplier'] as num?)?.toDouble() ?? 1.0,
      discountCap: (json['discountCap'] as num?)?.toDouble() ?? 5.0,
      completedBookings: bookings,
      completedRides: bookings,
      nextTierAt: (json['nextTierAt'] as num?)?.toInt() ?? 0,
      ridesRemaining: (json['ridesRemaining'] as num?)?.toInt() ?? 0,
      tierRedemptionRate: dynamicRate,
      euroPerPoint: perPoint,
      coinsToEurRatio: (json['coinsToEurRatio'] as num?)?.toInt() ??
          (dynamicRate > 0 ? (100.0 / dynamicRate).round() : 100),
      tierRedemptionRates: rates,
      progress: json['progress'] != null
          ? RewardProgress.fromJson(json['progress'] as Map<String, dynamic>)
          : const RewardProgress(pointsNeeded: 0, progressPercent: 0),
    );
  }
}
