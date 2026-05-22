import '../../../../core/storage/secure_storage_service.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_response.dart';
import '../models/complete_profile_request.dart';

class AuthRepository {
  final AuthRemoteDatasource _remote;
  final SecureStorageService _storage;

  AuthRepository({
    required AuthRemoteDatasource remote,
    required SecureStorageService storage,
  })  : _remote = remote,
        _storage = storage;

  Future<Map<String, dynamic>> checkPhone(String phone) => _remote.checkPhone(phone);
  
  Future<void> saveOtpSession({required String verificationId, required String phone}) =>
      _storage.saveOtpSession(verificationId: verificationId, phone: phone);

  Future<String?> getVerificationId() => _storage.getVerificationId();

  Future<String?> getPendingPhone() => _storage.getPendingPhone();

  Future<void> clearOtpSession() => _storage.clearOtpSession();

  Future<void> sendOtp(String phone, {String? fcmToken, bool? isRegister}) =>
      _remote.sendOtp(phone, fcmToken: fcmToken, isRegister: isRegister);

  Future<AuthResponse> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    final response = await _remote.verifyOtp(phone: phone, otp: otp);
    await _storage.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );
    return response;
  }

  Future<AuthResponse> socialLogin({
    required String provider,
    required String idToken,
    String? firstName,
    String? lastName,
  }) async {
    final response = await _remote.socialLogin(
      provider: provider,
      idToken: idToken,
      firstName: firstName,
      lastName: lastName,
    );
    await _storage.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );
    return response;
  }

  Future<void> completeProfile(CompleteProfileRequest request) =>
      _remote.completeProfile(request);

  Future<void> logout() async {
    await _remote.logout();
    await _storage.clearAll();
  }

  Future<bool> hasTokens() => _storage.hasTokens();
}
