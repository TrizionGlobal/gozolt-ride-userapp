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

  Future<String> createSetupIntent() async {
    final response = await _dio.post(ApiConstants.paymentSetupIntent);
    return (response.data as Map<String, dynamic>)['clientSecret'] as String;
  }

  Future<void> deletePaymentMethod(String id) async {
    await _dio.delete('${ApiConstants.paymentMethods}/$id');
  }
}
