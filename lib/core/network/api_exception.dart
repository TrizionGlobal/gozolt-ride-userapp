import 'package:dio/dio.dart';

enum ApiErrorType {
  network,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  tooManyRequests,
  server,
  badRequest,
  conflict,
  parse,
  unknown,
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final ApiErrorType type;

  const ApiException({
    required this.message,
    this.statusCode,
    this.type = ApiErrorType.unknown,
  });

  /// User-friendly message for display in UI.
  String get userMessage {
    switch (type) {
      case ApiErrorType.network:
        return 'No internet connection. Please check your network and try again.';
      case ApiErrorType.timeout:
        return 'The request timed out. Please try again.';
      case ApiErrorType.unauthorized:
        return 'Your session has expired. Please log in again.';
      case ApiErrorType.forbidden:
        return 'You don\'t have permission to perform this action.';
      case ApiErrorType.notFound:
        return 'The requested resource was not found.';
      case ApiErrorType.tooManyRequests:
        return 'Too many requests. Please wait a moment and try again.';
      case ApiErrorType.server:
        return 'Server error. Please try again later.';
      case ApiErrorType.badRequest:
        return message;
      case ApiErrorType.conflict:
        return message;
      case ApiErrorType.parse:
        return 'Failed to process server response. Please try again.';
      case ApiErrorType.unknown:
        return 'Something went wrong. Please try again.';
    }
  }

  factory ApiException.fromStatusCode(int? statusCode, [String? message]) {
    switch (statusCode) {
      case 400:
        return ApiException(
          message: message ?? 'Invalid request',
          statusCode: statusCode,
          type: ApiErrorType.badRequest,
        );
      case 401:
        return ApiException(
          message: message ?? 'Unauthorized',
          statusCode: statusCode,
          type: ApiErrorType.unauthorized,
        );
      case 403:
        return ApiException(
          message: message ?? 'Forbidden',
          statusCode: statusCode,
          type: ApiErrorType.forbidden,
        );
      case 404:
        return ApiException(
          message: message ?? 'Not found',
          statusCode: statusCode,
          type: ApiErrorType.notFound,
        );
      case 409:
        return ApiException(
          message: message ?? 'Conflict',
          statusCode: statusCode,
          type: ApiErrorType.conflict,
        );
      case 429:
        return ApiException(
          message: message ?? 'Too many requests',
          statusCode: statusCode,
          type: ApiErrorType.tooManyRequests,
        );
      case final code when code != null && code >= 500:
        return ApiException(
          message: message ?? 'Server error. Please try again later.',
          statusCode: statusCode,
          type: ApiErrorType.server,
        );
      default:
        return ApiException(
          message: message ?? 'Something went wrong',
          statusCode: statusCode,
        );
    }
  }

  factory ApiException.fromDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          message: 'Request timed out',
          type: ApiErrorType.timeout,
        );
      case DioExceptionType.connectionError:
        return const ApiException(
          message: 'No internet connection',
          type: ApiErrorType.network,
        );
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;
        String? serverMessage;
        if (data is Map<String, dynamic>) {
          final msg = data['message'];
          if (msg is String) {
            serverMessage = msg;
          } else if (msg is List) {
            serverMessage = msg.join(', ');
          }
          serverMessage ??= data['error'] is String
              ? data['error'] as String
              : null;
        }
        return ApiException.fromStatusCode(statusCode, serverMessage);
      case DioExceptionType.cancel:
        return const ApiException(
          message: 'Request cancelled',
          type: ApiErrorType.unknown,
        );
      default:
        return const ApiException(
          message: 'Something went wrong',
          type: ApiErrorType.unknown,
        );
    }
  }

  @override
  String toString() => 'ApiException($type, $statusCode): $message';
}
