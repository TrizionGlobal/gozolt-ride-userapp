import 'package:flutter_riverpod/flutter_riverpod.dart';
 
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
        );
 
  final String orderId;
 
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
 
    // TODO(FOOD_GROCERY_CHAT_API):
    // Send this message to the backend/WebSocket using:
    // orderId, delivery-partner ID and customer ID.
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
 
    // TODO(FOOD_GROCERY_CHAT_REALTIME):
    // Replace this temporary method with incoming WebSocket messages.
  }
 
  void clear() {
    state = const [];
  }
}
 
final foodGroceryChatProvider = StateNotifierProvider.family<
    FoodGroceryChatNotifier, List<FoodGroceryChatMessage>, String>(
  (ref, orderId) {
    return FoodGroceryChatNotifier(
      orderId: orderId,
    );
  },
);
 