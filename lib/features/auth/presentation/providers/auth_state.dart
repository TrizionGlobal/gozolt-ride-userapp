import '../../../../core/network/api_exception.dart';

enum AuthStatus {
  initial,
  loading,
  otpSent,
  authenticated,
  needsProfile,
  unauthenticated,
  error,
}

class AuthState {
  final AuthStatus status;
  final String? phone;
  final String? errorMessage;
  final bool isNewUser;

  const AuthState({
    this.status = AuthStatus.initial,
    this.phone,
    this.errorMessage,
    this.isNewUser = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? phone,
    String? errorMessage,
    bool? isNewUser,
  }) {
    return AuthState(
      status: status ?? this.status,
      phone: phone ?? this.phone,
      errorMessage: errorMessage,
      isNewUser: isNewUser ?? this.isNewUser,
    );
  }

  factory AuthState.loading() =>
      const AuthState(status: AuthStatus.loading);

  factory AuthState.error(ApiException e) =>
      AuthState(status: AuthStatus.error, errorMessage: e.message);

  factory AuthState.errorMessage(String msg) =>
      AuthState(status: AuthStatus.error, errorMessage: msg);
}
