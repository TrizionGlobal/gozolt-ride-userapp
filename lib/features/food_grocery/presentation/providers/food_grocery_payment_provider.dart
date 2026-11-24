import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ride/data/models/saved_payment_method.dart';

class FoodGroceryPaymentState {
  const FoodGroceryPaymentState({
    this.paymentMethodType = PaymentMethodType.cash,
    this.cardId,
    this.cardDisplayName,
    this.cardBrand,
    this.isOnline = false,
  });

  final PaymentMethodType paymentMethodType;
  final String? cardId;
  final String? cardDisplayName;
  final CardBrand? cardBrand;
  final bool isOnline;

  bool get isCash => paymentMethodType == PaymentMethodType.cash && !isOnline;

  bool get isCard => paymentMethodType == PaymentMethodType.card && !isOnline;

  bool get hasValidSelection {
    if (isCash || isOnline) {
      return true;
    }

    return cardId != null && cardId!.trim().isNotEmpty;
  }

  FoodGroceryPaymentState copyWith({
    PaymentMethodType? paymentMethodType,
    String? cardId,
    String? cardDisplayName,
    CardBrand? cardBrand,
    bool? isOnline,
    bool clearCardId = false,
  }) {
    return FoodGroceryPaymentState(
      paymentMethodType: paymentMethodType ?? this.paymentMethodType,
      cardId: clearCardId ? null : cardId ?? this.cardId,
      cardDisplayName: clearCardId ? null : cardDisplayName ?? this.cardDisplayName,
      cardBrand: clearCardId ? null : cardBrand ?? this.cardBrand,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

class FoodGroceryPaymentNotifier
    extends StateNotifier<FoodGroceryPaymentState> {
  FoodGroceryPaymentNotifier() : super(const FoodGroceryPaymentState());

  void selectPaymentMethod(
    PaymentMethodType type, {
    String? cardId,
    String? cardDisplayName,
    CardBrand? cardBrand,
    bool isOnline = false,
  }) {
    state = FoodGroceryPaymentState(
      paymentMethodType: type,
      cardId: type == PaymentMethodType.card ? cardId : null,
      cardDisplayName: type == PaymentMethodType.card
          ? (cardDisplayName ?? (isOnline ? 'Online Payment (Stripe)' : null))
          : null,
      cardBrand:
          (type == PaymentMethodType.card && !isOnline) ? cardBrand : null,
      isOnline: isOnline,
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
