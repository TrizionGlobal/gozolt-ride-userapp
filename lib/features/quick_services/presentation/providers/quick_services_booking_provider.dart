import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/dio_provider.dart';
import '../../data/models/quick_service_booking_data.dart';
import '../../data/models/quick_service_history_model.dart';
import '../../data/repositories/quick_services_repository.dart';

final quickServicesRepositoryProvider = Provider<QuickServicesRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final repo = QuickServicesRepository(dio);
  repo.fetchPricingRules();
  return repo;
});

final quickServicesBookingProvider = StateNotifierProvider<QuickServicesBookingNotifier, AsyncValue<String?>>((ref) {
  return QuickServicesBookingNotifier(ref.watch(quickServicesRepositoryProvider), ref);
});

class QuickServicesBookingNotifier extends StateNotifier<AsyncValue<String?>> {
  final QuickServicesRepository _repository;
  final Ref _ref;

  QuickServicesBookingNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<String?> bookQuickService(QuickServiceBookingData data) async {
    state = const AsyncValue.loading();
    try {
      final bookingId = await _repository.bookQuickService(data);
      _ref.invalidate(quickServicesHistoryProvider);
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

class QuickServicesHistoryState {
  final List<QuickServiceHistoryModel> bookings;
  final bool isLoading;
  final bool hasMore;
  final int page;
  final String selectedFilter;
  final String? error;

  const QuickServicesHistoryState({
    this.bookings = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.page = 1,
    this.selectedFilter = 'All',
    this.error,
  });

  QuickServicesHistoryState copyWith({
    List<QuickServiceHistoryModel>? bookings,
    bool? isLoading,
    bool? hasMore,
    int? page,
    String? selectedFilter,
    String? error,
  }) {
    return QuickServicesHistoryState(
      bookings: bookings ?? this.bookings,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      error: error,
    );
  }
}

class QuickServicesHistoryNotifier extends StateNotifier<QuickServicesHistoryState> {
  final QuickServicesRepository _repo;

  QuickServicesHistoryNotifier(this._repo) : super(const QuickServicesHistoryState()) {
    load();
  }

  void setFilter(String filter) {
    if (state.selectedFilter == filter) return;
    load(filter: filter);
  }

  Future<void> load({String? filter}) async {
    final activeFilter = filter ?? state.selectedFilter;
    state = state.copyWith(isLoading: true, error: null, selectedFilter: activeFilter, page: 1, hasMore: true);
    try {
      final items = await _repo.getQuickServiceHistory(
        page: 1,
        limit: 10,
        status: activeFilter,
      );
      if (mounted) {
        state = QuickServicesHistoryState(
          bookings: items,
          isLoading: false,
          hasMore: items.length >= 10,
          page: 1,
          selectedFilter: activeFilter,
        );
      }
    } catch (e) {
      if (mounted) {
        state = QuickServicesHistoryState(
          bookings: const [],
          isLoading: false,
          hasMore: false,
          page: 1,
          selectedFilter: activeFilter,
          error: e.toString(),
        );
      }
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    try {
      final nextPage = state.page + 1;
      final items = await _repo.getQuickServiceHistory(
        page: nextPage,
        limit: 10,
        status: state.selectedFilter,
      );
      if (mounted) {
        state = state.copyWith(
          bookings: [...state.bookings, ...items],
          isLoading: false,
          hasMore: items.length >= 10,
          page: nextPage,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }
}

final quickServicesHistoryProvider =
    StateNotifierProvider<QuickServicesHistoryNotifier, QuickServicesHistoryState>((ref) {
  final repository = ref.watch(quickServicesRepositoryProvider);
  return QuickServicesHistoryNotifier(repository);
});
