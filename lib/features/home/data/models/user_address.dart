class UserAddress {
  final String id;
  final String label;
  final String address;
  final double? latitude;
  final double? longitude;

  const UserAddress({
    required this.id,
    required this.label,
    required this.address,
    this.latitude,
    this.longitude,
  });

  factory UserAddress.fromJson(Map<String, dynamic> json) {
    return UserAddress(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}
