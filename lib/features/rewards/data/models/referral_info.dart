class ReferralInfo {
  final String referralCode;
  final int totalReferrals;
  final int completedReferrals;
  final int earnedPoints;

  const ReferralInfo({
    required this.referralCode,
    required this.totalReferrals,
    required this.completedReferrals,
    required this.earnedPoints,
  });

  factory ReferralInfo.fromJson(Map<String, dynamic> json) {
    return ReferralInfo(
      referralCode: json['referralCode'] as String? ?? '',
      totalReferrals: (json['totalReferrals'] as num?)?.toInt() ?? 0,
      completedReferrals: (json['completedReferrals'] as num?)?.toInt() ?? 0,
      earnedPoints: (json['earnedPoints'] as num?)?.toInt() ?? 0,
    );
  }
}
