class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final bool isNewUser;

  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.isNewUser,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      isNewUser: json['isNewUser'] as bool? ?? false,
    );
  }
}
