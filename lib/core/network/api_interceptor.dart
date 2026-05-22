import 'dart:developer' as dev;

import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import '../storage/secure_storage_service.dart';
import 'api_exception.dart';

class ApiInterceptor extends Interceptor {
  final SecureStorageService _storage;
  final Dio _dio;
  final void Function()? _onUnauthorized;

  /// Endpoints that don't need an auth header.
  static const _publicPaths = {
    ApiConstants.sendOtp,
    ApiConstants.verifyOtp,
    ApiConstants.socialLogin,
    ApiConstants.refreshToken,
  };

  ApiInterceptor({
    required SecureStorageService storage,
    required Dio dio,
    void Function()? onUnauthorized,
  })  : _storage = storage,
        _dio = dio,
        _onUnauthorized = onUnauthorized;

  // ── Attach Bearer token ────────────────────────────────
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final path = options.path;
    final isPublic = _publicPaths.any((p) => path.endsWith(p));

    if (!isPublic) {
      String? token = await _storage.getAccessToken();

      // Dev bypass: use hardcoded token when no real token exists
      if (token == null && AppConstants.kDevBypass) {
        token = AppConstants.kDevAccessToken;
      }

      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    handler.next(options);
  }

  // ── Handle errors with typed exceptions ────────────────
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;

    // Log error (without sensitive data)
    dev.log(
      'API Error: ${err.requestOptions.method} ${err.requestOptions.path} -> $statusCode',
      name: 'ApiInterceptor',
    );

    // 401: attempt token refresh
    if (statusCode == 401) {
      final path = err.requestOptions.path;
      final isPublic = _publicPaths.any((p) => path.endsWith(p));
      if (!isPublic) {
        final refreshed = await _attemptTokenRefresh();
        if (refreshed) {
          final token = await _storage.getAccessToken();
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer $token';

          try {
            final response = await _dio.fetch(options);
            return handler.resolve(response);
          } on DioException catch (e) {
            return handler.next(e);
          }
        } else {
          await _storage.clearTokens();
          _onUnauthorized?.call();
        }
      }
    }

    // Convert DioException to typed ApiException and propagate
    final apiException = ApiException.fromDioException(err);
    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: apiException,
      ),
    );
  }

  Future<bool> _attemptTokenRefresh() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final freshDio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
      final response = await freshDio.post(
        ApiConstants.refreshToken,
        data: {'refreshToken': refreshToken},
      );

      final newAccess = response.data['accessToken'] as String?;
      final newRefresh = response.data['refreshToken'] as String?;

      if (newAccess != null && newRefresh != null) {
        await _storage.saveTokens(
          accessToken: newAccess,
          refreshToken: newRefresh,
        );
        return true;
      }
    } catch (e) {
      dev.log('Token refresh failed: $e', name: 'ApiInterceptor');
    }
    return false;
  }
}
