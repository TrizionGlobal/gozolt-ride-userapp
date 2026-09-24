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

  final Map<String, String> _uploadCache = {};

  Future<List<String>> uploadImages(List<String> imagePaths) async {
    try {
      final List<String> pathsToUpload = [];
      final List<String> finalUrls = List.filled(imagePaths.length, '');

      for (int i = 0; i < imagePaths.length; i++) {
        final path = imagePaths[i];
        if (_uploadCache.containsKey(path)) {
          finalUrls[i] = _uploadCache[path]!;
        } else {
          pathsToUpload.add(path);
        }
      }

      if (pathsToUpload.isNotEmpty) {
        final uploaded = await _repository.uploadImages(pathsToUpload);
        int uploadedIdx = 0;
        for (int i = 0; i < imagePaths.length; i++) {
          final path = imagePaths[i];
          if (!_uploadCache.containsKey(path)) {
            finalUrls[i] = uploaded[uploadedIdx];
            _uploadCache[path] = uploaded[uploadedIdx];
            uploadedIdx++;
          }
        }
      }

      return finalUrls;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final quickServicesHistoryProvider = FutureProvider.autoDispose<List<QuickServiceHistoryModel>>((ref) async {
  final repository = ref.watch(quickServicesRepositoryProvider);
  return repository.getQuickServiceHistory();
});
