import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    try {
      final tickets = await _ds.getTickets();
      state = SupportTicketsState(tickets: tickets);
    } catch (_) {
      state = const SupportTicketsState(tickets: [], isLoading: false);
    }
  }

  Future<SupportTicket?> createTicket(CreateTicketRequest request) async {
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
