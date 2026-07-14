import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/fare_estimate.dart';
import '../models/promo_validation.dart';
import '../models/ride.dart';
import '../models/vehicle_type.dart';

class RideRemoteDatasource {
  final Dio _dio;

  RideRemoteDatasource(this._dio);

  Future<Map<VehicleType, FareEstimate>> estimateFare({
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    String? vehicleType,
    List<Map<String, dynamic>>? stops,
  }) async {
    final body = <String, dynamic>{
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'dropoffLat': dropoffLat,
      'dropoffLng': dropoffLng,
    };
    if (vehicleType != null && vehicleType.isNotEmpty) {
      body['vehicleType'] = vehicleType;
    }
    if (stops != null && stops.isNotEmpty) body['stops'] = stops;

    final response = await _dio.post(ApiConstants.rideEstimate, data: body);
    
    final Map<VehicleType, FareEstimate> estimates = {};
    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      data.forEach((key, value) {
        try {
          final type = VehicleType.fromApi(key);
          estimates[type] = FareEstimate.fromJson(value as Map<String, dynamic>);
        } catch (_) {}
      });
    }
    return estimates;
  }

  Future<Ride> createRide(Map<String, dynamic> data) async {
    final response = await _dio.post(ApiConstants.rides, data: data);
    return Ride.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> cancelRide(String rideId, String reason) async {
    await _dio.post(
      ApiConstants.rideCancel(rideId),
      data: {'reason': reason},
    );
  }

  Future<Ride?> getActiveRide() async {
    try {
      final response = await _dio.get(ApiConstants.activeRide);
      return Ride.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<PromoValidation> validatePromo({
    required String code,
    required double rideFare,
  }) async {
    final response = await _dio.post(
      ApiConstants.promoValidate,
      data: {'code': code, 'rideFare': rideFare},
    );
    return PromoValidation.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Ride> getRide(String rideId) async {
    final response = await _dio.get(ApiConstants.rideById(rideId));
    return Ride.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>?> getRideById(String rideId) async {
    try {
      final response = await _dio.get(ApiConstants.rideById(rideId));
      return response.data as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> confirmRidePayment(String rideId) async {
    await _dio.post(ApiConstants.paymentConfirmRide(rideId));
  }

  Future<Map<String, dynamic>> shareRide(String rideId) async {
    final response = await _dio.post(ApiConstants.rideShare(rideId));
    return response.data as Map<String, dynamic>;
  }

  Future<void> triggerSos(String rideId, double lat, double lng) async {
    await _dio.post(
      ApiConstants.rideSos(rideId),
      data: {'latitude': lat, 'longitude': lng},
    );
  }

  Future<void> rateRide(String rideId, int rating, {String? comment}) async {
    final data = <String, dynamic>{'rating': rating};
    if (comment != null && comment.isNotEmpty) data['comment'] = comment;
    await _dio.post(ApiConstants.rideRate(rideId), data: data);
  }

  Future<List<dynamic>> getRideMessages(String rideId) async {
    final response = await _dio.get(ApiConstants.rideMessages(rideId));
    return response.data as List<dynamic>;
  }

  Future<void> sendRideMessage(String rideId, String content) async {
    await _dio.post(
      ApiConstants.rideMessages(rideId),
      data: {'content': content},
    );
  }

  Future<void> addTip(String rideId, double amount) async {
    await _dio.post(
      ApiConstants.rideTip(rideId),
      data: {'amount': amount},
    );
  }

  Future<void> rescheduleRide(String rideId, DateTime scheduledAt) async {
    await _dio.patch(
      ApiConstants.rideReschedule(rideId),
      data: {'scheduledAt': scheduledAt.toUtc().toIso8601String()},
    );
  }

  Future<Map<String, dynamic>> changeDestination(
    String rideId, {
    required double newDropoffLat,
    required double newDropoffLng,
    required String newDropoffAddress,
  }) async {
    final response = await _dio.post(
      ApiConstants.rideChangeDestination(rideId),
      data: {
        'newDropoffLat': newDropoffLat,
        'newDropoffLng': newDropoffLng,
        'newDropoffAddress': newDropoffAddress,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> cancelDestinationChange(String rideId) async {
    await _dio.delete(ApiConstants.rideChangeDestination(rideId));
  }

  Future<void> addExtraFare(String rideId, double amount) async {
    await _dio.post(
      ApiConstants.rideExtraFare(rideId),
      data: {'amount': amount},
    );
  }
}
