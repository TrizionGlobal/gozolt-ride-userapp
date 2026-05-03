class RewardTransaction {
  final String id;
  final String type;
  final double points;
  final String description;
  final String? rideId;
  final String? pickupAddress;
  final String? dropoffAddress;
  final double? rideFare;
  final String? vehicleType;
  final String createdAt;

  const RewardTransaction({
    required this.id,
    required this.type,
    required this.points,
    required this.description,
    this.rideId,
    this.pickupAddress,
    this.dropoffAddress,
    this.rideFare,
    this.vehicleType,
    required this.createdAt,
  });

  bool get isRideRelated =>
      type == 'ride_completion' ||
      type == 'five_star_bonus' ||
      type == 'scheduled_ride_bonus';

  bool get isRedemption => type == 'redemption';

  bool get isPositive => points > 0;

  String get displayType {
    switch (type) {
      case 'ride_completion':
        return 'Ride Reward';
      case 'first_ride_bonus':
        return 'First Ride Bonus';
      case 'five_star_bonus':
        return '5-Star Bonus';
      case 'scheduled_ride_bonus':
        return 'Schedule Bonus';
      case 'referral_new_user':
        return 'Referral Welcome';
      case 'referral_referrer':
        return 'Referral Reward';
      case 'weekly_streak':
        return 'Weekly Streak';
      case 'redemption':
        return 'Redeemed';
      default:
        return 'Reward';
    }
  }

  factory RewardTransaction.fromJson(Map<String, dynamic> json) {
    return RewardTransaction(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'ride_completion',
      points: (json['points'] as num?)?.toDouble() ?? 0,
      description: json['description'] as String? ?? '',
      rideId: json['rideId'] as String?,
      pickupAddress: json['pickupAddress'] as String?,
      dropoffAddress: json['dropoffAddress'] as String?,
      rideFare: (json['rideFare'] as num?)?.toDouble(),
      vehicleType: json['vehicleType'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}
