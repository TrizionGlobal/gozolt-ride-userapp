import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers/dio_provider.dart';
import '../../../../core/providers/storage_provider.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/models/complete_profile_request.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.read(dioProvider);
  final storage = ref.read(secureStorageProvider);
  return AuthRepository(
    remote: AuthRemoteDatasource(dio),
    storage: storage,
  );
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

/// Stores the phone number entered by the user across screens.
final phoneNumberProvider = StateProvider<String>((ref) => '');

/// Stores the selected country dial code.
final selectedDialCodeProvider = StateProvider<String>((ref) => '+356');

/// Tracks whether the user tapped "Login" or "Register" on the welcome screen.
/// true = register flow (show Complete Profile after OTP),
/// false = login flow (go straight to Home after OTP).
final isRegisterFlowProvider = StateProvider<bool>((ref) => false);

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AuthState());

  bool _isRegisterFlow = false;

  bool get isRegisterFlow => _isRegisterFlow;

  Future<void> sendOtp(String phone, {bool isRegister = false}) async {
    _isRegisterFlow = isRegister;
    state = state.copyWith(status: AuthStatus.loading, phone: phone);

    try {
      // Check if phone exists before sending OTP
      final checkResult = await _repo.checkPhone(phone);
      final exists = checkResult['exists'] as bool? ?? false;

      if (isRegister && exists) {
        state = AuthState.errorMessage(
          'This phone number is already registered. Please log in instead.',
        );
        return;
      }

      if (!isRegister && !exists) {
        state = AuthState.errorMessage(
          'This phone number is not registered. Please register first.',
        );
        return;
      }

      // Send OTP via backend (Twilio)
      await _repo.sendOtp(phone);
      
      state = state.copyWith(
        status: AuthStatus.otpSent,
        phone: phone,
      );
    } on ApiException catch (e) {
      state = AuthState.error(e);
    } catch (e) {
      state = AuthState.errorMessage('Failed to send OTP. Please try again.');
    }
  }

  Future<void> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final response = await _repo.verifyOtp(
        phone: phone,
        otp: otp,
      );

      if (response.isNewUser) {
        state = state.copyWith(
          status: AuthStatus.needsProfile,
          isNewUser: true,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          isNewUser: false,
        );
      }
    } on ApiException catch (e) {
      state = AuthState.errorMessage(e.message ?? 'Invalid code. Please try again.');
    } catch (e) {
      state = AuthState.errorMessage('Verification failed. Please try again.');
    }
  }

  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken();

      if (idToken != null) {
        // Clear the saved session as it's no longer needed
        await _repo.clearOtpSession();
        
        // Authenticate with backend using Firebase ID Token
        final response = await _repo.socialLogin(
          provider: 'PHONE',
          idToken: idToken,
        );

        if (response.isNewUser) {
          state = state.copyWith(
            status: AuthStatus.needsProfile,
            isNewUser: true,
          );
        } else {
          state = state.copyWith(
            status: AuthStatus.authenticated,
            isNewUser: false,
          );
        }
      } else {
        state = AuthState.errorMessage('Failed to get verification token.');
      }
    } on FirebaseAuthException catch (e) {
      state = AuthState.errorMessage(e.message ?? 'Authentication failed');
    } on ApiException catch (e) {
      state = AuthState.error(e);
    } catch (e) {
      state = AuthState.errorMessage('Something went wrong. Please try again.');
    }
  }

  Future<void> socialLogin({
    required String provider,
    required String idToken,
    String? firstName,
    String? lastName,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final response = await _repo.socialLogin(
        provider: provider,
        idToken: idToken,
        firstName: firstName,
        lastName: lastName,
      );
      if (response.isNewUser) {
        state = state.copyWith(
          status: AuthStatus.needsProfile,
          isNewUser: true,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          isNewUser: false,
        );
      }
    } on ApiException catch (e) {
      state = AuthState.error(e);
    } catch (_) {
      state = AuthState.errorMessage('Sign in failed. Please try again.');
    }
  }

  Future<void> completeProfile(CompleteProfileRequest request) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _repo.completeProfile(request);
      state = state.copyWith(status: AuthStatus.authenticated);
    } on ApiException catch (e) {
      state = AuthState.error(e);
    } catch (_) {
      state = AuthState.errorMessage('Something went wrong. Please try again.');
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Resend OTP without changing auth status (avoids re-navigation to OTP screen).
  Future<void> resendOtp(String phone) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      await _repo.sendOtp(phone, fcmToken: fcmToken);
    } catch (_) {
      // Silently fail — the user can tap resend again
    }
  }

  void clearError() {
    if (state.status == AuthStatus.error) {
      state = state.copyWith(status: AuthStatus.initial);
    }
  }

  void reset() {
    state = const AuthState();
  }
}
