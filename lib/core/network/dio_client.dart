import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import '../storage/secure_storage_service.dart';
import 'api_interceptor.dart';

Dio createDioClient(SecureStorageService storage) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    ApiInterceptor(storage: storage, dio: dio),
  );

  // Logging in debug mode
  assert(() {
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
      logPrint: (o) => print('[DIO] $o'), // ignore: avoid_print - debug only
    ));
    return true;
  }());

  return dio;
}
