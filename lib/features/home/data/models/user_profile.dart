import 'dart:convert';

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
  final List<Map<String, dynamic>>? emergencyContacts;

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
    this.emergencyContacts,
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
      emergencyContacts: _parseEmergencyContacts(json['emergencyContacts']),
    );
  }

  static List<Map<String, dynamic>>? _parseEmergencyContacts(dynamic data) {
    if (data == null) return null;
    try {
      if (data is List) {
        final result = <Map<String, dynamic>>[];
        for (final item in data) {
          if (item is Map) {
            final name = item['name']?.toString().trim() ?? '';
            final phone = item['phone']?.toString().trim() ?? '';
            if (name.isNotEmpty || phone.isNotEmpty) {
              result.add(Map<String, dynamic>.from(item));
            }
          } else if (item is List && item.isNotEmpty && item.first is Map) {
            // Handle accidental nested array: [[{"name": "...", "phone": "..."}]]
            for (final nested in item) {
              if (nested is Map) {
                final name = nested['name']?.toString().trim() ?? '';
                final phone = nested['phone']?.toString().trim() ?? '';
                if (name.isNotEmpty || phone.isNotEmpty) {
                  result.add(Map<String, dynamic>.from(nested));
                }
              }
            }
          }
        }
        return result.isNotEmpty ? result : null;
      } else if (data is String) {
        // If it got stringified somehow
        final parsed = jsonDecode(data);
        return _parseEmergencyContacts(parsed);
      }
    } catch (e) {
      // Return null rather than failing the whole profile fetch
      return null;
    }
    return null;
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
