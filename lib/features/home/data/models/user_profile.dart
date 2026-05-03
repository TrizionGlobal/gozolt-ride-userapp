class UserProfile {
  final String id;
  final String? phone;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? avatarUrl;
  final String? city;
  final String? country;
  final String? referralCode;
  final String? status;
  final String? ridePin;

  const UserProfile({
    required this.id,
    this.phone,
    this.email,
    this.firstName,
    this.lastName,
    this.avatarUrl,
    this.city,
    this.country,
    this.referralCode,
    this.status,
    this.ridePin,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      referralCode: json['referralCode'] as String?,
      status: json['status'] as String?,
      ridePin: json['ridePin'] as String?,
    );
  }

  String get displayName {
    if (firstName != null && firstName!.isNotEmpty) {
      return firstName!;
    }
    return 'User';
  }

  String get initials {
    final first = (firstName ?? '').isNotEmpty ? firstName![0] : '';
    final last = (lastName ?? '').isNotEmpty ? lastName![0] : '';
    if (first.isEmpty && last.isEmpty) return 'U';
    return '$first$last'.toUpperCase();
  }
}
