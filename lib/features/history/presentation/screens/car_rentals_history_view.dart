import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../car_rental/data/datasources/car_rental_remote_datasource.dart';
import '../../../../core/providers/dio_provider.dart';
import 'car_rental_booking_details_screen.dart';

final carRentalHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.read(dioProvider);
  final datasource = CarRentalRemoteDatasource(dio);
  return datasource.getMyBookings();
});

class CarRentalsHistoryView extends ConsumerStatefulWidget {
  const CarRentalsHistoryView({super.key});

  @override
  ConsumerState<CarRentalsHistoryView> createState() => _CarRentalsHistoryViewState();
}

class _CarRentalsHistoryViewState extends ConsumerState<CarRentalsHistoryView> {
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'Pending', 'Confirmed', 'Active', 'Completed', 'Cancelled'];

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(carRentalHistoryProvider);

    return historyAsync.when(
      data: (bookings) {
        if (bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.car_rental, color: AppColors.textMuted, size: 56),
                const SizedBox(height: 16),
                Text(
                  'No car rentals yet',
                  style: AppTextStyles.titleMedium.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your rental history will appear here',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          );
        }

        // Apply Filter
        final filteredBookings = bookings.where((booking) {
          final status = booking['status'] as String;
          if (_selectedFilter == 'All') return true;
          if (_selectedFilter == 'Pending') return status == 'PENDING_PAYMENT' || status == 'PENDING_APPROVAL';
          if (_selectedFilter == 'Confirmed') return status == 'CONFIRMED';
          if (_selectedFilter == 'Active') return status == 'ACTIVE';
          if (_selectedFilter == 'Completed') return status == 'COMPLETED';
          if (_selectedFilter == 'Cancelled') return status == 'CANCELLED' || status == 'REJECTED';
          return true;
        }).toList();

        return RefreshIndicator(
          color: AppColors.primaryGold,
          onRefresh: () => ref.refresh(carRentalHistoryProvider.future),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                                  : (Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : AppColors.textSecondaryLight),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              
              // Filtered List
              Expanded(
                child: filteredBookings.isEmpty
                    ? Center(
                        child: Text(
                          'No $_selectedFilter car rentals found',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                        itemCount: filteredBookings.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final booking = filteredBookings[index];
                          final vehicle = booking['vehicle'];
              final supplier = vehicle['supplier'];
              final status = booking['status'] as String;
              final startDate = DateTime.parse(booking['startDate']);
              final endDate = DateTime.parse(booking['endDate']);
              final grandTotal = booking['grandTotal'];
              final pickupLocation = booking['pickupLocation'] ?? '';
              
              final vehicleName = vehicle['name'] ?? 'Rental Car';
              final rawCategory = vehicle['category'] as String?;
              final formattedCategory = rawCategory != null 
                  ? rawCategory.split('_').map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' : '').join(' ')
                  : '';
              final title = formattedCategory.isNotEmpty ? '$vehicleName ($formattedCategory)' : vehicleName;
              
              final images = vehicle['images'] as List<dynamic>?;
              final imageUrl = (images != null && images.isNotEmpty) ? images.first.toString() : null;

              final isDark = Theme.of(context).brightness == Brightness.dark;
              final primaryTextColor = isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;

              Color statusColor = AppColors.textSecondary;
              Color statusBg = isDark ? AppColors.textSecondary.withOpacity(0.2) : AppColors.textSecondaryLight.withOpacity(0.2);
              
              // Pending → orange
              if (status == 'PENDING_APPROVAL' || status == 'PENDING_PAYMENT') {
                statusColor = isDark ? Colors.orange.shade400 : Colors.orange.shade800;
                statusBg = isDark ? Colors.orange.withOpacity(0.15) : Colors.orange.shade50;
              }
              // Confirmed (supplier accepted, not yet handed over) → blue
              if (status == 'CONFIRMED') {
                statusColor = isDark ? Colors.blue.shade400 : Colors.blue.shade700;
                statusBg = isDark ? Colors.blue.withOpacity(0.15) : Colors.blue.shade50;
              }
              // Active (car handed over) → green
              if (status == 'ACTIVE') {
                statusColor = isDark ? Colors.green.shade400 : Colors.green.shade700;
                statusBg = isDark ? Colors.green.withOpacity(0.15) : Colors.green.shade50;
              }
              // Completed → teal/grey
              if (status == 'COMPLETED') {
                statusColor = isDark ? Colors.teal.shade300 : Colors.teal.shade700;
                statusBg = isDark ? Colors.teal.withOpacity(0.15) : Colors.teal.shade50;
              }
              // Cancelled or Rejected → red
              if (status == 'CANCELLED' || status == 'REJECTED') {
                statusColor = isDark ? Colors.red.shade400 : AppColors.error;
                statusBg = isDark ? Colors.red.withOpacity(0.15) : Colors.red.shade50;
              }

              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CarRentalBookingDetailsScreen(bookingId: booking['id']),
                    )
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Image & Basic Info
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Car Image
                            Container(
                              width: 80,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppColors.backgroundLight,
                                borderRadius: BorderRadius.circular(8),
                                image: imageUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(imageUrl),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: imageUrl == null
                                  ? const Icon(Icons.directions_car_filled, color: AppColors.primaryGold, size: 32)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            
                            // Title & Supplier
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: AppTextStyles.titleMedium.copyWith(color: primaryTextColor, fontWeight: FontWeight.bold),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.business, size: 14, color: AppColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          supplier?['companyName'] ?? 'Supplier',
                                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: statusBg,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          _formatStatus(status),
                                          style: AppTextStyles.labelSmall.copyWith(color: statusColor, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Text(
                                        '€${double.parse(grandTotal.toString()).toStringAsFixed(2)}',
                                        style: AppTextStyles.titleMedium.copyWith(color: AppColors.primaryGold, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Divider
                      Divider(height: 1, color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
                      
                      // Footer: Dates and Location
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16, color: AppColors.textMuted),
                                const SizedBox(width: 8),
                                Text(
                                  '${DateFormat('MMM d').format(startDate)} - ${DateFormat('MMM d, yyyy').format(endDate)}',
                                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                            if (pickupLocation.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 16, color: AppColors.textMuted),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      pickupLocation,
                                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
},
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryGold)),
      error: (e, st) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.textMuted, size: 48),
            const SizedBox(height: 12),
            Text('Failed to load rentals', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.refresh(carRentalHistoryProvider),
              child: const Text('Retry', style: TextStyle(color: AppColors.primaryGold)),
            ),
          ],
        ),
      ),
    );
  }

  String _formatStatus(String status) {
    if (status == 'PENDING_APPROVAL') return 'Pending';
    if (status == 'PENDING_PAYMENT') return 'Pending Payment';
    if (status == 'CONFIRMED') return 'Confirmed';
    if (status == 'ACTIVE') return 'Active';
    if (status == 'COMPLETED') return 'Completed';
    if (status == 'CANCELLED') return 'Cancelled';
    if (status == 'REJECTED') return 'Supplier Rejected';
    return status.replaceAll('_', ' ');
  }
}
