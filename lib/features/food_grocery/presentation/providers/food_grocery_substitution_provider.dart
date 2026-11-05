import 'package:flutter_riverpod/flutter_riverpod.dart';

enum GrocerySubstitutionChoice {
  undecided,
  replacement,
  anotherReplacement,
  refund,
}

enum FoodGrocerySubstitutionProgress {
  waitingForDecision,
  additionalPaymentRequired,
  processingPayment,
  refundInitiated,
  confirmed,
  cancelled,
}

class GroceryUnavailableItem {
  const GroceryUnavailableItem({
    required this.id,
    required this.name,
    required this.originalPrice,
    required this.quantity,
    required this.suggestedName,
    required this.suggestedPrice,
    required this.suggestedDescription,
    required this.alternativeName,
    required this.alternativePrice,
    required this.alternativeDescription,
    this.imageUrl,
    this.suggestedImageUrl,
    this.choice = GrocerySubstitutionChoice.undecided,
  });

  final String id;
  final String name;
  final double originalPrice;
  final int quantity;
  final String suggestedName;
  final double suggestedPrice;
  final String suggestedDescription;
  final String alternativeName;
  final double alternativePrice;
  final String alternativeDescription;
  final String? imageUrl;
  final String? suggestedImageUrl;
  final GrocerySubstitutionChoice choice;

  double get originalTotal {
    return originalPrice * quantity;
  }

  double get replacementTotal {
    return suggestedPrice * quantity;
  }

  double get priceDifference {
    return replacementTotal - originalTotal;
  }

  GroceryUnavailableItem copyWith({
    GrocerySubstitutionChoice? choice,
  }) {
    return GroceryUnavailableItem(
      id: id,
      name: name,
      originalPrice: originalPrice,
      quantity: quantity,
      suggestedName: suggestedName,
      suggestedPrice: suggestedPrice,
      suggestedDescription: suggestedDescription,
      alternativeName: alternativeName,
      alternativePrice: alternativePrice,
      alternativeDescription: alternativeDescription,
      imageUrl: imageUrl,
      suggestedImageUrl: suggestedImageUrl,
      choice: choice ?? this.choice,
    );
  }
}

class FoodGrocerySubstitutionState {
  const FoodGrocerySubstitutionState({
    this.items = const [],
    this.originalOrderTotal = 13.40,
    this.progress = FoodGrocerySubstitutionProgress.waitingForDecision,
    this.isSubmitting = false,
    this.isSubmitted = false,
    this.errorMessage,
  });

  final List<GroceryUnavailableItem> items;

  // Temporary value for UI testing.
  // TODO(FOOD_GROCERY_API):
  // Replace with the confirmed order total from the backend.
  final double originalOrderTotal;

  final FoodGrocerySubstitutionProgress progress;
  final bool isSubmitting;
  final bool isSubmitted;
  final String? errorMessage;

  bool get hasUnavailableItems => items.isNotEmpty;

  bool get allDecisionsCompleted {
    return items.isNotEmpty &&
        items.every(
          (item) => item.choice != GrocerySubstitutionChoice.undecided,
        );
  }

  double get priceDifference {
    return items.fold<double>(
      0,
      (total, item) {
        switch (item.choice) {
          case GrocerySubstitutionChoice.replacement:
            return total + item.replacementTotal - item.originalTotal;

          case GrocerySubstitutionChoice.anotherReplacement:
            return total +
                (item.alternativePrice * item.quantity) -
                item.originalTotal;

          case GrocerySubstitutionChoice.refund:
            return total - item.originalTotal;

          case GrocerySubstitutionChoice.undecided:
            return total;
        }
      },
    );
  }

  double get additionalPaymentAmount {
    return priceDifference > 0 ? priceDifference : 0;
  }

  double get refundAmount {
    return priceDifference < 0 ? priceDifference.abs() : 0;
  }

  double get updatedOrderTotal {
    final updatedTotal = originalOrderTotal + priceDifference;
    return updatedTotal < 0 ? 0 : updatedTotal;
  }

  bool get requiresAdditionalPayment {
    return additionalPaymentAmount > 0;
  }

  bool get requiresRefund {
    return refundAmount > 0;
  }

  bool get allUnavailableItemsRefunded {
    return items.isNotEmpty &&
        items.every(
          (item) => item.choice == GrocerySubstitutionChoice.refund,
        );
  }

  bool get canContinueFulfilment {
    return progress == FoodGrocerySubstitutionProgress.refundInitiated ||
        progress == FoodGrocerySubstitutionProgress.confirmed;
  }

