class FareEstimate {
  final double baseFare;
  final double distanceFare;
  final double timeFare;
  final double bookingFee;
  final double surgeMultiplier;
  final double estimatedFare;
  final double distanceKm;
  final int durationMinutes;
  final int etaMinutes;
  final int? goCoinsEarned;

  const FareEstimate({
    required this.baseFare,
    required this.distanceFare,
    required this.timeFare,
    required this.bookingFee,
    required this.surgeMultiplier,
    required this.estimatedFare,
    required this.distanceKm,
    required this.durationMinutes,
    required this.etaMinutes,
    this.goCoinsEarned,
  });

  double get surgeAmount =>
      surgeMultiplier > 1.0 ? (estimatedFare - estimatedFare / surgeMultiplier) : 0.0;

  bool get hasSurge => surgeMultiplier > 1.0;

  FareEstimate copyWith({
    double? baseFare,
    double? distanceFare,
    double? timeFare,
    double? bookingFee,
    double? surgeMultiplier,
    double? estimatedFare,
    double? distanceKm,
    int? durationMinutes,
    int? etaMinutes,
    int? goCoinsEarned,
  }) {
    return FareEstimate(
      baseFare: baseFare ?? this.baseFare,
      distanceFare: distanceFare ?? this.distanceFare,
      timeFare: timeFare ?? this.timeFare,
      bookingFee: bookingFee ?? this.bookingFee,
      surgeMultiplier: surgeMultiplier ?? this.surgeMultiplier,
      estimatedFare: estimatedFare ?? this.estimatedFare,
      distanceKm: distanceKm ?? this.distanceKm,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      goCoinsEarned: goCoinsEarned ?? this.goCoinsEarned,
    );
  }

  factory FareEstimate.fromJson(Map<String, dynamic> json) {
    return FareEstimate(
      baseFare: (json['baseFare'] as num).toDouble(),
      distanceFare: (json['distanceFare'] as num).toDouble(),
      timeFare: (json['timeFare'] as num).toDouble(),
      bookingFee: (json['bookingFee'] as num).toDouble(),
      surgeMultiplier: (json['surgeMultiplier'] as num?)?.toDouble() ?? 1.0,
      estimatedFare: (json['estimatedFare'] as num).toDouble(),
      distanceKm: (json['distanceKm'] as num).toDouble(),
      durationMinutes: (json['durationMinutes'] as num).toInt(),
      etaMinutes: (json['etaMinutes'] as num).toInt(),
      goCoinsEarned: json['goCoinsEarned'] != null ? (json['goCoinsEarned'] as num).toInt() : null,
    );
  }
}
