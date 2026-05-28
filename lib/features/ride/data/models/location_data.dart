class LocationData {
  final String address;
  final double latitude;
  final double longitude;
  final String? subtitle;
  final String? placeId;

  const LocationData({
    required this.address,
    required this.latitude,
    required this.longitude,
    this.subtitle,
    this.placeId,
  });

  LocationData copyWith({
    String? address,
    double? latitude,
    double? longitude,
    String? subtitle,
    String? placeId,
  }) {
    return LocationData(
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      subtitle: subtitle ?? this.subtitle,
      placeId: placeId ?? this.placeId,
    );
  }

  Map<String, dynamic> toJson() => {
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        if (placeId != null) 'placeId': placeId,
      };

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      subtitle: json['subtitle'] as String?,
      placeId: json['placeId'] as String?,
    );
  }
}