  FoodGrocerySubstitutionState copyWith({
    List<GroceryUnavailableItem>? items,
    double? originalOrderTotal,
    FoodGrocerySubstitutionProgress? progress,
    bool? isSubmitting,
    bool? isSubmitted,
    String? errorMessage,
    bool clearError = false,
  }) {
    return FoodGrocerySubstitutionState(
      items: items ?? this.items,
      originalOrderTotal: originalOrderTotal ?? this.originalOrderTotal,
      progress: progress ?? this.progress,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class FoodGrocerySubstitutionNotifier
    extends StateNotifier<FoodGrocerySubstitutionState> {
  FoodGrocerySubstitutionNotifier()
      : super(
          const FoodGrocerySubstitutionState(),
        );

  void selectChoice(
    String itemId,
    GrocerySubstitutionChoice choice,
  ) {
    final updatedItems = state.items.map(
      (item) {
        if (item.id != itemId) {
          return item;
        }

        return item.copyWith(
          choice: choice,
        );
      },
    ).toList();

    state = state.copyWith(
      items: updatedItems,
      progress: FoodGrocerySubstitutionProgress.waitingForDecision,
      isSubmitted: false,
      clearError: true,
    );
  }

  Future<void> submitDecisions() async {
    if (state.isSubmitting) {
      return;
    }

    if (!state.allDecisionsCompleted) {
      state = state.copyWith(
        errorMessage:
            'Choose a replacement or refund for every unavailable item.',
      );
      return;
    }

    // A more expensive replacement must not be confirmed
    // until the additional payment succeeds.
    if (state.requiresAdditionalPayment) {
      state = state.copyWith(
        progress: FoodGrocerySubstitutionProgress.additionalPaymentRequired,
        isSubmitting: false,
        isSubmitted: false,
        clearError: true,
      );
      return;
    }

    state = state.copyWith(
      isSubmitting: true,
      isSubmitted: false,
      clearError: true,
    );

    try {
      // TODO(FOOD_GROCERY_API):
      // Submit replacement/refund choices to the backend.
      await Future<void>.delayed(
        const Duration(milliseconds: 900),
      );

      state = state.copyWith(
        progress: state.requiresRefund
            ? FoodGrocerySubstitutionProgress.refundInitiated
            : FoodGrocerySubstitutionProgress.confirmed,
        isSubmitting: false,
        isSubmitted: true,
        clearError: true,
      );
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        isSubmitted: false,
        errorMessage: 'Unable to save your choices. Please try again.',
      );
    }
  }

  Future<void> completeAdditionalPayment() async {
    if (!state.requiresAdditionalPayment || state.isSubmitting) {
      return;
    }

    state = state.copyWith(
      progress: FoodGrocerySubstitutionProgress.processingPayment,
      isSubmitting: true,
      isSubmitted: false,
      clearError: true,
    );

    try {
      // TODO(FOOD_GROCERY_STRIPE):
      // Replace this delay with the real additional-payment API.
      await Future<void>.delayed(
        const Duration(milliseconds: 1200),
      );

      state = state.copyWith(
        progress: FoodGrocerySubstitutionProgress.confirmed,
        isSubmitting: false,
        isSubmitted: true,
        clearError: true,
      );
    } catch (_) {
      state = state.copyWith(
        progress: FoodGrocerySubstitutionProgress.additionalPaymentRequired,
        isSubmitting: false,
        isSubmitted: false,
        errorMessage: 'Additional payment failed. Please try again.',
      );
    }
  }

  void loadTemporaryUnavailableItem({
    double? originalOrderTotal,
  }) {
    state = FoodGrocerySubstitutionState(
      originalOrderTotal: originalOrderTotal ?? state.originalOrderTotal,
      items: const [
        GroceryUnavailableItem(
          id: 'demo-unavailable-1',
          name: 'Fresh Whole Milk 1L',
          originalPrice: 1.65,
          quantity: 1,
          suggestedName: 'Semi-Skimmed Milk 1L',
          suggestedPrice: 1.75,
          suggestedDescription: 'Similar size and same brand.',
          alternativeName: 'Skimmed Milk 1L',
          alternativePrice: 1.45,
          alternativeDescription: 'Lower fat content with similar taste.',
        ),
      ],
    );
  }

  void clear() {
    state = const FoodGrocerySubstitutionState();
  }
}

final foodGrocerySubstitutionProvider = StateNotifierProvider<
    FoodGrocerySubstitutionNotifier, FoodGrocerySubstitutionState>(
  (ref) => FoodGrocerySubstitutionNotifier(),
);
