class ReferralInfo {
  final String referralCode;
  final int totalReferrals;
  final int completedReferrals;
  final int earnedPoints;
  final List<ReferredUser> referralsList;

  const ReferralInfo({
    required this.referralCode,
    required this.totalReferrals,
    required this.completedReferrals,
    required this.earnedPoints,
    required this.referralsList,
  });

  factory ReferralInfo.fromJson(Map<String, dynamic> json) {
    return ReferralInfo(
      referralCode: json['referralCode'] as String? ?? '',
      totalReferrals: (json['totalReferrals'] as num?)?.toInt() ?? 0,
      completedReferrals: (json['completedReferrals'] as num?)?.toInt() ?? 0,
      earnedPoints: ((json['earnedPoints'] ?? json['pointsEarned']) as num?)?.toInt() ?? 0,
      referralsList: (json['referralsList'] as List<dynamic>?)
              ?.map((e) => ReferredUser.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ReferredUser {
  final String id;
  final String name;
  final DateTime? joinedAt;
  final String status;
  final bool hasCompletedRide;

  const ReferredUser({
    required this.id,
    required this.name,
    this.joinedAt,
    required this.status,
    required this.hasCompletedRide,
  });

  factory ReferredUser.fromJson(Map<String, dynamic> json) {
    return ReferredUser(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Anonymous Friend',
      joinedAt: json['joinedAt'] != null ? DateTime.tryParse(json['joinedAt']) : null,
      status: json['status'] as String? ?? 'Pending',
      hasCompletedRide: json['hasCompletedRide'] as bool? ?? false,
    );
  }
}
