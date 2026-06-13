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
import '../../data/models/create_ticket_request.dart';
import '../providers/support_providers.dart';

class CreateTicketScreen extends ConsumerStatefulWidget {
  final String? rideId;
  const CreateTicketScreen({super.key, this.rideId});

  @override
  ConsumerState<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends ConsumerState<CreateTicketScreen> {
  String? _selectedCategory;
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _isFormValid =>
      _selectedCategory != null &&
      _subjectController.text.trim().isNotEmpty &&
      _descriptionController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Try to find linked ride data
    RideHistoryItem? linkedRide;
    if (widget.rideId != null) {
      final historyState = ref.watch(rideHistoryProvider);
      final match =
          historyState.rides.where((r) => r.id == widget.rideId);
      if (match.isNotEmpty) linkedRide = match.first;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ─────────────────────────────────
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
                        onTap: () => context.pop(),
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
                      Text(
                        'Report an Issue',
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

          // ── Form ───────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Linked ride card
                if (linkedRide != null) ...[
                  _linkedRideCard(linkedRide),
                  const SizedBox(height: 20),
                ] else if (widget.rideId != null) ...[
                  _minimalRideCard(widget.rideId!),
                  const SizedBox(height: 20),
                ],

                // Category selector
                Text("What's this about?",
                    style: AppTextStyles.labelLarge
                        .copyWith(color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight, fontSize: 13)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _showCategorySheet(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.inputDark : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedCategory != null
                            ? AppColors.primaryGold.withOpacity(0.3)
                            : (isDark ? AppColors.borderDark : AppColors.borderLight),
                      ),
                      boxShadow: isDark
                          ? null
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Row(
                      children: [
                        if (_selectedCategory != null) ...[
                          _categoryChip(_selectedCategory!),
                          const Spacer(),
                        ] else
                          Expanded(
                            child: Text(
                              'Select a category',
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: isDark ? AppColors.textMuted : AppColors.textMutedLight),
                            ),
                          ),
                        Icon(Icons.keyboard_arrow_down,
                            color: isDark ? AppColors.textMuted : AppColors.textMutedLight, size: 22),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Subject
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Brief summary',
                        style: AppTextStyles.labelLarge.copyWith(
                            color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight, fontSize: 13)),
                    Text(
                      '${_subjectController.text.length}/200',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: isDark ? AppColors.textMuted : AppColors.textMutedLight, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _subjectController,
                  maxLength: 200,
                  onChanged: (_) => setState(() {}),
                  style: AppTextStyles.bodyMedium.copyWith(color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight),
                  decoration: InputDecoration(
                    hintText: 'e.g., Driver took a wrong route',
                    hintStyle: AppTextStyles.bodyMedium
                        .copyWith(color: isDark ? AppColors.textMuted : AppColors.textMutedLight),
                    filled: true,
                    fillColor: isDark ? AppColors.inputDark : AppColors.surfaceLight,
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.primaryGold),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 20),

                // Description
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Describe your issue',
                        style: AppTextStyles.labelLarge.copyWith(
                            color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight, fontSize: 13)),
                    Text(
                      '${_descriptionController.text.length}/2000',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: isDark ? AppColors.textMuted : AppColors.textMutedLight, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  maxLength: 2000,
                  maxLines: 5,
                  onChanged: (_) => setState(() {}),
                  style: AppTextStyles.bodyMedium.copyWith(color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight),
                  decoration: InputDecoration(
                    hintText:
                        'Please provide as much detail as possible. Include any relevant information like time, location, or specifics of what happened...',
                    hintStyle: AppTextStyles.bodyMedium
                        .copyWith(color: isDark ? AppColors.textMuted : AppColors.textMutedLight),
                    hintMaxLines: 3,
                    filled: true,
                    fillColor: isDark ? AppColors.inputDark : AppColors.surfaceLight,
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.primaryGold),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 28),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _isFormValid && !_isSubmitting ? _submit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: AppColors.backgroundDark,
                      disabledBackgroundColor:
                          AppColors.primaryGold.withOpacity(0.3),
                      padding: EdgeInsets.zero,
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.backgroundDark),
                            )
                          : Text('Submit', style: AppTextStyles.button),
                    ),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Linked Ride Card ───────────────────────────────────
  Widget _linkedRideCard(RideHistoryItem ride) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Related Ride',
              style: AppTextStyles.labelSmall
                  .copyWith(color: isDark ? AppColors.textMuted : AppColors.textMutedLight, fontSize: 10)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                      width: 1.5, height: 16, color: isDark ? AppColors.borderDark : AppColors.borderLight),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ride.pickupAddress,
                        style: AppTextStyles.bodySmall.copyWith(
                            color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 10),
                    Text(ride.dropoffAddress,
                        style: AppTextStyles.bodySmall.copyWith(
                            color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                _formatDate(ride.createdAt),
                style: AppTextStyles.labelSmall
                    .copyWith(color: isDark ? AppColors.textMuted : AppColors.textMutedLight, fontSize: 10),
              ),
              const Spacer(),
              Text(
                '\u20AC${ride.displayFare.toStringAsFixed(2)}',
                style: AppTextStyles.titleSmall
                    .copyWith(color: isDark ? AppColors.primaryGold : AppColors.primaryGoldDark, fontSize: 12),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  ride.displayVehicle,
                  style: AppTextStyles.labelSmall
                      .copyWith(fontSize: 9, color: isDark ? AppColors.textMuted : AppColors.textMutedLight),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _minimalRideCard(String rideId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          Icon(Icons.directions_car,
              color: isDark ? AppColors.textMuted : AppColors.textMutedLight, size: 18),
          const SizedBox(width: 8),
          Text('Related Ride: ',
              style: AppTextStyles.bodySmall
                  .copyWith(color: isDark ? AppColors.textMuted : AppColors.textMutedLight)),
          Expanded(
            child: Text(
                rideId.length > 8 ? '#${rideId.substring(0, 8)}' : '#$rideId',
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.primaryGold)),
          ),
        ],
      ),
    );
  }

  // ── Category Chip ──────────────────────────────────────
  Widget _categoryChip(String category) {
    final info = _categoryInfo(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: info.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(info.icon, color: info.color, size: 14),
          const SizedBox(width: 6),
          Text(
            info.label,
            style: AppTextStyles.labelSmall.copyWith(
              color: info.color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ── Category Bottom Sheet ──────────────────────────────
  void _showCategorySheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text("What's this about?",
                  style: AppTextStyles.headlineSmall.copyWith(
                      color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight)),
              const SizedBox(height: 16),
              ..._allCategories.map((cat) => GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedCategory = cat.value);
                      Navigator.pop(context);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedCategory == cat.value
                            ? cat.color.withOpacity(0.08)
                            : (isDark ? AppColors.cardDark : AppColors.cardLight),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedCategory == cat.value
                              ? cat.color.withOpacity(0.3)
                              : (isDark ? AppColors.borderDark : AppColors.borderLight),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: cat.color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(cat.icon,
                                color: cat.color, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(cat.label,
                                    style: AppTextStyles.titleSmall.copyWith(
                                        color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight)),
                                Text(cat.subtitle,
                                    style: AppTextStyles.bodySmall.copyWith(
                                        color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
                                        fontSize: 11)),
                              ],
                            ),
                          ),
                          if (_selectedCategory == cat.value)
                            const Icon(Icons.check_circle,
                                color: AppColors.primaryGold, size: 20),
                        ],
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // ── Submit ─────────────────────────────────────────────
  Future<void> _submit() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);

    final request = CreateTicketRequest(
      rideId: widget.rideId,
      category: _selectedCategory!,
      subject: _subjectController.text.trim(),
      description: _descriptionController.text.trim(),
    );

    final ticket =
        await ref.read(supportTicketsProvider.notifier).createTicket(request);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (ticket != null) {
      _showSuccessSheet(ticket.id, ticket.shortId);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit ticket. Please try again.'),
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        ),
      );
    }
  }

  void _showSuccessSheet(String ticketId, String shortId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle,
                    color: AppColors.primaryGold, size: 32),
              ),
              const SizedBox(height: 16),
              Text('Ticket Submitted!',
                  style: AppTextStyles.headlineSmall.copyWith(
                      color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight)),
              const SizedBox(height: 8),
              Text(
                "We've received your report and will get back to you as soon as possible.",
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight),
              ),
              const SizedBox(height: 8),
              Text(
                'Ticket #$shortId',
                style: AppTextStyles.titleSmall
                    .copyWith(color: isDark ? AppColors.primaryGold : AppColors.primaryGoldDark),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.pop();
                    context.pushNamed(
                      RouteNames.ticketDetail,
                      extra: ticketId,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    foregroundColor: AppColors.backgroundDark,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('View Ticket',
                      style: AppTextStyles.button),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.pop();
                },
                child: Text('Done',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: isDark ? AppColors.textMuted : AppColors.textMutedLight)),
              ),
            ],
          ),
        ),
      ),
    );
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
}

