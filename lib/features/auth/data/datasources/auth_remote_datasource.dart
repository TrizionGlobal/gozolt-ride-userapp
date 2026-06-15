import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_exception.dart';
import '../models/auth_response.dart';
import '../models/complete_profile_request.dart';

class AuthRemoteDatasource {
  final Dio _dio;

  AuthRemoteDatasource(this._dio);

  /// Check if a phone number is already registered.
  Future<Map<String, dynamic>> checkPhone(String phone) async {
    try {
      final response = await _dio.post(
        ApiConstants.checkPhone,
        data: {'phone': phone},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// Send OTP to the given phone number.
  Future<void> sendOtp(String phone, {String? fcmToken, bool? isRegister}) async {
    try {
      await _dio.post(
        ApiConstants.sendOtp,
        data: {
          'phone': phone,
          if (fcmToken != null) 'fcmToken': fcmToken,
          if (isRegister != null) 'isRegister': isRegister,
        },
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// Verify OTP and receive tokens.
  Future<AuthResponse> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.verifyOtp,
        data: {'phone': phone, 'otp': otp},
      );
      return AuthResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// Social login (Google / Apple).
  Future<AuthResponse> socialLogin({
    required String provider,
    required String idToken,
    String? firstName,
    String? lastName,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.socialLogin,
        data: {
          'provider': provider,
          'idToken': idToken,
          if (firstName != null) 'firstName': firstName,
          if (lastName != null) 'lastName': lastName,
        },
      );
      return AuthResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// Send OTP to link phone to social account.
  Future<void> linkPhone(String phone) async {
    try {
      await _dio.post(
        ApiConstants.linkPhone,
        data: {'phone': phone},
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// Verify OTP and link phone number.
  Future<void> verifyLinkPhone({
    required String phone,
    required String otp,
  }) async {
    try {
      await _dio.post(
        ApiConstants.verifyLinkPhone,
        data: {'phone': phone, 'otp': otp},
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// Complete profile for new users.
  Future<void> completeProfile(CompleteProfileRequest request) async {
    try {
      await _dio.post(
        ApiConstants.completeProfile,
        data: request.toJson(),
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// Check user profile (used on splash to determine if profile is complete).
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await _dio.get(ApiConstants.userProfile);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// Logout — invalidate refresh token on backend.
  Future<void> logout() async {
    try {
      await _dio.post(ApiConstants.logout);
    } on DioException catch (_) {
      // Silently fail — we clear tokens locally regardless.
    }
  }

  ApiException _mapDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const ApiException(
        message: 'Connection timed out. Please try again.',
        type: ApiErrorType.timeout,
      );
    }

    if (e.type == DioExceptionType.connectionError) {
      return const ApiException(
        message: 'Please check your internet connection.',
        type: ApiErrorType.network,
      );
    }

    final statusCode = e.response?.statusCode;
    final data = e.response?.data;
    String? serverMessage;
    if (data is Map<String, dynamic>) {
      serverMessage = data['message'] as String?;
    }

    if (statusCode == 429) {
      return const ApiException(
        message: 'Too many attempts. Please try again later.',
        statusCode: 429,
        type: ApiErrorType.badRequest,
      );
    }

    return ApiException.fromStatusCode(statusCode, serverMessage);
  }
}
