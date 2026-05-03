import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dio_client.dart';
import 'storage_provider.dart';

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.read(secureStorageProvider);
  return createDioClient(storage);
});
