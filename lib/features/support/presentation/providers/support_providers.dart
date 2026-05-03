import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/dio_provider.dart';
import '../../data/datasources/support_remote_datasource.dart';
import '../../data/models/create_ticket_request.dart';
import '../../data/models/support_ticket.dart';
import '../../data/models/ticket_reply.dart';

final supportRemoteDatasourceProvider =
    Provider<SupportRemoteDatasource>((ref) {
  return SupportRemoteDatasource(ref.read(dioProvider));
});

/// All user tickets (newest first).
final supportTicketsProvider =
    StateNotifierProvider<SupportTicketsNotifier, SupportTicketsState>((ref) {
  final ds = ref.read(supportRemoteDatasourceProvider);
  return SupportTicketsNotifier(ds);
});

/// Single ticket detail with replies.
final ticketDetailProvider =
    FutureProvider.family<SupportTicket, String>((ref, ticketId) async {
  if (AppConstants.kDevBypass) {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockTickets.firstWhere(
      (t) => t.id == ticketId,
      orElse: () => _mockTickets.first,
    );
  }
  final ds = ref.read(supportRemoteDatasourceProvider);
  return ds.getTicketDetail(ticketId);
});

/// Manages ticket replies with optimistic updates.
final ticketRepliesProvider = StateNotifierProvider.family<
    TicketRepliesNotifier, List<TicketReply>, String>((ref, ticketId) {
  final ds = ref.read(supportRemoteDatasourceProvider);
  final ticketAsync = ref.watch(ticketDetailProvider(ticketId));
  final initialReplies = ticketAsync.value?.replies ?? [];
  return TicketRepliesNotifier(ds, ticketId, initialReplies);
});

// ── Tickets List State ────────────────────────────────────
class SupportTicketsState {
  final List<SupportTicket> tickets;
  final bool isLoading;
  final String? error;

  const SupportTicketsState({
    this.tickets = const [],
    this.isLoading = false,
    this.error,
  });

  SupportTicketsState copyWith({
    List<SupportTicket>? tickets,
    bool? isLoading,
    String? error,
  }) {
    return SupportTicketsState(
      tickets: tickets ?? this.tickets,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SupportTicketsNotifier extends StateNotifier<SupportTicketsState> {
  final SupportRemoteDatasource _ds;

  SupportTicketsNotifier(this._ds) : super(const SupportTicketsState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);

    if (AppConstants.kDevBypass) {
      await Future.delayed(const Duration(milliseconds: 300));
      state = SupportTicketsState(tickets: _mockTickets);
      return;
    }

    try {
      final tickets = await _ds.getTickets();
      state = SupportTicketsState(tickets: tickets);
    } catch (_) {
      state = const SupportTicketsState(tickets: [], isLoading: false);
    }
  }

  Future<SupportTicket?> createTicket(CreateTicketRequest request) async {
    if (AppConstants.kDevBypass) {
      await Future.delayed(const Duration(milliseconds: 500));
      final newTicket = SupportTicket(
        id: 'tkt-${DateTime.now().millisecondsSinceEpoch}',
        rideId: request.rideId,
        category: request.category,
        subject: request.subject,
        description: request.description,
        status: 'OPEN',
        createdAt: DateTime.now().toIso8601String(),
      );
      state = state.copyWith(tickets: [newTicket, ...state.tickets]);
      return newTicket;
    }

    try {
      final ticket = await _ds.createTicket(request);
      state = state.copyWith(tickets: [ticket, ...state.tickets]);
      return ticket;
    } catch (e) {
      return null;
    }
  }
}

// ── Ticket Replies Notifier ───────────────────────────────
class TicketRepliesNotifier extends StateNotifier<List<TicketReply>> {
  final SupportRemoteDatasource _ds;
  final String _ticketId;

  TicketRepliesNotifier(
      this._ds, this._ticketId, List<TicketReply> initialReplies)
      : super(initialReplies);

  Future<void> sendReply(String message) async {
    final tempId = 'temp-${DateTime.now().millisecondsSinceEpoch}';
    final optimistic = TicketReply(
      id: tempId,
      authorId: 'dev-user',
      authorRole: 'USER',
      message: message,
      createdAt: DateTime.now().toIso8601String(),
      isSending: true,
    );

    state = [...state, optimistic];

    if (AppConstants.kDevBypass) {
      await Future.delayed(const Duration(milliseconds: 300));
      state = [
        ...state.where((r) => r.id != tempId),
        TicketReply(
          id: tempId,
          authorId: 'dev-user',
          authorRole: 'USER',
          message: message,
          createdAt: DateTime.now().toIso8601String(),
        ),
      ];
      // Simulate support auto-reply after 3s
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          state = [
            ...state,
            TicketReply(
              id: 'reply-auto-${DateTime.now().millisecondsSinceEpoch}',
              authorId: 'support-agent',
              authorRole: 'ADMIN',
              message:
                  'Thank you for reaching out. A support agent will review your message shortly.',
              createdAt: DateTime.now().toIso8601String(),
            ),
          ];
        }
      });
      return;
    }

