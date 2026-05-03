class DriverInfo {
  final String id;
  final String name;
  final String phone;
  final double rating;
  final int totalRides;
  final String? avatarUrl;
  final String vehicleMake;
  final String vehicleModel;
  final String vehicleColor;
  final String plateNumber;
  final String vehicleType;
  final String? memberSince;

  const DriverInfo({
    required this.id,
    required this.name,
    required this.phone,
    required this.rating,
    this.totalRides = 0,
    this.avatarUrl,
    required this.vehicleMake,
    required this.vehicleModel,
    required this.vehicleColor,
    required this.plateNumber,
    required this.vehicleType,
    this.memberSince,
  });

  String get vehicleDescription => '$vehicleMake $vehicleModel';
  String get formattedPlate => plateNumber;

  factory DriverInfo.fromJson(Map<String, dynamic> json) {
    final vehicle = json['vehicle'] as Map<String, dynamic>? ?? {};
    return DriverInfo(
      id: json['driverId'] as String? ?? json['id'] as String? ?? '',
      name: json['driverName'] as String? ?? json['name'] as String? ?? 'Driver',
      phone: json['driverPhone'] as String? ?? json['phone'] as String? ?? '',
      rating: (json['driverRating'] as num?)?.toDouble() ??
          (json['rating'] as num?)?.toDouble() ??
          5.0,
      totalRides: (json['totalRides'] as num?)?.toInt() ?? 0,
      avatarUrl: json['driverAvatar'] as String? ?? json['avatarUrl'] as String?,
      vehicleMake: vehicle['make'] as String? ?? json['vehicleMake'] as String? ?? '',
      vehicleModel: vehicle['model'] as String? ?? json['vehicleModel'] as String? ?? '',
      vehicleColor: vehicle['color'] as String? ?? json['vehicleColor'] as String? ?? '',
      plateNumber: vehicle['plateNumber'] as String? ?? json['plateNumber'] as String? ?? '',
      vehicleType: vehicle['type'] as String? ?? json['vehicleType'] as String? ?? 'Car Go',
      memberSince: json['memberSince'] as String?,
    );
  }
}
