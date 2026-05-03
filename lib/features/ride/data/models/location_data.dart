class LocationData {
  final String address;
  final double latitude;
  final double longitude;
  final String? subtitle;

  const LocationData({
    required this.address,
    required this.latitude,
    required this.longitude,
    this.subtitle,
  });

  LocationData copyWith({
    String? address,
    double? latitude,
    double? longitude,
    String? subtitle,
  }) {
    return LocationData(
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      subtitle: subtitle ?? this.subtitle,
    );
  }

  Map<String, dynamic> toJson() => {
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
      };

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      subtitle: json['subtitle'] as String?,
    );
  }
}
