import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ride/data/models/saved_payment_method.dart';

enum FoodGroceryOrderStatus {
  idle,
  processing,
  placed,
  supplierAccepted,
  failed,
}

enum FoodGroceryTrackingStage {
  supplierAccepted,
  preparing,
  readyForPickup,
  pickedUp,
  onTheWay,
  arrivingSoon,
}

class FoodGroceryOrderState {
  const FoodGroceryOrderState({
    this.status = FoodGroceryOrderStatus.idle,
    this.orderId,
    this.paymentMethodType = PaymentMethodType.cash,
    this.total = 0,
    this.trackingStage =
        FoodGroceryTrackingStage.supplierAccepted,
    this.errorMessage,
  });

  final FoodGroceryOrderStatus status;
  final String? orderId;
  final PaymentMethodType paymentMethodType;
  final double total;
  final FoodGroceryTrackingStage trackingStage;
  final String? errorMessage;

  bool get isProcessing => status == FoodGroceryOrderStatus.processing;
  bool get isPlaced =>
      status == FoodGroceryOrderStatus.placed ||
      status == FoodGroceryOrderStatus.supplierAccepted;

  bool get isAwaitingSupplier => status == FoodGroceryOrderStatus.placed;

  bool get isSupplierAccepted =>
      status == FoodGroceryOrderStatus.supplierAccepted;

  bool get hasFailed => status == FoodGroceryOrderStatus.failed;

  String get paymentMethodLabel {
    return paymentMethodType == PaymentMethodType.cash
        ? 'Cash on Delivery'
        : 'Credit / Debit Card';
  }

  String get paymentStatusLabel {
    return paymentMethodType == PaymentMethodType.cash
        ? 'Payment due on delivery'
        : 'Card payment selected';
  }

  String get trackingTitle {
  switch (trackingStage) {
    case FoodGroceryTrackingStage.supplierAccepted:
      return 'Order accepted';

    case FoodGroceryTrackingStage.preparing:
      return 'Preparing your order';

    case FoodGroceryTrackingStage.readyForPickup:
      return 'Ready for pickup';

    case FoodGroceryTrackingStage.pickedUp:
      return 'Order collected';

    case FoodGroceryTrackingStage.onTheWay:
      return 'Your order is on the way';

    case FoodGroceryTrackingStage.arrivingSoon:
      return 'Arriving soon';
  }
}

  String get trackingDescription {
    switch (trackingStage) {
      case FoodGroceryTrackingStage.supplierAccepted:
        return 'The supplier accepted your order.';

      case FoodGroceryTrackingStage.preparing:
        return 'The supplier is preparing your items.';

      case FoodGroceryTrackingStage.readyForPickup:
        return 'Your order is packed and ready for collection.';

      case FoodGroceryTrackingStage.pickedUp:
        return 'The delivery partner collected your order.';

      case FoodGroceryTrackingStage.onTheWay:
        return 'The delivery partner is heading to your address.';

      case FoodGroceryTrackingStage.arrivingSoon:
        return 'Your delivery partner is close to your address.';
    }
  }

int get trackingStep {
  return trackingStage.index + 1;
}

bool get isArrivingSoon {
  return trackingStage ==
      FoodGroceryTrackingStage.arrivingSoon;
}

  FoodGroceryOrderState copyWith({
    FoodGroceryOrderStatus? status,
    String? orderId,
    PaymentMethodType? paymentMethodType,
    double? total,
    FoodGroceryTrackingStage? trackingStage,
    String? errorMessage,
    bool clearError = false,
  }) {
    return FoodGroceryOrderState(
      status: status ?? this.status,
      orderId: orderId ?? this.orderId,
      paymentMethodType: paymentMethodType ?? this.paymentMethodType,
      total: total ?? this.total,
      trackingStage: trackingStage ?? this.trackingStage,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class FoodGroceryOrderNotifier extends StateNotifier<FoodGroceryOrderState> {
  FoodGroceryOrderNotifier() : super(const FoodGroceryOrderState());

  Future<void> placeTemporaryOrder({
    required PaymentMethodType paymentMethodType,
    required double total,
  }) async {
    if (state.isProcessing) {
      return;
    }

    state = FoodGroceryOrderState(
      status: FoodGroceryOrderStatus.processing,
      paymentMethodType: paymentMethodType,
      total: total,
    );

    try {
      // TODO(FOOD_GROCERY_API):
      // Replace this temporary delay with the real create-order API.
      //
      // For cash:
      // Send paymentMethod as CASH_ON_DELIVERY.
      //
      // For card:
      // Send the selected Stripe PaymentMethod ID and confirm
      // the PaymentIntent returned by the backend.
      await Future<void>.delayed(
        const Duration(milliseconds: 1600),
      );

      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      final temporaryOrderId =
          'FG-${timestamp.substring(timestamp.length - 8)}';

      state = FoodGroceryOrderState(
        status: FoodGroceryOrderStatus.placed,
        orderId: temporaryOrderId,
        paymentMethodType: paymentMethodType,
        total: total,
      );
    } catch (_) {
      state = FoodGroceryOrderState(
        status: FoodGroceryOrderStatus.failed,
        paymentMethodType: paymentMethodType,
        total: total,
        errorMessage: 'Unable to place your order. Please try again.',
      );
    }
  }

  Future<void> retry() async {
    final currentPaymentMethod = state.paymentMethodType;
    final currentTotal = state.total;

    await placeTemporaryOrder(
      paymentMethodType: currentPaymentMethod,
      total: currentTotal,
    );
  }

  Future<void> simulateSupplierAcceptance() async {
    if (!state.isAwaitingSupplier) {
      return;
    }

    // TODO(FOOD_GROCERY_REALTIME):
    // Remove this method when supplier order status is received
    // through the Food & Grocery API/WebSocket connection.
    await Future<void>.delayed(
      const Duration(milliseconds: 900),
    );

    state = state.copyWith(
      status: FoodGroceryOrderStatus.supplierAccepted,
      trackingStage:
      FoodGroceryTrackingStage.supplierAccepted,
      clearError: true,
    );
  }

Future<void> advanceTemporaryTracking() async {
  if (!state.isSupplierAccepted ||
      state.isArrivingSoon) {
    return;
  }

  // TODO(FOOD_GROCERY_REALTIME):
  // Replace this temporary progression with live order
  // status updates from the backend/WebSocket service.
  await Future<void>.delayed(
    const Duration(milliseconds: 700),
  );

  final nextIndex = state.trackingStage.index + 1;

  final stages =
      FoodGroceryTrackingStage.values;

  if (nextIndex >= stages.length) {
    return;
  }

  state = state.copyWith(
    trackingStage: stages[nextIndex],
    clearError: true,
  );
}


  void reset() {
    state = const FoodGroceryOrderState();
  }
}

final foodGroceryOrderProvider =
    StateNotifierProvider<FoodGroceryOrderNotifier, FoodGroceryOrderState>(
  (ref) => FoodGroceryOrderNotifier(),
);
