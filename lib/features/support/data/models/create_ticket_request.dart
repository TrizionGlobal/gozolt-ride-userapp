class CreateTicketRequest {
  final String? rideId;
  final String category;
  final String subject;
  final String description;

  const CreateTicketRequest({
    this.rideId,
    required this.category,
    required this.subject,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'category': category,
      'subject': subject,
      'description': description,
    };
    if (rideId != null) map['rideId'] = rideId;
    return map;
  }
}
