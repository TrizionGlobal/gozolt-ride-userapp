class DriverLocation {
  final double latitude;
  final double longitude;
  final double? heading;
  final double? speed;
  final String? timestamp;

  const DriverLocation({
    required this.latitude,
    required this.longitude,
    this.heading,
    this.speed,
    this.timestamp,
  });

  factory DriverLocation.fromJson(Map<String, dynamic> json) {
    return DriverLocation(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      timestamp: json['timestamp'] as String?,
    );
  }
}
