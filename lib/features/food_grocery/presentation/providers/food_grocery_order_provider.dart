import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/network/socket_service.dart';
import '../../../ride/data/models/saved_payment_method.dart';
import '../../data/datasources/food_grocery_remote_datasource.dart';
import '../../data/models/food_grocery_cart.dart';
import 'food_grocery_cart_provider.dart';
import 'food_grocery_substitution_provider.dart';
import 'food_grocery_rating_provider.dart';

void _log(String msg) {
  if (kDebugMode) print(msg);
}

enum FoodGroceryOrderStatus {
  idle,
  processing,
  placed,
  supplierAccepted,
  failed,
}

enum FoodGroceryTrackingStage {
  awaitingSupplier,
  supplierAccepted,
  preparing,
  readyForPickup,
  pickedUp,
  onTheWay,
  arrivingSoon,
  arrivedAtCustomer,
}

class FoodGroceryOrderState {
  const FoodGroceryOrderState({
    this.status = FoodGroceryOrderStatus.idle,
    this.orderId,
    this.formattedBookingId,
    this.orderReference,
    this.orderData,
    this.paymentMethodType = PaymentMethodType.cash,
    this.total = 0,
    this.trackingStage = FoodGroceryTrackingStage.awaitingSupplier,
    this.errorMessage,
    this.isLoading = false,
  });

  final FoodGroceryOrderStatus status;
  final String? orderId;
  final String? formattedBookingId;
  final String? orderReference;
  final Map<String, dynamic>? orderData;
  final PaymentMethodType paymentMethodType;
  final double total;
  final FoodGroceryTrackingStage trackingStage;
  final String? errorMessage;
  final bool isLoading;

  /// Returns the formatted booking reference directly (e.g. `GZ-FG-XXXXXXXX`)
  String get displayBookingId =>
      formattedBookingId ??
      orderReference ??
      orderData?['formattedBookingId']?.toString() ??
      orderId ??
      '';

  bool get isProcessing => status == FoodGroceryOrderStatus.processing;
  bool get isPlaced =>
      status == FoodGroceryOrderStatus.placed ||
      status == FoodGroceryOrderStatus.supplierAccepted;
  bool get isAwaitingSupplier => trackingStage == FoodGroceryTrackingStage.awaitingSupplier;
  bool get isSupplierAccepted =>
      status == FoodGroceryOrderStatus.supplierAccepted ||
      trackingStage.index >= FoodGroceryTrackingStage.supplierAccepted.index;
  bool get hasFailed => status == FoodGroceryOrderStatus.failed;
  bool get isArrivingSoon =>
      trackingStage == FoodGroceryTrackingStage.arrivingSoon ||
      trackingStage == FoodGroceryTrackingStage.arrivedAtCustomer;

  int get trackingStep => trackingStage.index;

  String get paymentMethodLabel =>
      paymentMethodType == PaymentMethodType.cash
          ? 'Cash on Delivery'
          : 'Credit / Debit Card';

  String get paymentStatusLabel =>
      paymentMethodType == PaymentMethodType.cash
          ? 'Payment due on delivery'
          : 'Card payment selected';

  String get trackingTitle {
    switch (trackingStage) {
      case FoodGroceryTrackingStage.awaitingSupplier:
        return 'Waiting for supplier';
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
      case FoodGroceryTrackingStage.arrivedAtCustomer:
        return 'Driver arrived';
    }
  }

  String get trackingDescription {
    switch (trackingStage) {
      case FoodGroceryTrackingStage.awaitingSupplier:
        return 'Waiting for the supplier to accept your order.';
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
      case FoodGroceryTrackingStage.arrivedAtCustomer:
        return 'Your delivery partner has arrived. Please come to the door.';
    }
  }

