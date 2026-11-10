import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/network/socket_service.dart';
import '../../../quick_services/data/models/quick_service_history_model.dart';
import '../../../quick_services/presentation/providers/quick_services_booking_provider.dart';
import 'package:intl/intl.dart';

class QuickServicesHistoryView extends ConsumerStatefulWidget {
  const QuickServicesHistoryView({super.key});

  @override
  ConsumerState<QuickServicesHistoryView> createState() => _QuickServicesHistoryViewState();
}

class _QuickServicesHistoryViewState extends ConsumerState<QuickServicesHistoryView> with WidgetsBindingObserver {
  final List<String> _filters = ['All', 'Completed', 'Cancelled', 'Scheduled'];
  String _selectedFilter = 'All';
  StreamSubscription? _socketSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final socketService = ref.read(socketServiceProvider);
    if (!socketService.isConnected) {
      socketService.connect();
    }
    _socketSub = socketService.onQuickServiceEvent.listen((_) {
      if (mounted) {
        ref.invalidate(quickServicesHistoryProvider);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      ref.invalidate(quickServicesHistoryProvider);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _socketSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(quickServicesHistoryProvider);

    if (historyState.isLoading && historyState.bookings.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryGold));
    }

    if (historyState.error != null && historyState.bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.textMuted, size: 48),
            const SizedBox(height: 12),
            Text('Failed to load quick services', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.read(quickServicesHistoryProvider.notifier).load(),
              child: const Text('Retry', style: TextStyle(color: AppColors.primaryGold)),
            ),
          ],
        ),
      );
    }

    final bookings = historyState.bookings;

    return Column(
      children: [
        // ── Filter Tabs ────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedFilter = filter;
                      });
                      ref.read(quickServicesHistoryProvider.notifier).setFilter(filter);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryGold
                            : Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryGold
                              : (Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
                        ),
                      ),
                      child: Text(
                        filter,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: isSelected
                              ? Theme.of(context).scaffoldBackgroundColor
                              : (Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.textSecondary
                                  : AppColors.textSecondaryLight),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // ── Content ────────────────────────────────
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primaryGold,
            onRefresh: () async {
              return ref.read(quickServicesHistoryProvider.notifier).load();
            },
            child: bookings.isEmpty
                ? LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: _buildEmptyState(),
                      ),
                    ),
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: bookings.length + (historyState.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= bookings.length) {
                        if (historyState.hasMore) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            ref.read(quickServicesHistoryProvider.notifier).loadMore();
                          });
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primaryGold,
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }
                      final booking = bookings[index];
                      return _buildHistoryCard(booking);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _selectedFilter == 'Scheduled'
                ? Icons.calendar_month
                : Icons.home_repair_service_outlined,
            color: Theme.of(context).brightness == Brightness.dark ? AppColors.textMuted : AppColors.textMutedLight,
            size: 56,
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == 'All'
                ? 'No services booked yet'
                : 'No ${_selectedFilter.toLowerCase()} services',
            style: AppTextStyles.titleMedium.copyWith(color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : AppColors.textSecondaryLight),
          ),
          const SizedBox(height: 6),
          Text(
            'Your quick services history will appear here',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 32,
            width: 170,
            child: ElevatedButton(
              onPressed: () {
                context.pushNamed(RouteNames.quickServicesList);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: AppColors.backgroundDark,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                'Book a Service',
                style: AppTextStyles.labelLarge.copyWith(
                  fontSize: 12,
                  color: AppColors.backgroundDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getServiceIcon(String category, String title) {
    final t = title.toLowerCase();
    if (t.contains('bike mechanic')) return Icons.two_wheeler;
    if (t.contains('truck mechanic')) return Icons.local_shipping;
    if (t.contains('car mechanic')) return Icons.directions_car;
    if (t.contains('bike wash')) return Icons.two_wheeler;
    if (t.contains('truck wash')) return Icons.local_shipping;
    if (t.contains('car wash')) return Icons.local_car_wash;
    if (t.contains('mobile')) return Icons.smartphone;
    if (t.contains('laptop') || t.contains('computer')) return Icons.laptop;
    if (t.contains('printer') || t.contains('scanner')) return Icons.print;
    if (t.contains('home cleaning') || t.contains('cleaning')) return Icons.cleaning_services;
    if (t.contains('pest')) return Icons.pest_control;
    if (t.contains('garden')) return Icons.yard;
    if (t.contains('plumb')) return Icons.plumbing;
    if (t.contains('carpent')) return Icons.carpenter;
    if (t.contains('paint')) return Icons.format_paint;
    if (t.contains('laundry')) return Icons.local_laundry_service;
    if (t.contains('beauty') || t.contains('wellness')) return Icons.spa;
    if (t.contains('security') || t.contains('bouncer')) return Icons.security;
    if (t.contains('hire')) return Icons.person_search;
    if (t.contains('refrigerator')) return Icons.kitchen;
    if (t.contains('air conditioner') || t.contains('conditioner') || t.contains('ac')) return Icons.ac_unit;
    if (t.contains('washing machine')) return Icons.local_laundry_service;
    if (t.contains('television') || t.contains('tv')) return Icons.tv;
    if (t.contains('fan')) return Icons.air;
    if (t.contains('appliance')) return Icons.ac_unit;
    if (t.contains('commercial electric') || t.contains('lift') || t.contains('elevator')) return Icons.elevator;
    if (t.contains('electric')) return Icons.electrical_services;
    if (t.contains('mechanic')) return Icons.handyman;
    if (t.contains('wash')) return Icons.local_car_wash;
    if (t == 'car') return Icons.directions_car;
    if (t == 'bike') return Icons.two_wheeler;
    if (t == 'truck') return Icons.local_shipping;
    
    final c = category.toLowerCase();
    switch (c) {
      case 'home services': return Icons.home_repair_service;
      case 'pc & mobile repair': return Icons.computer;
      case 'vehicle mechanic': return Icons.handyman;
      case 'vehicle wash': return Icons.local_car_wash;
      case 'electrical repair': return Icons.electrical_services;
      case 'appliance repair': return Icons.ac_unit;
    }
    
    return Icons.home_repair_service;
  }


  static bool _isInternalOptionKey(String rawKey) {
    final key = rawKey.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    const internalKeys = {
      'isvalidated',
      'validationpin',
      'beautytreatmentssubtotal',
      'startedat',
      'endedat',
      'finalhourlycost',
      'finaldurationhrs',
      'durationhours',
      'durationminutes',
      'hourlyrate',
      'serviceamount',
      'alreadypaid',
      'upfrontfee',
      'materialcost',
      'issuedescription',
      'requirements',
      'comments',
      'comment',
      'subtotal',
      'tax',
      'total',
      'servicemode',
      'vehicleservicemode',
    };
    return internalKeys.contains(key);
  }

  Widget _buildHistoryCard(QuickServiceHistoryModel booking) {
    final status = booking.status.toUpperCase();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    Color statusBg;
    Color statusText;
    String displayStatus;

    if (status == 'COMPLETED') {
      statusBg = AppColors.success.withValues(alpha: 0.1);
      statusText = AppColors.success;
      displayStatus = 'Completed';
    } else if (status == 'CANCELLED' || status == 'CANCELED') {
      statusBg = AppColors.error.withValues(alpha: 0.1);
      statusText = AppColors.error;
      displayStatus = 'Cancelled';
    } else if (status == 'AWAITING_PAYMENT' ||
        (status != 'COMPLETED' &&
            status != 'CANCELLED' &&
            status != 'CANCELED' &&
            (booking.options['endedAt'] != null || booking.options['finalHourlyCost'] != null))) {
      statusBg = Colors.orange.withValues(alpha: 0.15);
      statusText = Colors.orange;
      displayStatus = 'Awaiting Payment';
    } else if (status == 'IN_PROGRESS' ||
        (status != 'COMPLETED' &&
            status != 'CANCELLED' &&
            status != 'CANCELED' &&
            booking.options['startedAt'] != null &&
            booking.options['endedAt'] == null)) {
      statusBg = Colors.blue.withValues(alpha: 0.15);
      statusText = Colors.blue;
      displayStatus = 'In Progress';
    } else if (status == 'ASSIGNED' || status == 'WORKER_ASSIGNED' || status == 'SELF_ASSIGNED') {
      statusBg = AppColors.primaryGold.withValues(alpha: 0.15);
      statusText = AppColors.primaryGold;
      displayStatus = 'Assigned';
    } else {
      statusBg = AppColors.primaryGold.withValues(alpha: 0.1);
      statusText = AppColors.primaryGold;
      displayStatus = 'Scheduled';
    }

    final bool isWorkEnded = (status == 'AWAITING_PAYMENT' ||
        status == 'COMPLETED' ||
        booking.options['endedAt'] != null ||
        booking.options['finalHourlyCost'] != null);
    
    double initialPaid = (booking.upfrontFee + booking.materialCost - booking.discountAmount).clamp(0.0, double.infinity);
    if (booking.serviceCategory.toLowerCase().contains('beauty') || booking.serviceCategory.toLowerCase().contains('wellness')) {
      double addonsTotal = 0.0;
      for (var addon in booking.addOns) {
        if (addon is Map) {
          int count = int.tryParse(addon['count']?.toString() ?? '1') ?? 1;
          double price = double.tryParse((addon['price'] ?? addon['pricePerUnit'])?.toString() ?? '0.0') ?? 0.0;
          addonsTotal += (price * count);
        }
      }
      initialPaid = addonsTotal + booking.upfrontFee + booking.materialCost;
    }

    final rawService = double.tryParse(booking.options['serviceAmount']?.toString() ?? '') ??
        double.tryParse(booking.options['finalHourlyCost']?.toString() ?? '');
    final double serviceAmount = (rawService != null && isWorkEnded) ? double.parse(rawService.toStringAsFixed(2)) : 0.0;
    final double totalAmount = initialPaid + serviceAmount;

    final String title = booking.displayTitle;

    return GestureDetector(
      onTap: () async {
        HapticFeedback.selectionClick();
        await context.pushNamed(RouteNames.quickServiceHistoryDetails, extra: booking);
        if (mounted) {
          ref.invalidate(quickServicesHistoryProvider);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Header Row ──────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getServiceIcon(booking.serviceCategory, title),
                      color: AppColors.primaryGold,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      displayStatus,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: statusText,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ── Date & Price Row ────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 15,
                        color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('dd MMM yyyy, h:mm a').format(booking.bookingDate),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '€${totalAmount.toStringAsFixed(2)}',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.primaryGold,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),

              // ── Payment Due / Paid Breakdown ────────────
              if (isWorkEnded && serviceAmount > 0) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Online Paid: ',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '€${initialPaid.toStringAsFixed(2)}',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 1,
                        height: 14,
                        color: isDark ? Colors.grey[700] : Colors.grey[300],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Service: ',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '€${serviceAmount.toStringAsFixed(2)}',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: status == 'AWAITING_PAYMENT' ? AppColors.error : Colors.green,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (status == 'AWAITING_PAYMENT' ? AppColors.error : Colors.green).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              status == 'AWAITING_PAYMENT' ? 'Due' : 'Paid',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: status == 'AWAITING_PAYMENT' ? AppColors.error : Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

