import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../data/models/support_ticket.dart';
import '../providers/support_providers.dart';

class TicketListScreen extends ConsumerWidget {
  const TicketListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketState = ref.watch(supportTicketsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: RefreshIndicator(
        color: AppColors.primaryGold,
        backgroundColor: AppColors.surfaceDark,
        onRefresh: () => ref.read(supportTicketsProvider.notifier).load(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          slivers: [
            // ── Gold Header ──────────────────────────
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
                    padding: const EdgeInsets.fromLTRB(16, 8, 20, 20),
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
                                  .withValues(alpha: 0.15),
                            ),
                            child: const Icon(Icons.arrow_back,
                                color: AppColors.backgroundDark, size: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Support',
                          style: AppTextStyles.headlineSmall.copyWith(
                            color: AppColors.backgroundDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Content ──────────────────────────────
            if (ticketState.isLoading && ticketState.tickets.isEmpty)
              SliverToBoxAdapter(
                child: buildShimmerList(
                  itemBuilder: () => const ShimmerTicketCard(),
                  count: 3,
                ),
              )
            else if (ticketState.error != null && ticketState.tickets.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.textMuted, size: 48),
                      const SizedBox(height: 12),
                      Text('Failed to load tickets',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textSecondary)),
                      TextButton(
                        onPressed: () =>
                            ref.read(supportTicketsProvider.notifier).load(),
                        child: const Text('Retry',
                            style: TextStyle(color: AppColors.primaryGold)),
                      ),
                    ],
                  ),
                ),
              )
            else if (ticketState.tickets.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.support_agent,
                          color: AppColors.textMuted, size: 56),
                      const SizedBox(height: 16),
                      Text('No support tickets',
                          style: AppTextStyles.titleMedium
                              .copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      Text("Need help? We're here for you.",
                          style: AppTextStyles.bodySmall),
                      const SizedBox(height: 20),
                      OutlinedButton.icon(
                        onPressed: () =>
                            context.pushNamed(RouteNames.createTicket),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Create a Ticket'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryGold,
                          side:
                              const BorderSide(color: AppColors.primaryGold),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final ticket = ticketState.tickets[index];
                      return _TicketCard(
                        ticket: ticket,
                        onTap: () => context.pushNamed(
                          RouteNames.ticketDetail,
                          extra: ticket.id,
                        ),
                      );
                    },
                    childCount: ticketState.tickets.length,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: ticketState.tickets.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => context.pushNamed(RouteNames.createTicket),
              backgroundColor: AppColors.primaryGold,
              child: const Icon(Icons.add,
                  color: AppColors.backgroundDark, size: 28),
            )
          : null,
    );
  }
}

// ── Ticket Card ──────────────────────────────────────────
class _TicketCard extends StatelessWidget {
  final SupportTicket ticket;
  final VoidCallback? onTap;

  const _TicketCard({required this.ticket, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cat = _categoryStyle(ticket.category);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cat.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(cat.icon, color: cat.color, size: 20),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subject + status
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ticket.subject,
                          style: AppTextStyles.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusBadge(status: ticket.status),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Preview text
                  Text(
                    ticket.replies.isNotEmpty
                        ? ticket.replies.last.message
                        : ticket.description,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Date
                  Text(
                    'Created ${_formatTimeAgo(ticket.createdAt)}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays == 1) return 'yesterday';
      if (diff.inDays < 7) return '${diff.inDays} days ago';
      if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
      return '${(diff.inDays / 30).floor()} months ago';
    } catch (_) {
      return '';
    }
  }
}

// ── Status Badge ─────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (Color borderColor, Color textColor, String label) =
        _statusStyle(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 9,
        ),
      ),
    );
  }

  (Color, Color, String) _statusStyle(String status) {
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
}

// ── Category Style Helper ────────────────────────────────
class _CategoryStyle {
  final IconData icon;
  final Color color;
  const _CategoryStyle(this.icon, this.color);
}

_CategoryStyle _categoryStyle(String category) {
  switch (category) {
    case 'RIDE_ISSUE':
      return _CategoryStyle(Icons.directions_car, AppColors.info);
    case 'PAYMENT_ISSUE':
      return _CategoryStyle(Icons.credit_card, AppColors.success);
    case 'DRIVER_BEHAVIOR':
      return _CategoryStyle(Icons.person_off, AppColors.warning);
    case 'SAFETY_CONCERN':
      return _CategoryStyle(Icons.shield, AppColors.error);
    case 'LOST_ITEM':
      return _CategoryStyle(Icons.shopping_bag, const Color(0xFFB388FF));
    case 'APP_BUG':
      return _CategoryStyle(Icons.bug_report, AppColors.textSecondary);
    case 'ACCOUNT_ISSUE':
      return _CategoryStyle(Icons.person, const Color(0xFF26A69A));
    case 'OTHER':
      return _CategoryStyle(Icons.help_outline, AppColors.textMuted);
    default:
      return _CategoryStyle(Icons.help_outline, AppColors.textMuted);
  }
}
