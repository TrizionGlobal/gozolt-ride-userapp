import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import '../storage/secure_storage_service.dart';
import 'api_interceptor.dart';

Dio createDioClient(
  SecureStorageService storage, {
  void Function()? onUnauthorized,
}) {
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
    ApiInterceptor(
      storage: storage,
      dio: dio,
      onUnauthorized: onUnauthorized,
    ),
  );

  // Logging in debug mode
  assert(() {
    dio.interceptors.add(CompactLogInterceptor());
    return true;
  }());

  return dio;
}

class CompactLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('[DIO] ➔ ${options.method} ${options.path}');
    if (options.data != null) {
      print('[DIO]   Request Data: ${options.data}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('[DIO] ✔ ${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('[DIO] ✘ ${err.response?.statusCode ?? "Error"} ${err.requestOptions.method} ${err.requestOptions.path}');
    if (err.message != null) {
      print('[DIO]   Message: ${err.message}');
    }
    if (err.response?.data != null) {
      print('[DIO]   Response: ${err.response?.data}');
    }
    handler.next(err);
  }
}
