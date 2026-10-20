import 'package:flutter_riverpod/flutter_riverpod.dart';

enum FoodGroceryDeliveryPaymentStatus {
  paidOnline,
  cashDue,
  cashCollected,
}

class FoodGroceryDeliveryVerificationState {
  const FoodGroceryDeliveryVerificationState({
    this.orderId = '',
    this.verificationCode = '4826',
    this.amount = 0,
    this.paymentStatus = FoodGroceryDeliveryPaymentStatus.paidOnline,
    this.isDeliveryPartnerArrived = false,
    this.isOrderReceived = false,
    this.isConfirming = false,
  });

  final String orderId;
  final String verificationCode;
  final double amount;
  final FoodGroceryDeliveryPaymentStatus paymentStatus;
  final bool isDeliveryPartnerArrived;
  final bool isOrderReceived;
  final bool isConfirming;

  bool get isCash =>
      paymentStatus == FoodGroceryDeliveryPaymentStatus.cashDue ||
      paymentStatus == FoodGroceryDeliveryPaymentStatus.cashCollected;

  bool get isPaid =>
      paymentStatus == FoodGroceryDeliveryPaymentStatus.paidOnline ||
      paymentStatus == FoodGroceryDeliveryPaymentStatus.cashCollected;

  FoodGroceryDeliveryVerificationState copyWith({
    String? orderId,
    String? verificationCode,
    double? amount,
    FoodGroceryDeliveryPaymentStatus? paymentStatus,
    bool? isDeliveryPartnerArrived,
    bool? isOrderReceived,
    bool? isConfirming,
  }) {
    return FoodGroceryDeliveryVerificationState(
      orderId: orderId ?? this.orderId,
      verificationCode: verificationCode ?? this.verificationCode,
      amount: amount ?? this.amount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      isDeliveryPartnerArrived:
          isDeliveryPartnerArrived ?? this.isDeliveryPartnerArrived,
      isOrderReceived: isOrderReceived ?? this.isOrderReceived,
      isConfirming: isConfirming ?? this.isConfirming,
    );
  }
}

class FoodGroceryDeliveryVerificationNotifier
    extends StateNotifier<FoodGroceryDeliveryVerificationState> {
  FoodGroceryDeliveryVerificationNotifier()
      : super(
          const FoodGroceryDeliveryVerificationState(),
        );

  void initialiseTemporaryDelivery({
    required String orderId,
    required double amount,
    required bool isCash,
  }) {
    state = FoodGroceryDeliveryVerificationState(
      orderId: orderId,
      verificationCode: '4826',
      amount: amount,
      paymentStatus: isCash
          ? FoodGroceryDeliveryPaymentStatus.cashDue
          : FoodGroceryDeliveryPaymentStatus.paidOnline,
      isDeliveryPartnerArrived: true,
    );
  }

  void markCashCollected() {
    if (!state.isCash) {
      return;
    }

    state = state.copyWith(
      paymentStatus: FoodGroceryDeliveryPaymentStatus.cashCollected,
    );
  }

  Future<void> confirmOrderReceived() async {
    if (state.isConfirming || state.isOrderReceived) {
      return;
    }

    state = state.copyWith(
      isConfirming: true,
    );

    // TODO(FOOD_GROCERY_API):
    // Replace this temporary delay with the delivery
    // verification/order-completion API.
    await Future<void>.delayed(
      const Duration(milliseconds: 700),
    );

    state = state.copyWith(
      isConfirming: false,
      isOrderReceived: true,
    );
  }

  void reset() {
    state = const FoodGroceryDeliveryVerificationState();
  }
}

final foodGroceryDeliveryVerificationProvider = StateNotifierProvider<
    FoodGroceryDeliveryVerificationNotifier,
    FoodGroceryDeliveryVerificationState>(
  (ref) => FoodGroceryDeliveryVerificationNotifier(),
);
