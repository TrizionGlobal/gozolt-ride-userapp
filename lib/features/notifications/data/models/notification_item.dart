class NotificationItem {
  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final bool read;
  final String createdAt;

  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    required this.read,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'SYSTEM',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      data: json['data'] as Map<String, dynamic>?,
      read: json['read'] as bool? ?? false,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  bool get isRideUpdate => type == 'RIDE_UPDATE';
  bool get isPromotion => type == 'PROMOTION';
  bool get isPayment => type == 'PAYMENT';
  bool get isSystem => type == 'SYSTEM';
}

class NotificationPreference {
  final bool rideUpdates;
  final bool payments;
  final bool promotions;
  final bool systemAlerts;

  const NotificationPreference({
    this.rideUpdates = true,
    this.payments = true,
    this.promotions = true,
    this.systemAlerts = true,
  });

  factory NotificationPreference.fromJson(Map<String, dynamic> json) {
    return NotificationPreference(
      rideUpdates: json['rideUpdates'] as bool? ?? true,
      payments: json['payments'] as bool? ?? true,
      promotions: json['promotions'] as bool? ?? true,
      systemAlerts: json['systemAlerts'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'rideUpdates': rideUpdates,
        'payments': payments,
        'promotions': promotions,
        'systemAlerts': systemAlerts,
      };

  NotificationPreference copyWith({
    bool? rideUpdates,
    bool? payments,
    bool? promotions,
    bool? systemAlerts,
  }) {
    return NotificationPreference(
      rideUpdates: rideUpdates ?? this.rideUpdates,
      payments: payments ?? this.payments,
      promotions: promotions ?? this.promotions,
      systemAlerts: systemAlerts ?? this.systemAlerts,
    );
  }
}
