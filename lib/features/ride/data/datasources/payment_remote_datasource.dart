import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/saved_payment_method.dart';

class PaymentRemoteDatasource {
  final Dio _dio;

  PaymentRemoteDatasource(this._dio);

  Future<List<SavedPaymentMethod>> getPaymentMethods() async {
    final response = await _dio.get(ApiConstants.paymentMethods);
    final list = response.data as List<dynamic>;
    return list
        .map((e) => SavedPaymentMethod.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> createSetupIntent() async {
    final response = await _dio.post(ApiConstants.paymentSetupIntent);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createPaymentSheet(double amount) async {
    final response = await _dio.post(
      ApiConstants.paymentPaymentSheet,
      data: {'amount': amount},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> confirmSetupIntent(String paymentMethodId) async {
    await _dio.post(
      ApiConstants.paymentConfirmSetup,
      data: {'paymentMethodId': paymentMethodId},
    );
  }

  Future<void> checkoutRide({
    required String rideId,
    required String paymentMethod,
    String? paymentMethodId,
  }) async {
    await _dio.post(
      ApiConstants.paymentCheckout(rideId),
      data: {
        'paymentMethod': paymentMethod,
        'paymentMethodId': paymentMethodId,
      },
    );
  }

  Future<void> deletePaymentMethod(String id) async {
    await _dio.delete('${ApiConstants.paymentMethods}/$id');
  }
}
