import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/user_address.dart';
import '../models/user_profile.dart';

class HomeRemoteDatasource {
  final Dio _dio;

  HomeRemoteDatasource(this._dio);

  Future<UserProfile> getUserProfile() async {
    try {
      final response = await _dio.get(ApiConstants.userProfile);
      return UserProfile.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      // 401 is handled by ApiInterceptor (refresh + redirect to login).
      // For any other error, rethrow so the UI can show a retry option.
      rethrow;
    }
  }

  Future<List<UserAddress>> getUserAddresses() async {
    final response = await _dio.get(ApiConstants.userAddresses);
    final list = response.data as List<dynamic>;
    return list
        .map((e) => UserAddress.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> getUnreadNotificationCount() async {
    final response = await _dio.get(ApiConstants.notificationsUnreadCount);
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data['count'] as int? ?? 0;
    }
    return 0;
  }
}
