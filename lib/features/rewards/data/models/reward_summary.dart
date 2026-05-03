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

  const RewardSummary({
    required this.tier,
    required this.totalPoints,
    required this.currentPoints,
    required this.earningMultiplier,
    required this.discountCap,
    required this.progress,
  });

  bool get isBronze => tier == 'BRONZE';
  bool get isMaxTier => progress.nextTier == null;

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
    return RewardSummary(
      tier: json['tier'] as String? ?? 'BRONZE',
      totalPoints: (json['totalPoints'] as num?)?.toDouble() ?? 0,
      currentPoints: (json['currentPoints'] as num?)?.toDouble() ?? 0,
      earningMultiplier: (json['earningMultiplier'] as num?)?.toDouble() ?? 1.0,
      discountCap: (json['discountCap'] as num?)?.toDouble() ?? 5.0,
      progress: json['progress'] != null
          ? RewardProgress.fromJson(json['progress'] as Map<String, dynamic>)
          : const RewardProgress(pointsNeeded: 0, progressPercent: 0),
    );
  }
}