// ── Category Data ────────────────────────────────────────
class _CategoryOption {
  final String value;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  const _CategoryOption({
    required this.value,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

_CategoryOption _categoryInfo(String category) {
  return _allCategories.firstWhere(
    (c) => c.value == category,
    orElse: () => _allCategories.last,
  );
}

const _allCategories = [
  _CategoryOption(
    value: 'RIDE_ISSUE',
    label: 'Ride Issue',
    subtitle: 'Problems with your ride',
    icon: Icons.directions_car,
    color: AppColors.info,
  ),
  _CategoryOption(
    value: 'PAYMENT_ISSUE',
    label: 'Payment Issue',
    subtitle: 'Billing or payment problems',
    icon: Icons.credit_card,
    color: AppColors.success,
  ),
  _CategoryOption(
    value: 'DRIVER_BEHAVIOR',
    label: 'Driver Behavior',
    subtitle: 'Concerns about your driver',
    icon: Icons.person_off,
    color: AppColors.warning,
  ),
  _CategoryOption(
    value: 'SAFETY_CONCERN',
    label: 'Safety Concern',
    subtitle: 'Safety related issues',
    icon: Icons.shield,
    color: AppColors.error,
  ),
  _CategoryOption(
    value: 'LOST_ITEM',
    label: 'Lost Item',
    subtitle: 'Left something in the car',
    icon: Icons.shopping_bag,
    color: Color(0xFFB388FF),
  ),
  _CategoryOption(
    value: 'APP_BUG',
    label: 'App Bug',
    subtitle: "Something isn't working right",
    icon: Icons.bug_report,
    color: AppColors.textSecondary,
  ),
  _CategoryOption(
    value: 'ACCOUNT_ISSUE',
    label: 'Account Issue',
    subtitle: 'Problems with your account',
    icon: Icons.person,
    color: Color(0xFF26A69A),
  ),
  _CategoryOption(
    value: 'OTHER',
    label: 'Other',
    subtitle: 'Anything else',
    icon: Icons.help_outline,
    color: AppColors.textMuted,
  ),
];
