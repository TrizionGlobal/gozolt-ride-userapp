import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../quick_services/data/models/quick_service_history_model.dart';
import 'package:intl/intl.dart';

class QuickServiceHistoryDetailsScreen extends StatelessWidget {
  final QuickServiceHistoryModel booking;

  const QuickServiceHistoryDetailsScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final status = booking.status.toUpperCase();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final displayBookingId = booking.id.substring(0, 8).toUpperCase();
    final displayDate = DateFormat('dd MMM yyyy').format(booking.bookingDate);
    final displayTime = DateFormat('h:mm a').format(booking.bookingDate);
    final qrDataJson = '''
Service ID: $displayBookingId
Service: ${booking.serviceTitle}
Date: $displayDate
Time: $displayTime
'''.trim();

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
                      'Service Details',
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // QR Code Section
                  if (status != 'CANCELLED' && status != 'CANCELED') ...[
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white, // QR code needs white background for contrast
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Present this to service provider',
                            style: AppTextStyles.titleMedium.copyWith(color: AppColors.textPrimaryLight),
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
                            'Service ID: $displayBookingId',
                            style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondaryLight),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Service Information
                  _buildSectionTitle(context, 'Service Information'),
                  const SizedBox(height: 8),
                  _buildInfoCard(context, [
                    _buildStatusRow(context, status),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGold.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                                  Icons.home_repair_service,
                                  color: AppColors.primaryGold,
                                  size: 28,
                                ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Service',
                                style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                booking.serviceTitle,
                                style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    _buildInfoRow(context, 'Date', displayDate),
                    _buildInfoRow(context, 'Time', displayTime),
                  ]),
                  
                  if (booking.options.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSectionTitle(context, 'Features Selection'),
                    const SizedBox(height: 8),
                    _buildInfoCard(context, [
                      ...(booking.options.entries.map((e) {
                        return _buildInfoRow(context, e.key, e.value.toString());
                      })),
                    ]),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  if (booking.addOns.isNotEmpty) ...[
                    _buildSectionTitle(context, 'Add-ons Selection'),
                    const SizedBox(height: 8),
                    _buildInfoCard(context, [
                      ...(booking.addOns.map((addon) {
                        return _buildInfoRow(context, addon['name'] as String, '€${(addon['price']).toString()}');
                      })),
                    ]),
                    const SizedBox(height: 24),
                  ],

                  // Supplier Details
                  if (booking.supplier != null) ...[
                    _buildSectionTitle(context, 'Supplier Details'),
                    const SizedBox(height: 8),
                    _buildInfoCard(context, [
                      _buildInfoRow(context, 'Company', booking.supplier!['companyName'] ?? 'N/A'),
                    ]),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Payment Details
                  _buildSectionTitle(context, 'Payment Details'),
                  const SizedBox(height: 8),
                  _buildInfoCard(context, [
                    _buildInfoRow(context, 'Payment Method', booking.paymentMethod),
                    _buildInfoRow(context, 'Base Rate', '€${booking.upfrontFee.toStringAsFixed(2)}'),
                    
                    if (booking.materialCost > 0)
                      _buildInfoRow(context, 'Materials & Add-ons', '€${booking.materialCost.toStringAsFixed(2)}'),
                    
                    const Divider(),
                    _buildInfoRow(context, 'Grand Total', '€${booking.totalAmount.toStringAsFixed(2)}', isBold: true),
                  ]),

                  if (status == 'PENDING' || status == 'SCHEDULED') ...[
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
                        onPressed: () {
                          // Mock cancellation action
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Service cancellation requested.')),
                          );
                        },
                        child: const Text('Cancel Service', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      ),
                    ),
                  ],

                  if (status == 'CANCELLED' || status == 'CANCELED') ...[
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
                                'Service Cancelled',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(context, 'Cancelled By', 'You', valueColor: Colors.redAccent),
                          _buildInfoRow(context, 'Refund Amount', '€${booking.totalAmount.toStringAsFixed(2)}', valueColor: Colors.green),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
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
      case 'PENDING':
      case 'SCHEDULED':
        statusColor = isDark ? Colors.orange.shade400 : Colors.orange.shade800;
        statusBg = isDark ? Colors.orange.withOpacity(0.15) : Colors.orange.shade50;
        statusIcon = Icons.schedule_rounded;
        break;
      case 'COMPLETED':
        statusColor = isDark ? Colors.teal.shade300 : Colors.teal.shade700;
        statusBg = isDark ? Colors.teal.withOpacity(0.15) : Colors.teal.shade50;
        statusIcon = Icons.task_alt_rounded;
        break;
      case 'CANCELLED':
      case 'CANCELED':
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
                  status,
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

  Widget _buildInfoRow(BuildContext context, String label, String value, {bool isBold = false, Color? valueColor}) {
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
}
