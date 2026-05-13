import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/route_names.dart';
import '../../../history/data/models/ride_history_item.dart';
import '../../../history/presentation/providers/history_providers.dart';
import '../../data/models/support_ticket.dart';
import '../../data/models/ticket_reply.dart';
import '../providers/support_providers.dart';

class TicketDetailScreen extends ConsumerStatefulWidget {
  final String ticketId;
  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> {
  final _replyController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ticketAsync = ref.watch(ticketDetailProvider(widget.ticketId));
    final replies = ref.watch(ticketRepliesProvider(widget.ticketId));

    // Auto-scroll when replies change
    ref.listen(ticketRepliesProvider(widget.ticketId), (context, error) {
      _scrollToBottom();
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        color: AppColors.primaryGold,
        backgroundColor: AppColors.surfaceDark,
        onRefresh: () async {
          ref.invalidate(ticketDetailProvider(widget.ticketId));
          ref.invalidate(ticketRepliesProvider(widget.ticketId));
          await Future.delayed(const Duration(milliseconds: 300));
        },
        child: ticketAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryGold),
          ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: AppColors.textMuted, size: 48),
              const SizedBox(height: 12),
              Text('Failed to load ticket',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary)),
              TextButton(
                onPressed: () => ref.invalidate(
                    ticketDetailProvider(widget.ticketId)),
                child: const Text('Retry',
                    style: TextStyle(color: AppColors.primaryGold)),
              ),
            ],
          ),
        ),
          data: (ticket) =>
              _buildContent(context, ticket, replies),
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, SupportTicket ticket, List<TicketReply> replies) {
    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Header ─────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFD4A843), Color(0xFFF5C518)],
                    ),
                    borderRadius:
                        BorderRadius.vertical(bottom: Radius.circular(24)),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.backgroundDark
                                    .withOpacity(0.15),
                              ),
                              child: const Icon(Icons.arrow_back,
                                  color: AppColors.backgroundDark, size: 20),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Ticket #${ticket.shortId}',
                              style: AppTextStyles.headlineSmall.copyWith(
                                color: AppColors.backgroundDark,
                              ),
                            ),
                          ),
                          _statusBadge(ticket.status),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Ticket Info Card ───────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _ticketInfoCard(ticket),
                ),
              ),

              // ── Linked Ride (if any) ───────────────
              if (ticket.rideId != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: _linkedRideCard(context, ticket.rideId!),
                  ),
                ),

              // ── Status Banner ──────────────────────
              if (ticket.isInProgress)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _statusBanner(
                      icon: Icons.support_agent,
                      text: 'A support agent is reviewing your ticket',
                      color: AppColors.info,
                    ),
                  ),
                ),
              if (ticket.isResolved)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _statusBanner(
                      icon: Icons.check_circle_outline,
                      text:
                          'This ticket has been resolved. Need more help? Create a new ticket.',
                      color: AppColors.success,
                    ),
                  ),
                ),
              if (ticket.isClosed)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _statusBanner(
                      icon: Icons.lock_outline,
                      text: 'This ticket is closed.',
                      color: AppColors.textMuted,
                    ),
                  ),
                ),

              // ── Conversation Divider ───────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Row(
                    children: [
                      Text('Conversation',
                          style: AppTextStyles.titleSmall
                              .copyWith(color: AppColors.textSecondary)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                            height: 1, color: AppColors.borderDark),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Original Message ───────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: _messageBubble(
                    author: 'You',
                    message: ticket.description,
                    timestamp: ticket.createdAt,
                    isUser: true,
                  ),
                ),
              ),

              // ── Replies ────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final reply = replies[index];
                      return _messageBubble(
                        author: reply.isUser ? 'You' : 'Gozolt Support',
                        message: reply.message,
                        timestamp: reply.createdAt,
                        isUser: reply.isUser,
                        isSending: reply.isSending,
                        isFailed: reply.isFailed,
                        onRetry: reply.isFailed
                            ? () => ref
                                .read(ticketRepliesProvider(widget.ticketId)
                                    .notifier)
                                .sendReply(reply.message)
                            : null,
                      );
                    },
                    childCount: replies.length,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Reply Input (only if ticket can accept replies) ──
        if (ticket.canReply) _replyInput(context),
      ],
    );
  }

  // ── Ticket Info Card ───────────────────────────────────
  Widget _ticketInfoCard(SupportTicket ticket) {
    final cat = _categoryStyle(ticket.category);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: cat.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(cat.icon, color: cat.color, size: 14),
              ),
              const SizedBox(width: 8),
              Text(ticket.displayCategory,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: cat.color, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          // Subject
          Text(ticket.subject,
              style: AppTextStyles.titleMedium),
          const SizedBox(height: 6),
          // Date
          Text(
            'Created ${_formatDate(ticket.createdAt)}',
            style: AppTextStyles.labelSmall
                .copyWith(color: AppColors.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  // ── Linked Ride Card ───────────────────────────────────
  Widget _linkedRideCard(BuildContext context, String rideId) {
    RideHistoryItem? ride;
    if (AppConstants.kDevBypass) {
      final historyState = ref.watch(rideHistoryProvider);
      final match = historyState.rides.where((r) => r.id == rideId);
      if (match.isNotEmpty) ride = match.first;
    }

    return GestureDetector(
      onTap: () => context.pushNamed(RouteNames.tripSummary, extra: rideId),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.directions_car,
                  color: AppColors.info, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Linked Ride',
                      style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textMuted, fontSize: 10)),
                  if (ride != null)
                    Text(
                      '${ride.pickupAddress} \u2192 ${ride.dropoffAddress}',
                      style: AppTextStyles.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    Text(rideId,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.primaryGold)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }

  // ── Status Banner ──────────────────────────────────────
  Widget _statusBanner({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: AppTextStyles.bodySmall
                    .copyWith(color: color, height: 1.3)),
          ),
        ],
      ),
    );
  }

  // ── Message Bubble ─────────────────────────────────────
  Widget _messageBubble({
    required String author,
    required String message,
    required String timestamp,
    required bool isUser,
    bool isSending = false,
    bool isFailed = false,
    VoidCallback? onRetry,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Author + time
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isUser) ...[
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.support_agent,
                      color: AppColors.primaryGold, size: 12),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                author,
                style: AppTextStyles.labelSmall.copyWith(
                  color: isUser ? AppColors.textSecondary : AppColors.primaryGold,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
              if (!isUser) ...[
                const SizedBox(width: 4),
                const Icon(Icons.verified,
                    color: AppColors.primaryGold, size: 12),
              ],
              const SizedBox(width: 8),
              Text(
                _formatTime(timestamp),
                style: AppTextStyles.labelSmall
                    .copyWith(color: AppColors.textMuted, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Bubble
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUser
                  ? AppColors.primaryGold.withOpacity(0.08)
                  : AppColors.cardDark,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft: Radius.circular(isUser ? 12 : 2),
                bottomRight: Radius.circular(isUser ? 2 : 12),
              ),
              border: Border.all(
                color: isUser
                    ? AppColors.primaryGold.withOpacity(0.15)
                    : AppColors.borderDark,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    message,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
                if (isSending) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: AppColors.primaryGold,
                    ),
                  ),
                ],
                if (isFailed) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onRetry,
                    child: const Icon(Icons.error,
                        color: AppColors.error, size: 16),
                  ),
                ],
              ],
            ),
          ),
          if (isFailed)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: GestureDetector(
                onTap: onRetry,
                child: Text('Failed to send. Tap to retry.',
                    style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.error, fontSize: 10)),
              ),
            ),
        ],
      ),
    );
  }

  // ── Reply Input Bar ────────────────────────────────────
  Widget _replyInput(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(
          top: BorderSide(color: AppColors.borderDark, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _replyController,
                  onChanged: (_) => setState(() {}),
                  style: AppTextStyles.bodyMedium,
                  maxLines: 3,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: 'Write a reply...',
                    hintStyle: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.inputDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _replyController.text.trim().isNotEmpty
                    ? _sendReply
                    : null,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _replyController.text.trim().isNotEmpty
                        ? AppColors.primaryGold
                        : AppColors.primaryGold.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send,
                      color: AppColors.backgroundDark, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendReply() {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.mediumImpact();
    _replyController.clear();
    setState(() {});
    ref
        .read(ticketRepliesProvider(widget.ticketId).notifier)
        .sendReply(text);
  }

  // ── Status Badge ───────────────────────────────────────
  Widget _statusBadge(String status) {
    final (Color borderColor, Color textColor, String label) =
        _statusColors(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }

  (Color, Color, String) _statusColors(String status) {
    switch (status) {
      case 'OPEN':
        return (AppColors.primaryGold, AppColors.primaryGold, 'Open');
      case 'IN_PROGRESS':
        return (AppColors.info, AppColors.info, 'In Progress');
      case 'RESOLVED':
        return (AppColors.success, AppColors.success, 'Resolved');
      case 'CLOSED':
        return (AppColors.textMuted, AppColors.textMuted, 'Closed');
      default:
        return (AppColors.textMuted, AppColors.textMuted, status);
    }
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return isoDate;
    }
  }

  String _formatTime(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';

      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[dt.month - 1]} ${dt.day}';
    } catch (_) {
      return '';
    }
  }
}

// ── Category Style ───────────────────────────────────────
class _CatStyle {
  final IconData icon;
  final Color color;
  const _CatStyle(this.icon, this.color);
}

_CatStyle _categoryStyle(String category) {
  switch (category) {
    case 'RIDE_ISSUE':
      return _CatStyle(Icons.directions_car, AppColors.info);
    case 'PAYMENT_ISSUE':
      return _CatStyle(Icons.credit_card, AppColors.success);
    case 'DRIVER_BEHAVIOR':
      return _CatStyle(Icons.person_off, AppColors.warning);
    case 'SAFETY_CONCERN':
      return _CatStyle(Icons.shield, AppColors.error);
    case 'LOST_ITEM':
      return _CatStyle(Icons.shopping_bag, const Color(0xFFB388FF));
    case 'APP_BUG':
      return _CatStyle(Icons.bug_report, AppColors.textSecondary);
    case 'ACCOUNT_ISSUE':
      return _CatStyle(Icons.person, const Color(0xFF26A69A));
    default:
      return _CatStyle(Icons.help_outline, AppColors.textMuted);
  }
}
