import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/ride_history_item.dart';

class HistoryRemoteDatasource {
  final Dio _dio;

  HistoryRemoteDatasource(this._dio);

  Future<List<RideHistoryItem>> getRideHistory({
    String? status,
    int page = 1,
    int limit = 10,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (status != null) queryParams['status'] = status;

    final response = await _dio.get(
      ApiConstants.rideHistory,
      queryParameters: queryParams,
    );

    final data = response.data;
    List<dynamic> list;
    if (data is Map<String, dynamic>) {
      list = data['data'] as List<dynamic>? ?? [];
    } else if (data is List) {
      list = data;
    } else {
      list = [];
    }

    return list
        .map((e) => RideHistoryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RideHistoryItem> getRideDetail(String rideId) async {
    final response = await _dio.get(ApiConstants.rideById(rideId));
    return RideHistoryItem.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> cancelRide(String rideId, String reason) async {
    await _dio.post(
      ApiConstants.rideCancel(rideId),
      data: {'reason': reason},
    );
  }

  Future<void> rescheduleRide(String rideId, DateTime newTime) async {
    await _dio.patch(
      ApiConstants.rideReschedule(rideId),
      data: {'newScheduledAt': newTime.toUtc().toIso8601String()},
    );
  }


  Future<Map<String, dynamic>> getPaymentDetails(String rideId) async {
    final response = await _dio.get(ApiConstants.paymentByRide(rideId));
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getInvoice(String rideId) async {
    final response = await _dio.get(ApiConstants.rideInvoice(rideId));
    return response.data as Map<String, dynamic>;
  }
}
