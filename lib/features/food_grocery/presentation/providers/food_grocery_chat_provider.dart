import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/socket_service.dart';

enum FoodGroceryChatSender {
  customer,
  deliveryPartner,
}

class FoodGroceryChatMessage {
  const FoodGroceryChatMessage({
    required this.id,
    required this.orderId,
    required this.text,
    required this.sender,
    required this.sentAt,
  });

  final String id;
  final String orderId;
  final String text;
  final FoodGroceryChatSender sender;
  final DateTime sentAt;

  bool get isFromCustomer {
    return sender == FoodGroceryChatSender.customer;
  }
}

class FoodGroceryChatNotifier
    extends StateNotifier<List<FoodGroceryChatMessage>> {
  FoodGroceryChatNotifier({
    required this.orderId,
    required this.socketService,
  }) : super(
          [
            FoodGroceryChatMessage(
              id: 'welcome-$orderId',
              orderId: orderId,
              text:
                  'Hello, I’m your GOZOLT delivery partner. You can message me about this delivery.',
              sender: FoodGroceryChatSender.deliveryPartner,
              sentAt: DateTime.now(),
            ),
          ],
        ) {
    _initSocket();
  }

  final String orderId;
  final UserSocketService socketService;
  StreamSubscription? _sub;

  void _initSocket() {
    socketService.joinFoodGroceryOrder(orderId);
    _sub = socketService.onFoodGroceryChatMessage.listen((data) {
      final msgOrderId = data['orderId']?.toString();
      if (msgOrderId != orderId) return;

      final senderRole = data['senderRole']?.toString();
      if (senderRole != 'USER') {
        final text = data['message']?.toString() ?? '';
        if (text.trim().isNotEmpty) {
          final message = FoodGroceryChatMessage(
            id: data['id']?.toString() ??
                DateTime.now().microsecondsSinceEpoch.toString(),
            orderId: orderId,
            text: text.trim(),
            sender: FoodGroceryChatSender.deliveryPartner,
            sentAt: DateTime.now(),
          );
          state = [...state, message];
        }
      }
    });
  }

  void sendCustomerMessage(String text) {
    final trimmedText = text.trim();

    if (trimmedText.isEmpty) {
      return;
    }

    final message = FoodGroceryChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      orderId: orderId,
      text: trimmedText,
      sender: FoodGroceryChatSender.customer,
      sentAt: DateTime.now(),
    );

    state = [
      ...state,
      message,
    ];

    socketService.sendFoodGroceryChatMessage(orderId, trimmedText);
  }

  void receiveTemporaryPartnerMessage(String text) {
    final trimmedText = text.trim();

    if (trimmedText.isEmpty) {
      return;
    }

    final message = FoodGroceryChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      orderId: orderId,
      text: trimmedText,
      sender: FoodGroceryChatSender.deliveryPartner,
      sentAt: DateTime.now(),
    );

    state = [
      ...state,
      message,
    ];
  }

  void clear() {
    state = const [];
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final foodGroceryChatProvider = StateNotifierProvider.family<
    FoodGroceryChatNotifier, List<FoodGroceryChatMessage>, String>(
  (ref, orderId) {
    final socket = ref.watch(socketServiceProvider);
    return FoodGroceryChatNotifier(
      orderId: orderId,
      socketService: socket,
    );
  },
);
 