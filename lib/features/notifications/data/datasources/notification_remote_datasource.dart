import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/notification_item.dart';

class NotificationRemoteDatasource {
  final Dio _dio;

  NotificationRemoteDatasource(this._dio);

  Future<List<NotificationItem>> getNotifications({
    String? type,
    bool? read,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (type != null) queryParams['type'] = type;
    if (read != null) queryParams['read'] = read;

    final response = await _dio.get(
      ApiConstants.notifications,
      queryParameters: queryParams,
    );
    final list = response.data['data'] as List<dynamic>;
    return list
        .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> getUnreadCount() async {
    final response = await _dio.get(ApiConstants.notificationsUnreadCount);
    return response.data['count'] as int;
  }

  Future<void> markAsRead({List<String>? notificationIds, bool? all}) async {
    final data = <String, dynamic>{};
    if (notificationIds != null) data['notificationIds'] = notificationIds;
    if (all == true) data['read'] = true;
    await _dio.patch(ApiConstants.notificationsMarkRead, data: data);
  }

  Future<NotificationPreference> getPreferences() async {
    final response = await _dio.get(ApiConstants.notificationPreferences);
    return NotificationPreference.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<void> updatePreferences(NotificationPreference prefs) async {
    await _dio.patch(
      ApiConstants.notificationPreferences,
      data: prefs.toJson(),
    );
  }
}
