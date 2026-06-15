class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final bool isNewUser;
  final bool phoneLinkRequired;

  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.isNewUser,
    this.phoneLinkRequired = false,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      isNewUser: json['isNewUser'] as bool? ?? false,
      phoneLinkRequired: json['phoneLinkRequired'] as bool? ?? false,
    );
  }
}
