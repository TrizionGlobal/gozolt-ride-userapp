import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';

class QuickServicesHistoryView extends StatefulWidget {
  const QuickServicesHistoryView({super.key});

  @override
  State<QuickServicesHistoryView> createState() => _QuickServicesHistoryViewState();
}

class _QuickServicesHistoryViewState extends State<QuickServicesHistoryView> {
  final List<String> _filters = ['All', 'Completed', 'Cancelled', 'Scheduled'];
  String _selectedFilter = 'All';

  // Mock data for Quick Services History
  final List<Map<String, dynamic>> _mockBookings = [
    {
      'id': 'GZT-QS-1029',
      'title': 'Home Cleaning',
      'provider': 'CleanPro Services',
      'email': 'contact@cleanpro.com',
      'icon': Icons.cleaning_services,
      'status': 'Completed',
      'date': '15 Sep 2026',
      'time': '5:00 PM',
      'location': '123 Main St, Apartment 4B',
      'options': {
        'Cleaning Type': 'Deep Clean',
        'Bedrooms': '3',
        'Bathrooms': '2',
        'Pets': 'Yes',
      },
      'addOns': [
        {'name': 'Window Cleaning', 'price': 15.00},
        {'name': 'Oven Cleaning', 'price': 20.00},
      ],
      'baseRate': 50.00,
      'materialsFee': 35.00,
      'taxes': 5.75,
      'paymentMethod': 'Credit Card (**** 1234)',
      'walletAmountUsed': 0.00,
      'total': 90.75,
    },
    {
      'id': 'GZT-QS-1030',
      'title': 'Plumbing Repair',
      'provider': 'QuickFix Plumbing',
      'email': 'support@quickfix.com',
      'icon': Icons.plumbing,
      'status': 'Scheduled',
      'date': '18 Sep 2026',
      'time': '10:00 AM',
      'location': '45 Oak Lane, Villa 1',
      'options': {
        'Issue Type': 'Water Leakage',
        'Severity': 'High',
        'Property Type': 'Villa',
      },
      'addOns': [],
      'baseRate': 40.00,
      'materialsFee': 0.00,
      'taxes': 5.00,
      'paymentMethod': 'Credit Card (**** 1234)',
      'walletAmountUsed': 0.00,
      'total': 45.00,
    },
    {
      'id': 'GZT-QS-1031',
      'title': 'Pest Control',
      'provider': 'BugBusters Inc.',
      'email': 'hello@bugbusters.com',
      'icon': Icons.bug_report,
      'status': 'Cancelled',
      'date': '12 Sep 2026',
      'time': '2:00 PM',
      'location': '78 Pine Road',
      'options': {
        'Pest Type': 'Termites, Ants',
        'Property Type': 'Independent House',
        'Affected Areas': 'Kitchen, Garden, Living Room',
      },
      'addOns': [
        {'name': 'Organic Treatment', 'price': 25.00},
      ],
      'baseRate': 100.00,
      'materialsFee': 25.00,
      'taxes': 15.00,
      'paymentMethod': 'PayPal',
      'walletAmountUsed': 10.00,
      'total': 130.00,
    },
    {
      'id': 'GZT-QS-1032',
      'title': 'Appliance Repair',
      'provider': 'Appliance Master',
      'email': 'service@appliancemaster.com',
      'icon': Icons.kitchen,
      'status': 'Completed',
      'date': '05 Sep 2026',
      'time': '1:30 PM',
      'location': '99 Maple Ave',
      'options': {
        'Appliance': 'Washing Machine',
        'Brand': 'Samsung',
        'Issue': 'Not spinning properly',
      },
      'addOns': [],
      'baseRate': 70.00,
      'materialsFee': 25.00,
      'taxes': 10.50,
      'paymentMethod': 'Cash on Delivery',
      'walletAmountUsed': 20.00, // Show GoCoins discount usage here
      'total': 85.50,
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Filter the mock bookings
    final filteredBookings = _mockBookings.where((booking) {
      if (_selectedFilter == 'All') return true;
      return booking['status'] == _selectedFilter;
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
                context.goNamed(RouteNames.home);
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

  Widget _buildHistoryCard(Map<String, dynamic> booking) {
    final status = booking['status'] as String;
    
    Color statusBg;
    Color statusText;

    switch (status) {
      case 'Completed':
        statusBg = AppColors.success.withValues(alpha: 0.1);
        statusText = AppColors.success;
        break;
      case 'Cancelled':
        statusBg = AppColors.error.withValues(alpha: 0.1);
        statusText = AppColors.error;
        break;
      case 'Scheduled':
      default:
        statusBg = AppColors.primaryGold.withValues(alpha: 0.1);
        statusText = AppColors.primaryGold;
        break;
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
                        booking['icon'] as IconData,
                        color: AppColors.primaryGold,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking['title'] as String,
                          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Service ID: ${booking['id']}',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
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
                    status,
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
                      '${booking['date']} at ${booking['time']}',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                Text(
                  '€${(booking['total'] as double).toStringAsFixed(2)}',
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
