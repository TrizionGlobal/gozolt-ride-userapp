import 'package:flutter_riverpod/flutter_riverpod.dart';

enum GrocerySubstitutionChoice {
  undecided,
  replacement,
  refund,
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
      imageUrl: imageUrl,
      suggestedImageUrl: suggestedImageUrl,
      choice: choice ?? this.choice,
    );
  }
}

class FoodGrocerySubstitutionState {
  const FoodGrocerySubstitutionState({
    this.items = const [],
    this.isSubmitting = false,
    this.isSubmitted = false,
    this.errorMessage,
  });

  final List<GroceryUnavailableItem> items;
  final bool isSubmitting;
  final bool isSubmitted;
  final String? errorMessage;

  bool get hasUnavailableItems {
    return items.isNotEmpty;
  }

  bool get allDecisionsCompleted {
    return items.isNotEmpty &&
        items.every(
          (item) => item.choice != GrocerySubstitutionChoice.undecided,
        );
  }

  double get replacementDifference {
    return items.fold<double>(
      0,
      (total, item) {
        if (item.choice != GrocerySubstitutionChoice.replacement) {
          return total;
        }

        return total + item.priceDifference;
      },
    );
  }

  FoodGrocerySubstitutionState copyWith({
    List<GroceryUnavailableItem>? items,
    bool? isSubmitting,
    bool? isSubmitted,
    String? errorMessage,
    bool clearError = false,
  }) {
    return FoodGrocerySubstitutionState(
      items: items ?? this.items,
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
          const FoodGrocerySubstitutionState(
            items: [
              GroceryUnavailableItem(
                id: 'demo-unavailable-1',
                name: 'Fresh Whole Milk 1L',
                originalPrice: 1.65,
                quantity: 1,
                suggestedName: 'Semi-Skimmed Milk 1L',
                suggestedPrice: 1.75,
                suggestedDescription: 'Similar size and same brand.',
              ),
            ],
          ),
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

    state = state.copyWith(
      isSubmitting: true,
      isSubmitted: false,
      clearError: true,
    );

    try {
      // TODO(FOOD_GROCERY_API):
      // Send the customer substitution decisions to the
      // Food & Grocery order API.
      await Future<void>.delayed(
        const Duration(milliseconds: 900),
      );

      state = state.copyWith(
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

  void loadTemporaryUnavailableItem() {
    state = const FoodGrocerySubstitutionState(
      items: [
        GroceryUnavailableItem(
          id: 'demo-unavailable-1',
          name: 'Fresh Whole Milk 1L',
          originalPrice: 1.65,
          quantity: 1,
          suggestedName: 'Semi-Skimmed Milk 1L',
          suggestedPrice: 1.75,
          suggestedDescription: 'Similar size and same brand.',
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