    try {
      final reply = await _ds.replyToTicket(_ticketId, message);
      state = [
        ...state.where((r) => r.id != tempId),
        reply,
      ];
    } catch (_) {
      state = state.map((r) {
        if (r.id == tempId) {
          return TicketReply(
            id: tempId,
            authorId: r.authorId,
            authorRole: r.authorRole,
            message: r.message,
            createdAt: r.createdAt,
            isFailed: true,
          );
        }
        return r;
      }).toList();
    }
  }
}

// ── Dev Mock Data ─────────────────────────────────────────
final _mockTickets = [
  SupportTicket(
    id: 'tkt-a1b2c3d4',
    rideId: 'ride-003',
    category: 'DRIVER_BEHAVIOR',
    subject: 'Driver asked me to cancel the ride',
    description:
        'My driver called me after accepting the ride and asked me to cancel because he didn\'t want to drive to my pickup location. This is very unprofessional behavior.',
    status: 'IN_PROGRESS',
    createdAt: '2025-05-17T19:00:00Z',
    replies: [
      const TicketReply(
        id: 'reply-001',
        authorId: 'support-agent-1',
        authorRole: 'ADMIN',
        message:
            'Hi there! Thank you for reporting this. We take driver behavior very seriously. We\'re looking into this incident and will follow up with the driver. You were not charged for this ride.',
        createdAt: '2025-05-17T20:30:00Z',
      ),
      const TicketReply(
        id: 'reply-002',
        authorId: 'dev-user',
        authorRole: 'USER',
        message:
            'Thank you for the quick response. I appreciate you looking into it.',
        createdAt: '2025-05-17T21:00:00Z',
      ),
    ],
  ),
  const SupportTicket(
    id: 'tkt-e5f6g7h8',
    category: 'PAYMENT_ISSUE',
    subject: 'Double charged for my last ride',
    description:
        'I was charged twice for my ride on May 18. The ride from Airport to Hilton Malta shows two payments of EUR 23.50 on my credit card statement.',
    status: 'OPEN',
    createdAt: '2025-05-19T11:00:00Z',
    rideId: 'ride-002',
  ),
  const SupportTicket(
    id: 'tkt-i9j0k1l2',
    category: 'LOST_ITEM',
    subject: 'Left my phone charger in the car',
    description:
        'I left my USB-C phone charger in the back seat of the car during my ride from Spinola Bay to The Point. The driver was Anna Vella.',
    status: 'RESOLVED',
    createdAt: '2025-05-15T13:00:00Z',
    rideId: 'ride-005',
    replies: [
      TicketReply(
        id: 'reply-003',
        authorId: 'support-agent-2',
        authorRole: 'ADMIN',
        message:
            'We\'ve contacted the driver and they confirmed they found your charger. They\'ll drop it off at our Sliema office. You can pick it up anytime between 9 AM - 6 PM.',
        createdAt: '2025-05-15T14:30:00Z',
      ),
      TicketReply(
        id: 'reply-004',
        authorId: 'dev-user',
        authorRole: 'USER',
        message: 'Great, I\'ll pick it up tomorrow. Thanks!',
        createdAt: '2025-05-15T15:00:00Z',
      ),
      TicketReply(
        id: 'reply-005',
        authorId: 'support-agent-2',
        authorRole: 'ADMIN',
        message:
            'You\'re welcome! We\'re marking this as resolved. Feel free to open a new ticket if you need anything else.',
        createdAt: '2025-05-15T15:10:00Z',
      ),
    ],
  ),
];
