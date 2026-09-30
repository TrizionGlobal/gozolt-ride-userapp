import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../../quick_services/data/models/quick_service_history_model.dart';
import '../../../quick_services/presentation/providers/quick_services_booking_provider.dart';
import 'package:intl/intl.dart';

class QuickServicesHistoryView extends ConsumerStatefulWidget {
  const QuickServicesHistoryView({super.key});

  @override
  ConsumerState<QuickServicesHistoryView> createState() => _QuickServicesHistoryViewState();
}

class _QuickServicesHistoryViewState extends ConsumerState<QuickServicesHistoryView> {
  final List<String> _filters = ['All', 'Completed', 'Cancelled', 'Scheduled'];
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(quickServicesHistoryProvider);

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryGold)),
      error: (err, stack) => Center(child: Text('Error: $err', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error))),
      data: (bookings) {
        // Filter the dynamic bookings
        final filteredBookings = bookings.where((booking) {
          if (_selectedFilter == 'All') return true;
          if (_selectedFilter == 'Scheduled' && booking.status == 'PENDING') return true;
          return booking.status.toUpperCase() == _selectedFilter.toUpperCase();
        }).toList();

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
          child: filteredBookings.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: filteredBookings.length,
                  itemBuilder: (context, index) {
                    final booking = filteredBookings[index];
                    return _buildHistoryCard(booking);
                  },
                ),
        ),
      ],
    );
    },
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
            color: AppColors.textMuted,
            size: 56,
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == 'All'
                ? 'No services booked yet'
                : 'No ${_selectedFilter.toLowerCase()} services',
            style: AppTextStyles.titleMedium.copyWith(color: AppColors.textSecondary),
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
    switch (t) {
      case 'home cleaning': return Icons.cleaning_services;
      case 'pest control': return Icons.pest_control;
      case 'gardening': return Icons.yard;
      case 'plumbing': return Icons.plumbing;
      case 'carpenter': return Icons.carpenter;
      case 'mobile': return Icons.smartphone;
      case 'laptop/computer': return Icons.laptop;
      case 'printer / scanner': return Icons.print;
      case 'car': return Icons.directions_car;
      case 'bike': return Icons.two_wheeler;
      case 'truck': return Icons.local_shipping;
      case 'refrigerator': return Icons.kitchen;
      case 'air conditioner': return Icons.ac_unit;
      case 'washing machine': return Icons.local_laundry_service;
      case 'television': return Icons.tv;
      case 'fan': return Icons.air;
      case 'appliance repair': return Icons.ac_unit;
      case 'electrical repair': return Icons.electrical_services;
      case 'vehicle mechanic': return Icons.handyman;
      case 'vehicle wash': return Icons.local_car_wash;
      case 'pc & mobile repair': return Icons.computer;
    }
    
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

  Widget _buildHistoryCard(QuickServiceHistoryModel booking) {
    final status = booking.status.toUpperCase();
    
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
    } else {
        statusBg = AppColors.primaryGold.withValues(alpha: 0.1);
        statusText = AppColors.primaryGold;
        displayStatus = 'Scheduled';
    }

    String subtitle = booking.serviceCategory;
    final validAddOns = booking.addOns.where((a) => a is Map).toList();
    
    if (validAddOns.isNotEmpty) {
      final names = validAddOns.map((a) => (a as Map)['name']?.toString() ?? 'Unknown Add-on').toList();
      if (names.length <= 2) {
        subtitle = names.join(', ');
      } else {
        subtitle = '${names.take(2).join(', ')} +${names.length - 2} more';
      }
    } else if (booking.options.isNotEmpty) {
      final firstVal = booking.options.values.first;
      if (firstVal is List && firstVal.isNotEmpty) {
        if (firstVal.first is Map) {
          final firstItem = firstVal.first as Map;
          final parts = [if (firstItem['Make'] != null) firstItem['Make'], if (firstItem['Model'] != null) firstItem['Model'], if (firstItem['Type'] != null && firstItem['Make'] == null) firstItem['Type']].where((e) => e != null);
          subtitle = parts.isNotEmpty ? parts.join(' ') : 'Multiple items';
          if (firstVal.length > 1) subtitle += ' +${firstVal.length - 1} more';
        } else {
          subtitle = firstVal.first.toString();
          if (firstVal.length > 1) subtitle += ' +${firstVal.length - 1} more';
        }
      } else {
        subtitle = firstVal.toString();
      }
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        context.pushNamed(RouteNames.quickServiceHistoryDetails, extra: booking);
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getServiceIcon(booking.serviceCategory, booking.serviceTitle),
                        color: AppColors.primaryGold,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.serviceTitle,
                          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (booking.addOns.isNotEmpty || booking.options.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    displayStatus,
                    style: AppTextStyles.labelSmall.copyWith(color: statusText, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: AppColors.textMuted),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('dd MMM yyyy, h:mm a').format(booking.bookingDate),
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                Text(
                  '€${booking.totalAmount.toStringAsFixed(2)}',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.primaryGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ));
  }
}
