import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../car_rental/data/datasources/car_rental_remote_datasource.dart';
import '../../../../core/providers/dio_provider.dart';
import '../../../ride/data/datasources/payment_remote_datasource.dart';
import '../../../ride/presentation/widgets/stripe_add_card_sheet.dart';
import 'car_rentals_history_view.dart';
import 'car_rental_cancellation_success_screen.dart';
import 'rental_extension_success_screen.dart';

final carRentalBookingDetailsProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, bookingId) async {
  final dio = ref.read(dioProvider);
  final datasource = CarRentalRemoteDatasource(dio);
  return datasource.getBookingDetails(bookingId);
});

class CarRentalBookingDetailsScreen extends ConsumerWidget {
  final String bookingId;

  const CarRentalBookingDetailsScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDetails = ref.watch(carRentalBookingDetailsProvider(bookingId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Custom Header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFD4A843), Color(0xFFF5C518)],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 20, 20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.backgroundDark.withOpacity(0.15),
                        ),
                        child: const Icon(Icons.arrow_back, color: AppColors.backgroundDark, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Booking Details',
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.backgroundDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          Expanded(
            child: asyncDetails.when(
              data: (booking) {
                final vehicle = booking['vehicle'];
          final supplier = vehicle['supplier'];
          final status = booking['status'] as String;
          final startDate = DateTime.parse(booking['startDate']);
          final endDate = DateTime.parse(booking['endDate']);
          
          final fullBookingId = booking['id'] as String;
          final displayBookingId = fullBookingId.length >= 8 
              ? 'GZ-BKG-${fullBookingId.substring(0, 8).toUpperCase()}'
              : '#GZ-CR-UNKNOWN';

          final vehicleName = vehicle['name'] ?? 'Premium Vehicle';

          final qrDataJson = '''
Booking Reference: $displayBookingId
Vehicle: $vehicleName
Date: ${DateFormat('MMM dd, yyyy').format(startDate)}
Time: ${DateFormat('h:mm a').format(startDate)}

(ID: $fullBookingId)
'''.trim();
          
          return RefreshIndicator(
            color: AppColors.primaryGold,
            onRefresh: () => ref.refresh(carRentalBookingDetailsProvider(bookingId).future),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // QR Code Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white, // QR code needs white background for contrast
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Present this to supplier',
                        style: AppTextStyles.titleMedium.copyWith(color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight),
                      ),
                      const SizedBox(height: 16),
                      QrImageView(
                        data: qrDataJson,
                        version: QrVersions.auto,
                        size: 200.0,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Booking ID: $displayBookingId',
                        style: AppTextStyles.labelLarge.copyWith(color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Status & Dates
                _buildSectionTitle(context, 'Trip Information'),
                const SizedBox(height: 8),
                _buildInfoCard(context, [
                  _buildStatusRow(context, status),
                  _buildInfoRow(context, 'Pickup', DateFormat('MMM d, yyyy - h:mm a').format(startDate)),
                  _buildInfoRow(context, 'Return', DateFormat('MMM d, yyyy - h:mm a').format(endDate)),
                  _buildInfoRow(context, 'Location', booking['pickupLocation'] ?? 'Self Pickup'),
                ]),
                
                const SizedBox(height: 24),
                

                // Vehicle Details
                _buildSectionTitle(context, 'Vehicle Details'),
                const SizedBox(height: 8),
                _buildInfoCard(context, [
                  _buildInfoRow(context, 'Vehicle', vehicle['name'] ?? 'N/A'),
                  _buildInfoRow(context, 'Category', _formatEnumString(vehicle['category'])),
                  _buildInfoRow(context, 'Transmission', _formatEnumString(vehicle['transmission'])),
                  _buildInfoRow(context, 'Fuel', _formatEnumString(vehicle['fuelType'])),
                  _buildInfoRow(context, 'Seats', vehicle['seats']?.toString() ?? 'N/A'),
                  _buildInfoRow(context, 'Luggage', vehicle['luggageCapacity']?.toString() ?? 'N/A'),
                  _buildInfoRow(context, 'A/C', (vehicle['hasAirConditioning'] == true) ? 'Yes' : 'No'),
                ]),
                
                const SizedBox(height: 24),
                
                // Supplier Details
                _buildSectionTitle(context, 'Supplier Details'),
                const SizedBox(height: 8),
                _buildInfoCard(context, [
                  _buildInfoRow(context, 'Company', supplier['companyName']),
                  _buildInfoRow(context, 'Contact', supplier['contactPhone']),
                  _buildInfoRow(context, 'Email', supplier['email']),
                ]),
                
                const SizedBox(height: 24),
                
                // Pricing
                _buildSectionTitle(context, 'Payment Details'),
                const SizedBox(height: 8),
                _buildInfoCard(context, [
                  ...(() {
                    int totalExtensionDays = 0;
                    double totalExtensionCost = 0.0;
                    if (booking['extensionRequests'] != null) {
                      for (var r in (booking['extensionRequests'] as List).where((r) => r['status'] == 'APPROVED')) {
                        final origDate = DateTime.parse(r['originalEndDate']);
                        final newDate = DateTime.parse(r['newEndDate']);
                        totalExtensionDays += (newDate.difference(origDate).inMinutes.abs() / 1440).ceil();
                        totalExtensionCost += double.tryParse(r['additionalCost'].toString()) ?? 0;
                      }
                    }

                    final currentDays = (DateTime.parse(booking['endDate']).difference(DateTime.parse(booking['startDate'])).inMinutes.abs() / 1440).ceil();
                    int originalDays = currentDays - totalExtensionDays;
                    final d = originalDays < 1 ? 1 : originalDays;
                    
                    final vehicleRate = (double.tryParse(vehicle['pricePerDay'].toString()) ?? 0) * d;
                    
                    final rows = <Widget>[
                      _buildInfoRow(context, 'Vehicle Rate', '€${vehicleRate.toStringAsFixed(2)}'),
                    ];

                    if (booking['isFlexible'] == true) {
                      rows.add(_buildInfoRow(context, 'Stay Flexible', '€${double.parse(booking['flexibleTotal'].toString()).toStringAsFixed(2)}'));
                    }

                    if (booking['protectionPackageId'] != null) {
                      final pkg = (vehicle['protectionPackages'] as List?)?.firstWhere(
                        (p) => p['id'] == booking['protectionPackageId'],
                        orElse: () => null,
                      );
                      if (pkg != null) {
                        final cost = (double.tryParse(pkg['pricePerDay'].toString()) ?? 0) * d;
                        rows.add(_buildInfoRow(context, pkg['title'] ?? 'Protection Package', '€${cost.toStringAsFixed(2)}'));
                      }
                    }

                    if (booking['addonIds'] != null && (booking['addonIds'] as List).isNotEmpty) {
                      final addonIds = List<String>.from(booking['addonIds']);
                      final addonsList = (vehicle['addons'] as List?) ?? [];
                      for (final id in addonIds) {
                        final addon = addonsList.firstWhere((a) => a['id'] == id, orElse: () => null);
                        if (addon != null) {
                          final cost = (double.tryParse(addon['pricePerDay'].toString()) ?? 0) * d;
                          rows.add(_buildInfoRow(context, addon['name'] ?? 'Add-on', '€${cost.toStringAsFixed(2)}'));
                        }
                      }
                    }
                    
                    final grandTotal = double.tryParse(booking['grandTotal'].toString()) ?? 0;
                    final originalPaid = grandTotal - totalExtensionCost;
                    
                    if (totalExtensionCost > 0) {
                      rows.add(const Divider());
                      rows.add(_buildInfoRow(context, 'Original Booking', '€${originalPaid.toStringAsFixed(2)}', isBold: true));
                      rows.add(const SizedBox(height: 8));
                      rows.add(_buildInfoRow(context, 'Extension ($totalExtensionDays days)', '€${totalExtensionCost.toStringAsFixed(2)}', isBold: true));
                    }
                    
                    final walletAmountUsed = double.tryParse(booking['walletAmountUsed']?.toString() ?? '0') ?? 0;
                    if (walletAmountUsed > 0) {
                      rows.add(_buildInfoRow(context, 'GoCoins Discount', '-€${walletAmountUsed.toStringAsFixed(2)}', valueColor: AppColors.primaryGold));
                    }
                    
                    return rows;
                  })(),
                  
                  const Divider(),
                  _buildInfoRow(context, 'Grand Total', '€${double.parse(booking['grandTotal'].toString()).toStringAsFixed(2)}', isBold: true),
                ]),
                
                if (booking['handover'] != null) ...[
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'Handover Details'),
                  const SizedBox(height: 8),
                  _buildInfoCard(context, [
                    _buildInfoRow(context, 'Date', DateFormat('MMM dd, yyyy h:mm a').format(DateTime.parse(booking['handover']['createdAt']))),
                    _buildInfoRow(context, 'Fuel Level', booking['handover']['fuelLevel']),
                    _buildInfoRow(context, 'Odometer', '${booking['handover']['odometerReading']} km'),
                    _buildInfoRow(context, 'Condition', booking['handover']['vehicleCondition']),
                  ]),
                ],

                if (booking['return'] != null) ...[
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'Return Details'),
                  const SizedBox(height: 8),
                  _buildInfoCard(context, [
                    _buildInfoRow(context, 'Date', DateFormat('MMM dd, yyyy h:mm a').format(DateTime.parse(booking['return']['createdAt']))),
                    _buildInfoRow(context, 'Fuel Level', booking['return']['fuelLevel']),
                    _buildInfoRow(context, 'Odometer', '${booking['return']['odometerReading']} km'),
                    _buildInfoRow(context, 'Condition', booking['return']['vehicleCondition']),
                    if (booking['return']['damageNotes'] != null && booking['return']['damageNotes'].toString().isNotEmpty)
                      _buildInfoRow(context, 'Damage Notes', booking['return']['damageNotes']),
                  ]),
                ],

                if (['PENDING_PAYMENT', 'PENDING_APPROVAL', 'CONFIRMED'].contains(booking['status'])) ...[
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _handleCancel(context, ref, booking),
                      child: const Text('Cancel Booking', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    ),
                  ),
                ],

                if (booking['status'] == 'CANCELLED') ...[
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.cancel_outlined, color: Colors.redAccent),
                            const SizedBox(width: 12),
                            Text(
                              'Booking Cancelled',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(context, 'Cancelled By', booking['cancelledBy'] == 'USER' ? 'You' : booking['cancelledBy'] == 'SUPPLIER' ? 'Supplier' : 'System', valueColor: Colors.redAccent),
                        if (booking['cancellationReason'] != null)
                          _buildInfoRow(context, 'Reason', booking['cancellationReason'], valueColor: Colors.redAccent),
                        if (booking['return'] != null && booking['return']['refundAmount'] != null)
                          _buildInfoRow(context, 'Refund Amount', '€${double.parse(booking['return']['refundAmount'].toString()).toStringAsFixed(2)}', valueColor: Colors.green),
                      ],
                    ),
                  ),
                ],

                if (booking['status'] == 'ACTIVE') ...(() {
                  final extensionRequests = (booking['extensionRequests'] as List?) ?? [];

                  // 1. Pending request → awaiting supplier
                  final hasPendingExtension = extensionRequests.any((r) {
                    if (r['status'] != 'PENDING') return false;
                    final reqOrigDate = DateTime.parse(r['originalEndDate']);
                    final bookingEndDate = DateTime.parse(booking['endDate']);
                    return reqOrigDate.isAtSameMomentAs(bookingEndDate);
                  });

                  // 2. Already has an APPROVED extension
                  final hasApprovedExtension = extensionRequests.any((r) => r['status'] == 'APPROVED');

                  // 3. Most recent request was REJECTED
                  final hasRejectedExtension = !hasApprovedExtension &&
                      extensionRequests.any((r) => r['status'] == 'REJECTED');

                  if (hasPendingExtension) {
                    return [
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.hourglass_top_rounded, color: Colors.orange),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Your extension request is pending supplier approval. You\'ll be notified once reviewed.',
                                style: AppTextStyles.bodyMedium.copyWith(color: Colors.orange.shade800),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ];
                  }

                  if (hasRejectedExtension) {
                    return [
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withOpacity(0.4)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.cancel_outlined, color: Colors.redAccent),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Extension Request Rejected',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: Colors.red.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'The supplier has rejected your extension request. Your original return date remains unchanged.',
                                    style: AppTextStyles.bodySmall.copyWith(color: Colors.red.shade600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ];
                  }

                  if (hasApprovedExtension) {
                    return [
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.withOpacity(0.4)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle_outline, color: Colors.green),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Booking Already Extended',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Your booking has already been extended. Further extensions are not permitted.',
                                    style: AppTextStyles.bodySmall.copyWith(color: Colors.green.shade700),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ];
                  }

                  // Default: show Extend Booking button
                  return [
                    const SizedBox(height: 32),
                    Center(
                      child: SizedBox(
                        width: 320,
                        height: 42,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGold,
                            foregroundColor: AppColors.backgroundDark,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => _handleExtend(context, ref, booking),
                          child: const Text('Extend Booking', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        ),
                      ),
                    ),
                  ];
                })(),

                if (booking['extensionRequests'] != null && (booking['extensionRequests'] as List).isNotEmpty) ...[
                  const SizedBox(height: 32),
                  _buildSectionTitle(context, 'Extension History'),
                  const SizedBox(height: 8),
                  ...((booking['extensionRequests'] as List).map((ext) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: _buildInfoCard(context, [
                        _buildStatusRow(context, ext['status']),
                        _buildInfoRow(context, 'Requested End Date', DateFormat('MMM dd, yyyy h:mm a').format(DateTime.parse(ext['newEndDate']))),
                        _buildInfoRow(context, 'Additional Cost', '€${double.parse(ext['additionalCost'].toString()).toStringAsFixed(2)}', isBold: true),
                        if (ext['reason'] != null)
                          _buildInfoRow(context, 'Reason', ext['reason']),
                      ]),
                    );
                  }).toList()),
                ],

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryGold)),
        error: (e, st) => Center(child: Text('Error loading details: $e')),
      ),
    ),
  ],
),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: AppTextStyles.titleMedium.copyWith(
        color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildStatusRow(BuildContext context, String status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color statusColor;
    Color statusBg;
    IconData statusIcon;

    switch (status) {
      case 'PENDING_APPROVAL':
      case 'PENDING_PAYMENT':
        statusColor = isDark ? Colors.orange.shade400 : Colors.orange.shade800;
        statusBg = isDark ? Colors.orange.withOpacity(0.15) : Colors.orange.shade50;
        statusIcon = Icons.schedule_rounded;
        break;
      case 'CONFIRMED':
        statusColor = isDark ? Colors.blue.shade400 : Colors.blue.shade700;
        statusBg = isDark ? Colors.blue.withOpacity(0.15) : Colors.blue.shade50;
        statusIcon = Icons.check_circle_outline_rounded;
        break;
      case 'ACTIVE':
        statusColor = isDark ? Colors.green.shade400 : Colors.green.shade700;
        statusBg = isDark ? Colors.green.withOpacity(0.15) : Colors.green.shade50;
        statusIcon = Icons.directions_car_rounded;
        break;
      case 'COMPLETED':
        statusColor = isDark ? Colors.teal.shade300 : Colors.teal.shade700;
        statusBg = isDark ? Colors.teal.withOpacity(0.15) : Colors.teal.shade50;
        statusIcon = Icons.task_alt_rounded;
        break;
      case 'CANCELLED':
      case 'REJECTED':
        statusColor = isDark ? Colors.red.shade400 : AppColors.error;
        statusBg = isDark ? Colors.red.withOpacity(0.15) : Colors.red.shade50;
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusColor = AppColors.textSecondary;
        statusBg = isDark ? AppColors.textSecondary.withOpacity(0.15) : AppColors.backgroundLight;
        statusIcon = Icons.info_outline_rounded;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Status', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 14, color: statusColor),
                const SizedBox(width: 6),
                Text(
                  _formatStatus(status),
                  style: AppTextStyles.labelLarge.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, {bool isBold = false, bool isStatus = false, Color? valueColor}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color vColor = valueColor ?? (isDark ? AppColors.textPrimary : AppColors.textPrimaryLight);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.bodyMedium.copyWith(
                color: vColor,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatEnumString(String? val) {
    if (val == null) return 'N/A';
    return val.split('_').map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' : '').join(' ');
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

  void _handleCancel(BuildContext context, WidgetRef ref, Map<String, dynamic> booking) {
    bool isFlexible = booking['isFlexible'] == true;
    DateTime pickupDate = DateTime.parse(booking['startDate']);
    DateTime endDate = DateTime.parse(booking['endDate']);
    DateTime createdAt = DateTime.parse(booking['createdAt']);
    DateTime now = DateTime.now();

    bool isEligibleForCancel = false;
    String cancelWarning = '';
    double estimatedRefund = 0.0;
    
    if (isFlexible) {
      if (booking['status'] == 'ACTIVE') {
        int totalDays = endDate.difference(pickupDate).inDays;
        if (totalDays < 1) totalDays = 1;
        int usedDays = now.difference(pickupDate).inDays;
        if (usedDays < 1) usedDays = 1;
        int remainingDays = totalDays - usedDays;
        if (remainingDays < 0) remainingDays = 0;
        
        isEligibleForCancel = true;
        if (remainingDays > 0) {
          double grandTotal = double.tryParse(booking['grandTotal'].toString()) ?? 0;
          estimatedRefund = (grandTotal / totalDays) * remainingDays;
        }
      } else {
        isEligibleForCancel = true;
        estimatedRefund = double.tryParse(booking['grandTotal'].toString()) ?? 0;
      }
    } else {
      if (booking['status'] == 'ACTIVE') {
        cancelWarning = 'Basic plan bookings cannot be cancelled once active.';
      } else {
        final diffHours = now.difference(createdAt).inHours;
        if (diffHours <= 24) {
          isEligibleForCancel = true;
          estimatedRefund = double.tryParse(booking['grandTotal'].toString()) ?? 0;
        } else {
          cancelWarning = 'Basic plan bookings can only be cancelled within 24 hours of placing the booking.';
        }
      }
    }

    if (!isEligibleForCancel) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color,
          title: const Text('Cannot Cancel Booking'),
          content: Text(cancelWarning),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK', style: TextStyle(color: AppColors.primaryGold)),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: const Text('Cancel Booking'),
        content: Text('Are you sure you want to cancel this booking? A refund of €${estimatedRefund.toStringAsFixed(2)} will be credited to your original payment method within 24 hours.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('NO', style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primaryGold)),
              );

              try {
                final dio = ref.read(dioProvider);
                final datasource = CarRentalRemoteDatasource(dio);
                final response = await datasource.cancelBooking(booking['id']);
                
                ref.invalidate(carRentalBookingDetailsProvider(booking['id']));
                ref.invalidate(carRentalHistoryProvider);
                
                if (context.mounted) {
                  Navigator.of(context).pop(); // dismiss loading
                  final finalRefund = double.tryParse(response['refundAmount'].toString()) ?? estimatedRefund;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CarRentalCancellationSuccessScreen(refundAmount: finalRefund),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.of(context).pop(); // dismiss loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.redAccent),
                  );
                }
              }
            },
            child: const Text('YES, CANCEL', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _handleExtend(BuildContext context, WidgetRef ref, Map<String, dynamic> booking) async {
    final DateTime currentEndDate = DateTime.parse(booking['endDate']);
    
    // Pick new date
    final DateTime? newDate = await showDatePicker(
      context: context,
      initialDate: currentEndDate.add(const Duration(days: 1)),
      firstDate: currentEndDate.add(const Duration(days: 1)),
      lastDate: currentEndDate.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryGold,
              onPrimary: AppColors.backgroundDark,
              surface: AppColors.backgroundLight,
              onSurface: AppColors.textPrimaryLight,
            ),
          ),
          child: child!,
        );
      },
    );

    if (newDate == null) return;
    if (!context.mounted) return;
    
    final DateTime newDateWithTime = DateTime(
      newDate.year,
      newDate.month,
      newDate.day,
      currentEndDate.hour,
      currentEndDate.minute,
    );

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppColors.primaryGold)),
    );

    try {
      final dio = ref.read(dioProvider);
      final datasource = CarRentalRemoteDatasource(dio);
      
      // Calculate
      final newEndDateStr = newDateWithTime.toIso8601String();
      final calcResult = await datasource.calculateExtensionCost(booking['id'], newEndDateStr);
      
      if (!context.mounted) return;
      Navigator.of(context).pop(); // dismiss loading
      
      // Show Confirmation
      await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        builder: (ctx) => _buildExtendConfirmationModal(ctx, calcResult, datasource, booking['id'], newEndDateStr, ref),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop(); // dismiss loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.redAccent),
      );
    }
  }

  Widget _buildExtendConfirmationModal(
    BuildContext context, 
    Map<String, dynamic> calcResult,
    CarRentalRemoteDatasource datasource,
    String bookingId,
    String newEndDateStr,
    WidgetRef ref,
  ) {
    bool isSubmitting = false;

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 24),
            Text('Confirm Extension', style: AppTextStyles.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            
            _buildInfoCard(context, [
              _buildInfoRow(context, 'Original Return', DateFormat('MMM d, yyyy - h:mm a').format(DateTime.parse(calcResult['originalEndDate']))),
              _buildInfoRow(context, 'New Return', DateFormat('MMM d, yyyy - h:mm a').format(DateTime.parse(calcResult['newEndDate'])), isBold: true),
              const Divider(),
              _buildInfoRow(context, 'Existing Rent Amount', '€${double.parse(calcResult['existingTotal'].toString()).toStringAsFixed(2)}'),
              const Divider(),
              _buildInfoRow(context, 'Extra Days', '${calcResult['extraDays']} days'),
              if (calcResult['breakdown'] != null)
                ...(calcResult['breakdown'] as List).map((b) => _buildInfoRow(context, b['label'], '€${double.parse(b['cost'].toString()).toStringAsFixed(2)}')),
              const Divider(),
              _buildInfoRow(context, 'Extended Amount', '€${double.parse(calcResult['additionalCost'].toString()).toStringAsFixed(2)}'),
              const Divider(),
              _buildInfoRow(context, 'New Grand Total', '€${double.parse(calcResult['finalTotal'].toString()).toStringAsFixed(2)}', isBold: true),
            ]),
            
            const SizedBox(height: 32),
            Center(
              child: SizedBox(
                width: 320,
                height: 42,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    foregroundColor: AppColors.backgroundDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isSubmitting ? null : () async {
                    setState(() => isSubmitting = true);
                    try {
                      final double additionalCost = double.parse(calcResult['additionalCost'].toString());
                      
                      if (additionalCost > 0) {
                        // First get the payment intent
                        await datasource.createExtensionPaymentIntent(bookingId, newEndDateStr);
                        
                        if (!context.mounted) return;
                        Navigator.of(context).pop(); // dismiss modal
                        
                        // Show Stripe Bottom Sheet
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => StripeAddCardSheet(
                            datasource: PaymentRemoteDatasource(ref.read(dioProvider)),
                            amount: additionalCost,
                            simulatePayment: true,
                            onCardAdded: (paymentMethodId) async {
                              // Card was charged/added, now we submit the actual extension request
                              try {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppColors.primaryGold)),
                                );
                                
                                await datasource.createExtensionRequest(
                                  bookingId, 
                                  newEndDateStr, 
                                  paymentIntentId: paymentMethodId
                                );
                                
                                ref.invalidate(carRentalBookingDetailsProvider(bookingId));
                                
                                if (context.mounted) {
                                  Navigator.of(context).pop(); // dismiss loading
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const RentalExtensionSuccessScreen()),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  Navigator.of(context).pop(); // dismiss loading
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.redAccent),
                                  );
                                }
                              }
                            },
                          ),
                        );
                      } else {
                        // If 0 cost, just submit
                        await datasource.createExtensionRequest(bookingId, newEndDateStr);
                        if (!context.mounted) return;
                        Navigator.of(context).pop(); // dismiss modal
                        
                        ref.invalidate(carRentalBookingDetailsProvider(bookingId));
                        
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const RentalExtensionSuccessScreen()),
                        );
                      }
                    } catch (e) {
                      setState(() => isSubmitting = false);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.redAccent),
                      );
                    }
                  },
                  child: isSubmitting 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.backgroundDark))
                      : const Text('Pay & Submit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: isSubmitting ? Colors.grey.withOpacity(0.5) : Colors.grey)),
            ),
          ],
        ),
      ),
    );
      },
    );
  }
}
