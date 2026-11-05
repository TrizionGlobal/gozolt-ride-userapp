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

  bool get isRedemption =>
      type == 'redemption' ||
      type.endsWith('_redemption');

  bool get isPositive => points > 0;

  String get displayType {
    switch (type) {
      case 'ride_completion':
        return 'Ride Reward';
      case 'rental_completion':
        return 'Car Rental Reward';
      case 'bike_rental_completion':
        return 'Bike Rental Reward';
      case 'quick_service_completion':
        return 'Quick Service Reward';
      case 'airport_transfer_completion':
        return 'Airport Transfer Reward';
      case 'redemption':
        return 'Wallet Credit Redeemed';
      case 'ride_redemption':
        return 'Ride Discount';
      case 'car_rental_redemption':
        return 'Car Rental Discount';
      case 'bike_rental_redemption':
        return 'Bike Rental Discount';
      case 'airport_transfer_redemption':
        return 'Airport Transfer Discount';
      case 'quick_service_redemption':
        return 'Quick Service Discount';
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
      case 'signup_bonus':
        return 'Welcome Bonus';
      case 'weekly_streak':
      case 'weekly_streak_bonus':
        return 'Weekly Streak';
      case 'tier_upgrade_bonus_silver_25':
        return 'Silver Tier Reward';
      case 'tier_upgrade_bonus_gold_50':
        return 'Gold Tier Reward';
      case 'tier_upgrade_bonus_platinum_100':
        return 'Platinum Tier Reward';
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
