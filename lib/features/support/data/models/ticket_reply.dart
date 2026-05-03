class TicketReply {
  final String id;
  final String authorId;
  final String authorRole;
  final String message;
  final String createdAt;
  final bool isSending;
  final bool isFailed;

  const TicketReply({
    required this.id,
    required this.authorId,
    required this.authorRole,
    required this.message,
    required this.createdAt,
    this.isSending = false,
    this.isFailed = false,
  });

  factory TicketReply.fromJson(Map<String, dynamic> json) {
    return TicketReply(
      id: json['id'] as String,
      authorId: json['authorId'] as String? ?? '',
      authorRole: json['authorRole'] as String? ?? 'USER',
      message: json['message'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  bool get isUser => authorRole == 'USER';
  bool get isAdmin => authorRole == 'ADMIN' || authorRole == 'SUPPORT';
}
