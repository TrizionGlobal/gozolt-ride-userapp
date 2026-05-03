class RideStop {
  final String address;
  final double latitude;
  final double longitude;
  final int stopOrder;

  const RideStop({
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.stopOrder,
  });

  Map<String, dynamic> toJson() => {
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
      };

  factory RideStop.fromJson(Map<String, dynamic> json) {
    return RideStop(
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      stopOrder: (json['stopOrder'] as num).toInt(),
    );
  }
}
