import 'ticket_reply.dart';

class SupportTicket {
  final String id;
  final String? rideId;
  final String category;
  final String subject;
  final String description;
  final String status;
  final String createdAt;
  final String? updatedAt;
  final List<TicketReply> replies;

  const SupportTicket({
    required this.id,
    required this.category,
    required this.subject,
    required this.description,
    required this.status,
    required this.createdAt,
    this.rideId,
    this.updatedAt,
    this.replies = const [],
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'] as String,
      rideId: json['rideId'] as String?,
      category: json['category'] as String? ?? 'OTHER',
      subject: json['subject'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'OPEN',
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String?,
      replies: (json['replies'] as List<dynamic>?)
              ?.map((r) => TicketReply.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  String get shortId => id.length > 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();

  bool get isOpen => status == 'OPEN';
  bool get isInProgress => status == 'IN_PROGRESS';
  bool get isResolved => status == 'RESOLVED';
  bool get isClosed => status == 'CLOSED';
  bool get canReply => isOpen || isInProgress;

  String get displayCategory {
    switch (category) {
      case 'RIDE_ISSUE':
        return 'Ride Issue';
      case 'PAYMENT_ISSUE':
        return 'Payment Issue';
      case 'DRIVER_BEHAVIOR':
        return 'Driver Behavior';
      case 'SAFETY_CONCERN':
        return 'Safety Concern';
      case 'LOST_ITEM':
        return 'Lost Item';
      case 'APP_BUG':
        return 'App Bug';
      case 'ACCOUNT_ISSUE':
        return 'Account Issue';
      case 'OTHER':
        return 'Other';
      default:
        return category;
    }
  }
}
