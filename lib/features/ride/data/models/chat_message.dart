class ChatMessage {
  final String id;
  final String rideId;
  final String senderId;
  final String senderRole; // 'USER' or 'DRIVER'
  final String message;
  final String timestamp;
  final bool isSending;
  final bool hasFailed;

  const ChatMessage({
    required this.id,
    required this.rideId,
    required this.senderId,
    required this.senderRole,
    required this.message,
    required this.timestamp,
    this.isSending = false,
    this.hasFailed = false,
  });

  bool get isUser => senderRole == 'USER';

  ChatMessage copyWith({bool? isSending, bool? hasFailed}) {
    return ChatMessage(
      id: id,
      rideId: rideId,
      senderId: senderId,
      senderRole: senderRole,
      message: message,
      timestamp: timestamp,
      isSending: isSending ?? this.isSending,
      hasFailed: hasFailed ?? this.hasFailed,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    // Handle timestamp: backend sends epoch ms (int), but could also be String
    String ts;
    final rawTs = json['timestamp'];
    if (rawTs is int) {
      ts = DateTime.fromMillisecondsSinceEpoch(rawTs).toIso8601String();
    } else if (rawTs is String) {
      ts = rawTs;
    } else {
      ts = json['createdAt'] as String? ?? DateTime.now().toIso8601String();
    }

    return ChatMessage(
      id: (json['id'] ?? '').toString(),
      rideId: json['rideId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      senderRole: json['senderRole'] as String? ?? 'USER',
      message: json['message'] as String? ?? json['content'] as String? ?? '',
      timestamp: ts,
    );
  }
}
