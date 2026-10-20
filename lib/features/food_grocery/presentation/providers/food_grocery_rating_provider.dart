import 'package:flutter_riverpod/flutter_riverpod.dart';

class FoodGroceryRatingState {
  const FoodGroceryRatingState({
    this.overallRating = 0,
    this.supplierRating = 0,
    this.deliveryRating = 0,
    this.selectedTags = const <String>{},
    this.comment = '',
    this.isSubmitting = false,
    this.isSubmitted = false,
    this.errorMessage,
  });

  final int overallRating;
  final int supplierRating;
  final int deliveryRating;
  final Set<String> selectedTags;
  final String comment;
  final bool isSubmitting;
  final bool isSubmitted;
  final String? errorMessage;

  bool get canSubmit =>
      overallRating > 0 &&
      supplierRating > 0 &&
      deliveryRating > 0 &&
      !isSubmitting;

  FoodGroceryRatingState copyWith({
    int? overallRating,
    int? supplierRating,
    int? deliveryRating,
    Set<String>? selectedTags,
    String? comment,
    bool? isSubmitting,
    bool? isSubmitted,
    String? errorMessage,
    bool clearError = false,
  }) {
    return FoodGroceryRatingState(
      overallRating: overallRating ?? this.overallRating,
      supplierRating: supplierRating ?? this.supplierRating,
      deliveryRating: deliveryRating ?? this.deliveryRating,
      selectedTags: selectedTags ?? this.selectedTags,
      comment: comment ?? this.comment,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class FoodGroceryRatingNotifier extends StateNotifier<FoodGroceryRatingState> {
  FoodGroceryRatingNotifier() : super(const FoodGroceryRatingState());

  void setOverallRating(int rating) {
    state = state.copyWith(
      overallRating: rating,
      clearError: true,
    );
  }

  void setSupplierRating(int rating) {
    state = state.copyWith(
      supplierRating: rating,
      clearError: true,
    );
  }

  void setDeliveryRating(int rating) {
    state = state.copyWith(
      deliveryRating: rating,
      clearError: true,
    );
  }

  void toggleTag(String tag) {
    final updatedTags = Set<String>.from(
      state.selectedTags,
    );

    if (updatedTags.contains(tag)) {
      updatedTags.remove(tag);
    } else {
      updatedTags.add(tag);
    }

    state = state.copyWith(
      selectedTags: updatedTags,
      clearError: true,
    );
  }

  void setComment(String value) {
    state = state.copyWith(
      comment: value,
      clearError: true,
    );
  }

  Future<bool> submitReview({
    required String orderId,
    required String supplierName,
  }) async {
    if (!state.canSubmit) {
      state = state.copyWith(
        errorMessage: 'Please complete all three ratings before submitting.',
      );
      return false;
    }

    state = state.copyWith(
      isSubmitting: true,
      clearError: true,
    );

    try {
      // TODO(FOOD_GROCERY_API):
      // Replace this temporary delay with the Food & Grocery
      // submit-rating API.
      //
      // Send:
      // orderId
      // supplierName
      // overallRating
      // supplierRating
      // deliveryRating
      // selectedTags
      // comment

      await Future<void>.delayed(
        const Duration(milliseconds: 800),
      );

      state = state.copyWith(
        isSubmitting: false,
        isSubmitted: true,
        clearError: true,
      );

      return true;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Unable to submit your review. Please try again.',
      );

      return false;
    }
  }

  void reset() {
    state = const FoodGroceryRatingState();
  }
}

final foodGroceryRatingProvider =
    StateNotifierProvider<FoodGroceryRatingNotifier, FoodGroceryRatingState>(
  (ref) => FoodGroceryRatingNotifier(),
);
