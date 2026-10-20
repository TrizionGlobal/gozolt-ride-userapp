import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ride/data/models/saved_payment_method.dart';

class FoodGroceryPaymentState {
  const FoodGroceryPaymentState({
    this.paymentMethodType = PaymentMethodType.cash,
    this.cardId,
  });

  final PaymentMethodType paymentMethodType;
  final String? cardId;

  bool get isCash => paymentMethodType == PaymentMethodType.cash;

  bool get isCard => paymentMethodType == PaymentMethodType.card;

  bool get hasValidSelection {
    if (isCash) {
      return true;
    }

    return cardId != null && cardId!.trim().isNotEmpty;
  }

  FoodGroceryPaymentState copyWith({
    PaymentMethodType? paymentMethodType,
    String? cardId,
    bool clearCardId = false,
  }) {
    return FoodGroceryPaymentState(
      paymentMethodType: paymentMethodType ?? this.paymentMethodType,
      cardId: clearCardId ? null : cardId ?? this.cardId,
    );
  }
}

class FoodGroceryPaymentNotifier
    extends StateNotifier<FoodGroceryPaymentState> {
  FoodGroceryPaymentNotifier() : super(const FoodGroceryPaymentState());

  void selectPaymentMethod(
    PaymentMethodType type, {
    String? cardId,
  }) {
    state = FoodGroceryPaymentState(
      paymentMethodType: type,
      cardId: type == PaymentMethodType.card ? cardId : null,
    );
  }

  void reset() {
    state = const FoodGroceryPaymentState();
  }
}

final foodGroceryPaymentProvider =
    StateNotifierProvider<FoodGroceryPaymentNotifier, FoodGroceryPaymentState>(
  (ref) => FoodGroceryPaymentNotifier(),
);