  FoodGroceryOrderState copyWith({
    FoodGroceryOrderStatus? status,
    String? orderId,
    String? formattedBookingId,
    String? orderReference,
    Map<String, dynamic>? orderData,
    PaymentMethodType? paymentMethodType,
    double? total,
    FoodGroceryTrackingStage? trackingStage,
    String? errorMessage,
    bool clearError = false,
    bool? isLoading,
  }) {
    return FoodGroceryOrderState(
      status: status ?? this.status,
      orderId: orderId ?? this.orderId,
      formattedBookingId: formattedBookingId ?? this.formattedBookingId,
      orderReference: orderReference ?? this.orderReference,
      orderData: orderData ?? this.orderData,
      paymentMethodType: paymentMethodType ?? this.paymentMethodType,
      total: total ?? this.total,
      trackingStage: trackingStage ?? this.trackingStage,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class FoodGroceryOrderNotifier extends StateNotifier<FoodGroceryOrderState> {
  FoodGroceryOrderNotifier(this._ref) : super(const FoodGroceryOrderState());

  final Ref _ref;

  static FoodGroceryTrackingStage _backendStatusToStage(String? backendStatus) {
    switch (backendStatus?.toUpperCase()) {
      case 'SUPPLIER_ACCEPTED':
        return FoodGroceryTrackingStage.supplierAccepted;
      case 'PREPARING':
        return FoodGroceryTrackingStage.preparing;
      case 'PICKING_ITEMS':
        return FoodGroceryTrackingStage.preparing;
      case 'PACKING':
        return FoodGroceryTrackingStage.preparing;
      case 'READY_FOR_PICKUP':
        return FoodGroceryTrackingStage.readyForPickup;
      case 'PICKED_UP':
        return FoodGroceryTrackingStage.pickedUp;
      case 'ON_THE_WAY':
        return FoodGroceryTrackingStage.onTheWay;
      case 'ARRIVING_SOON':
        return FoodGroceryTrackingStage.arrivingSoon;
      case 'ARRIVED_AT_CUSTOMER':
        return FoodGroceryTrackingStage.arrivedAtCustomer;
      default:
        return FoodGroceryTrackingStage.awaitingSupplier;
    }
  }

  Future<void> placeOrder({
    required FoodGroceryCartState cart,
    required PaymentMethodType paymentMethodType,
    required String? deliveryAddressId,
    required Map<String, dynamic>? deliveryAddressSnapshot,
    bool leaveAtDoor = false,
    String? deliveryInstructions,
    int goCoinsToUse = 0,
    String? stripePaymentMethodId,
    String? stripePaymentIntentId,
  }) async {
    if (state.isProcessing) return;

    state = FoodGroceryOrderState(
      status: FoodGroceryOrderStatus.processing,
      paymentMethodType: paymentMethodType,
      total: cart.total,
      isLoading: true,
    );

    try {
      final ds = _ref.read(foodGroceryRemoteDatasourceProvider);

      final cartItems = cart.items.map((item) {
        return <String, dynamic>{
          'productId': item.productId,
          if (item.variantId != null) 'variantId': item.variantId,
          'quantity': item.quantity,
          if (item.modifiers.isNotEmpty)
            'modifiers': item.modifiers.map((m) => {
              'id': m.id,
              'name': m.name,
              'price': m.price,
            }).toList(),
          if (item.instructions != null && item.instructions!.isNotEmpty)
            'instructions': item.instructions,
        };
      }).toList();

      final orderData = await ds.createOrder(
        businessId: cart.supplierId ?? '',
        items: cartItems,
        paymentMethod: paymentMethodType == PaymentMethodType.cash ? 'CASH' : 'CARD',
        stripePaymentMethodId: stripePaymentMethodId,
        stripePaymentIntentId: stripePaymentIntentId,
        goCoinsToUse: goCoinsToUse,
        deliveryAddressId: deliveryAddressId,
        deliveryAddressSnapshot: deliveryAddressSnapshot,
        leaveAtDoor: leaveAtDoor,
        deliveryInstructions: deliveryInstructions,
      );

      if (!mounted) return;

      final orderId = orderData['id']?.toString() ?? orderData['orderId']?.toString();
      final formattedBookingId = orderData['formattedBookingId']?.toString() ??
          orderData['orderReference']?.toString() ??
          orderId ??
          '';
      final backendStatus = orderData['status']?.toString();

      state = FoodGroceryOrderState(
        status: FoodGroceryOrderStatus.placed,
        orderId: orderId,
        formattedBookingId: formattedBookingId,
        orderReference: formattedBookingId,
        orderData: orderData,
        paymentMethodType: paymentMethodType,
        total: cart.total,
        trackingStage: _backendStatusToStage(backendStatus),
        isLoading: false,
      );

      // Join the WebSocket order room for real-time updates
      if (orderId != null) {
        final socket = _ref.read(socketServiceProvider);
        socket.joinFoodGroceryOrder(orderId);
        _listenToOrderUpdates(orderId);
      }

      // Clear cart after successful placement
      _ref.read(foodGroceryCartProvider.notifier).clearCart();
    } catch (e) {
      _log('[FoodGroceryOrder] placeOrder failed: $e');
      if (!mounted) return;
      String errorMsg = 'Unable to place your order. Please try again.';
      if (e is DioException) {
        final resData = e.response?.data;
        if (resData is Map && resData['message'] != null) {
          final m = resData['message'];
          errorMsg = m is List ? m.join(', ') : m.toString();
        } else if (e.message != null && e.message!.isNotEmpty) {
          errorMsg = e.message!;
        }
      }
      state = FoodGroceryOrderState(
        status: FoodGroceryOrderStatus.failed,
        paymentMethodType: paymentMethodType,
        total: cart.total,
        errorMessage: errorMsg,
        isLoading: false,
      );
    }
  }

  void _listenToOrderUpdates(String orderId) {
    final socket = _ref.read(socketServiceProvider);

    socket.onFoodGroceryOrderStatus.listen((event) {
      if (!mounted) return;
      final eventOrderId = event['orderId']?.toString() ?? event['id']?.toString();
      if (eventOrderId != orderId) return;

      final backendStatus = event['status']?.toString();
      _log('[FoodGroceryOrder] Status update received: $backendStatus for $orderId');

      final stage = _backendStatusToStage(backendStatus);

      FoodGroceryOrderStatus orderStatus = state.status;
      if (backendStatus == 'SUPPLIER_ACCEPTED') {
        orderStatus = FoodGroceryOrderStatus.supplierAccepted;
      } else if (backendStatus == 'CANCELLED') {
        orderStatus = FoodGroceryOrderStatus.failed;
      } else if (backendStatus == 'COMPLETED') {
        orderStatus = FoodGroceryOrderStatus.placed;
      }

      state = state.copyWith(
        status: orderStatus,
        trackingStage: stage,
      );
    });

    socket.onFoodGrocerySubstitution.listen((event) {
      if (!mounted) return;
      final eventOrderId = event['orderId']?.toString();
      if (eventOrderId != orderId) return;

      if (event['eventType'] == 'requested') {
        _log('[FoodGroceryOrder] Substitution requested for $orderId');
        // The UI listens to substitution events independently
      }
    });
  }

  Future<void> pollOrderStatus(String orderId) async {
    if (!mounted) return;
    try {
      final ds = _ref.read(foodGroceryRemoteDatasourceProvider);
      final orderData = await ds.getOrderDetails(orderId);
      if (!mounted) return;
      final backendStatus = orderData['status']?.toString();
      state = state.copyWith(
        orderData: orderData,
        trackingStage: _backendStatusToStage(backendStatus),
      );
    } catch (_) {
      // Silently ignore polling failures — WebSocket covers realtime
    }
  }

  Future<bool> submitSubstitutionDecisions(String orderId) async {
    final substitution = _ref.read(foodGrocerySubstitutionProvider);
    if (!substitution.allDecisionsCompleted) return false;

    try {
      final ds = _ref.read(foodGroceryRemoteDatasourceProvider);
      final decisions = substitution.items.map((item) {
        return {
          'itemId': item.id,
          'choice': item.choice == GrocerySubstitutionChoice.replacement
              ? 'REPLACEMENT'
              : 'REFUND',
        };
      }).toList();
      await ds.submitSubstitutions(orderId: orderId, decisions: decisions);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> confirmOrderReceived(String orderId) async {
    try {
      final ds = _ref.read(foodGroceryRemoteDatasourceProvider);
      await ds.confirmOrderReceived(orderId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> submitRating(String orderId) async {
    final rating = _ref.read(foodGroceryRatingProvider);
    if (!rating.canSubmit) return false;

    _ref.read(foodGroceryRatingProvider.notifier).state =
        rating.copyWith(isSubmitting: true);

    try {
      final ds = _ref.read(foodGroceryRemoteDatasourceProvider);
      await ds.rateOrder(
        orderId: orderId,
        overallRating: rating.overallRating,
        supplierRating: rating.supplierRating,
        deliveryRating: rating.deliveryRating,
        tags: rating.selectedTags.toList(),
        comment: rating.comment.trim().isEmpty ? null : rating.comment.trim(),
      );
      _ref.read(foodGroceryRatingProvider.notifier).state =
          rating.copyWith(isSubmitting: false, isSubmitted: true);
      return true;
    } catch (_) {
      _ref.read(foodGroceryRatingProvider.notifier).state =
          rating.copyWith(isSubmitting: false,
              errorMessage: 'Unable to submit your review. Please try again.');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getActiveOrder() async {
    try {
      final ds = _ref.read(foodGroceryRemoteDatasourceProvider);
      final order = await ds.getActiveOrder();
      if (!mounted) return null;
      if (order != null) {
        final orderId = order['id']?.toString() ?? order['orderId']?.toString();
        final backendStatus = order['status']?.toString();
        final payMethod = order['paymentMethod']?.toString().toUpperCase();
        final formattedBookingId = order['formattedBookingId']?.toString() ??
            order['orderReference']?.toString() ??
            orderId ??
            '';
        state = FoodGroceryOrderState(
          status: FoodGroceryOrderStatus.placed,
          orderId: orderId,
          formattedBookingId: formattedBookingId,
          orderReference: formattedBookingId,
          orderData: order,
          paymentMethodType: payMethod == 'CASH'
              ? PaymentMethodType.cash
              : PaymentMethodType.card,
          total: (order['totalAmount'] as num?)?.toDouble() ?? 0,
          trackingStage: _backendStatusToStage(backendStatus),
        );
        if (orderId != null) {
          final socket = _ref.read(socketServiceProvider);
          socket.joinFoodGroceryOrder(orderId);
          _listenToOrderUpdates(orderId);
        }
      }
      return order;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getOrderHistory() async {
    try {
      final ds = _ref.read(foodGroceryRemoteDatasourceProvider);
      return await ds.getOrderHistory();
    } catch (_) {
      return const [];
    }
  }

  void leaveOrderRoom() {
    final orderId = state.orderId;
    if (orderId != null) {
      final socket = _ref.read(socketServiceProvider);
      socket.leaveFoodGroceryOrder(orderId);
    }
  }

  void reset() {
    leaveOrderRoom();
    state = const FoodGroceryOrderState();
  }
}

final foodGroceryOrderProvider =
    StateNotifierProvider<FoodGroceryOrderNotifier, FoodGroceryOrderState>(
  (ref) => FoodGroceryOrderNotifier(ref),
);
