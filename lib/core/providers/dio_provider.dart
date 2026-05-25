import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dio_client.dart';
import 'auth_redirect_provider.dart';
import 'storage_provider.dart';

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.read(secureStorageProvider);
  final redirectNotifier = ref.read(authRedirectProvider);
  return createDioClient(
    storage,
    onUnauthorized: () {
      redirectNotifier.triggerRedirect();
    },
  );
});
