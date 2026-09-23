import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/dio_provider.dart';
import '../../data/models/quick_service_booking_data.dart';
import '../../data/models/quick_service_history_model.dart';
import '../../data/repositories/quick_services_repository.dart';

final quickServicesRepositoryProvider = Provider<QuickServicesRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return QuickServicesRepository(dio);
});

final quickServicesBookingProvider = StateNotifierProvider<QuickServicesBookingNotifier, AsyncValue<String?>>((ref) {
  return QuickServicesBookingNotifier(ref.watch(quickServicesRepositoryProvider));
});

class QuickServicesBookingNotifier extends StateNotifier<AsyncValue<String?>> {
  final QuickServicesRepository _repository;

  QuickServicesBookingNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<String?> bookQuickService(QuickServiceBookingData data) async {
    state = const AsyncValue.loading();
    try {
      final bookingId = await _repository.bookQuickService(data);
      state = AsyncValue.data(bookingId);
      return bookingId;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<List<String>> uploadImages(List<String> imagePaths) async {
    try {
      return await _repository.uploadImages(imagePaths);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return [];
    }
  }
}

final quickServicesHistoryProvider = FutureProvider.autoDispose<List<QuickServiceHistoryModel>>((ref) async {
  final repository = ref.watch(quickServicesRepositoryProvider);
  return repository.getQuickServiceHistory();
});
