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
  });

  double get surgeAmount =>
      surgeMultiplier > 1.0 ? (estimatedFare - estimatedFare / surgeMultiplier) : 0.0;

  bool get hasSurge => surgeMultiplier > 1.0;

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
    );
  }
}
