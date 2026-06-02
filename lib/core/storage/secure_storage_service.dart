import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'storage_keys.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
          webOptions: WebOptions(
            dbName: 'gozolt_db',
            publicKey: 'gozolt_key',
          ),
        );

  // ── Tokens ─────────────────────────────────────────────
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: StorageKeys.accessToken, value: accessToken);
    await _storage.write(key: StorageKeys.refreshToken, value: refreshToken);
  }

  Future<String?> getAccessToken() =>
      _storage.read(key: StorageKeys.accessToken);

  Future<String?> getRefreshToken() =>
      _storage.read(key: StorageKeys.refreshToken);

  Future<void> clearTokens() async {
    await _storage.delete(key: StorageKeys.accessToken);
    await _storage.delete(key: StorageKeys.refreshToken);
  }

  Future<bool> hasTokens() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // ── Onboarding ─────────────────────────────────────────
  Future<void> setOnboardingSeen() =>
      _storage.write(key: StorageKeys.hasSeenOnboarding, value: 'true');

  Future<bool> hasSeenOnboarding() async {
    final value = await _storage.read(key: StorageKeys.hasSeenOnboarding);
    return value == 'true';
  }

  // ── Theme ──────────────────────────────────────────────
  Future<void> saveThemeMode(String mode) =>
      _storage.write(key: StorageKeys.themeMode, value: mode);

  Future<String?> getThemeMode() =>
      _storage.read(key: StorageKeys.themeMode);

  // ── Language ───────────────────────────────────────────
  Future<void> saveLanguage(String lang) =>
      _storage.write(key: StorageKeys.language, value: lang);

  Future<String?> getLanguage() =>
      _storage.read(key: StorageKeys.language);

  // ── OTP Session ─────────────────────────────────────────
  Future<void> saveOtpSession({
    required String verificationId,
    required String phone,
  }) async {
    await _storage.write(key: StorageKeys.verificationId, value: verificationId);
    await _storage.write(key: StorageKeys.pendingPhone, value: phone);
  }

  Future<String?> getVerificationId() =>
      _storage.read(key: StorageKeys.verificationId);

  Future<String?> getPendingPhone() =>
      _storage.read(key: StorageKeys.pendingPhone);

  Future<void> clearOtpSession() async {
    await _storage.delete(key: StorageKeys.verificationId);
    await _storage.delete(key: StorageKeys.pendingPhone);
  }

  // ── Clear All ──────────────────────────────────────────
  Future<void> clearAll() => _storage.deleteAll();
}
