import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../quick_services/data/models/quick_service_history_model.dart';
import 'package:intl/intl.dart';

class QuickServiceHistoryDetailsScreen extends StatelessWidget {
  final QuickServiceHistoryModel booking;

  const QuickServiceHistoryDetailsScreen({super.key, required this.booking});

  String _getExpertVisitName(String serviceTitle) {
    final lowerCat = serviceTitle.toLowerCase();
    if (lowerCat.contains('security') || lowerCat.contains('bouncer')) {
      return 'Hiring Person/hr';
    } else if (lowerCat.contains('mechanic')) {
      return 'Mechanic Visit/hr';
    } else if (lowerCat.contains('electric')) {
      if (lowerCat.contains('commercial') || lowerCat.contains('lift') || lowerCat.contains('events')) {
        return 'Mechanic Visit/hr';
      }
      return 'Expert Visit/hr';
    } else if (lowerCat.contains('engineer') || 
               lowerCat.contains('computer') ||
               lowerCat.contains('printer') ||
               lowerCat.contains('mobile') ||
               lowerCat.contains('technician')) {
      return 'Engineering Visit/hr';
    } else if (lowerCat.contains('wash')) {
      return 'Service Agent Visit/hr';
    }
    return 'Expert Visit/hr';
  }

  double _getQuickServiceHourlyRate(String serviceTitle) {
    final lowerCat = serviceTitle.toLowerCase();
    
    if (lowerCat.contains('plumber') || lowerCat.contains('carpenter')) return 20.00;
    if (lowerCat.contains('computer') || 
        lowerCat.contains('electric') || 
        lowerCat.contains('lift') || 
        lowerCat.contains('appliance') || 
        lowerCat.contains('printer') || 
        lowerCat.contains('mobile')) return 10.00;
    
    if (lowerCat.contains('mechanic')) {
      if (lowerCat.contains('car') || lowerCat.contains('truck')) return 9.00;
      if (lowerCat.contains('bike')) return 8.00;
      return 6.00;
    }
    
    if (lowerCat.contains('truck wash')) return 8.00;
    if (lowerCat.contains('security') || lowerCat.contains('hire person')) return 7.00;
    
    return 6.00;
  }

  @override
  Widget build(BuildContext context) {
    final status = booking.status.toUpperCase();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final displayBookingId = 'GZ-QS-${booking.id.substring(0, 8).toUpperCase()}';
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
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Present this to service person',
                            style: AppTextStyles.titleMedium.copyWith(color: AppColors.textPrimaryLight),
                          ),
                          const SizedBox(height: 16),
                          QrImageView(
                            data: qrDataJson,
                            version: QrVersions.auto,
                            size: 150.0,
                            backgroundColor: Colors.white,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Service ID',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            displayBookingId,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.titleMedium.copyWith(
                                color: AppColors.textPrimaryLight,
                                fontWeight: FontWeight.bold, 
                                letterSpacing: 1.2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],


                  // Booking Summary Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
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
                                    color: AppColors.primaryGold.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.receipt_long,
                                    color: AppColors.primaryGold,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Booking Summary',
                                  style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            _buildStatusBadge(status),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Service Title
                        Row(
                          children: [
                            const Icon(Icons.home_repair_service, size: 18, color: Colors.grey),
                            const SizedBox(width: 10),
                            Text(booking.serviceTitle, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        
                        // Date & Time
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                            const SizedBox(width: 10),
                            Text('$displayDate • $displayTime', style: AppTextStyles.bodySmall),
                          ],
                        ),
                        
                        if (booking.location != null) ...[
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on, size: 18, color: Colors.grey),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  booking.location!,
                                  style: AppTextStyles.bodySmall,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],

                        if (booking.userName != null) ...[
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.person, size: 18, color: Colors.grey),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Customer: ${booking.userName}', style: AppTextStyles.bodySmall),
                                    if (booking.userEmail != null) ...[
                                      const SizedBox(height: 2),
                                      Text('Email: ${booking.userEmail}', style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[600], fontSize: 12)),
                                    ],
                                    if (booking.userPhone != null) ...[
                                      const SizedBox(height: 2),
                                      Text('Phone: ${booking.userPhone}', style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[600], fontSize: 12)),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                        
                        if (booking.options.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 12),
                          ...booking.options.entries.map((e) {
                            if (e.value is List) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(e.key, style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 8),
                                    ...(e.value as List).map((item) {
                                      if (item is Map) {
                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 8.0),
                                          padding: const EdgeInsets.all(12.0),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.withOpacity(0.05),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey.withOpacity(0.2)),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: item.entries
                                                .where((entry) => entry.value != null && entry.value.toString().isNotEmpty)
                                                .map<Widget>((entry) {
                                              return Padding(
                                                padding: const EdgeInsets.only(bottom: 6.0),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text('${entry.key}: ', style: AppTextStyles.bodySmall.copyWith(color: Colors.grey.shade700)),
                                                    Expanded(child: Text('${entry.value}', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold))),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        );
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 6.0),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('• ', style: AppTextStyles.bodyMedium),
                                            Expanded(child: Text('$item', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold))),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                ),
                              );
                            } else {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(e.key, style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade700)),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        '${e.value}',
                                        textAlign: TextAlign.end,
                                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          }).toList(),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Selected Add-ons Card (Matching Price Summary style)
                  // Selected Add-ons Card (Matching Price Summary style)
                  if (booking.addOns.where((a) => a is Map).isNotEmpty || (booking.requirements != null && booking.requirements!.trim().isNotEmpty) || (booking.images != null && booking.images!.isNotEmpty)) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected Add-ons & Details',
                            style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          if (booking.addOns.where((a) => a is Map).isNotEmpty)
                            ...booking.addOns.where((a) => a is Map).map((addon) {
                              String name = 'Unknown Add-on';
                              String countOrPrice = '';
                              if (addon is Map) {
                                name = addon['name']?.toString() ?? 'Unknown Add-on';
                                if (addon.containsKey('count') && addon['count'] != null) {
                                  countOrPrice = '${addon['count']}';
                                } else if (addon.containsKey('price') && addon['price'] != null) {
                                  countOrPrice = '€${addon['price']}';
                                }
                              }

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: AppTextStyles.bodyMedium,
                                      ),
                                    ),
                                    Text(
                                      countOrPrice,
                                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          
                          if (booking.addOns.where((a) => a is Map).isNotEmpty && ((booking.requirements != null && booking.requirements!.trim().isNotEmpty) || (booking.images != null && booking.images!.isNotEmpty)))
                            const Divider(height: 24),
                          
                          if (booking.requirements != null && booking.requirements!.trim().isNotEmpty) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.note_alt_outlined, size: 18, color: Colors.grey),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Issue description: ${booking.requirements!}',
                                    style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[700]),
                                  ),
                                ),
                              ],
                            ),
                            if (booking.images != null && booking.images!.isNotEmpty) const SizedBox(height: 10),
                          ],

                          if (booking.images != null && booking.images!.isNotEmpty) ...[
                            Row(
                              children: [
                                const Icon(Icons.image_outlined, size: 18, color: Colors.grey),
                                const SizedBox(width: 10),
                                Text('Attached Photo (${booking.images!.length})', style: AppTextStyles.bodySmall),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: SizedBox(
                                    height: 40,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: booking.images!.length,
                                      itemBuilder: (context, index) {
                                        final path = booking.images![index];
                                        return Padding(
                                          padding: const EdgeInsets.only(left: 4.0),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: Image.network(
                                              path,
                                              width: 40,
                                              height: 40,
                                              fit: BoxFit.cover,
                                              errorBuilder: (ctx, err, stack) => Container(
                                                width: 40,
                                                height: 40,
                                                color: Colors.grey[200],
                                                child: const Icon(Icons.broken_image, size: 16, color: Colors.grey),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Supplier Details
                  if (booking.supplier != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Supplier Details',
                            style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Company', style: AppTextStyles.bodyMedium),
                              Text(booking.supplier!['companyName'] ?? 'N/A', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Price Details Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Summary',
                          style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Upfront Booking Fee', style: AppTextStyles.bodyMedium),
                            Text('€${booking.upfrontFee.toStringAsFixed(2)}', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_getExpertVisitName(booking.serviceTitle), style: AppTextStyles.bodyMedium),
                            Text('€${_getQuickServiceHourlyRate(booking.serviceTitle).toStringAsFixed(2)}', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        if (booking.materialCost > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Materials Included', style: AppTextStyles.bodyMedium),
                              Text('€${booking.materialCost.toStringAsFixed(2)}', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                        if (booking.discountAmount > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('GoCoins Discount', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryGold)),
                              Text('-€${booking.discountAmount.toStringAsFixed(2)}', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryGold)),
                            ],
                          ),
                        ],
                        if (booking.estimatedPrice != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Estimated Spare Price', style: AppTextStyles.bodyMedium),
                              Text(booking.estimatedPrice!, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Amount Paid',
                              style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '€${booking.totalAmount.toStringAsFixed(2)}',
                              style: AppTextStyles.titleMedium.copyWith(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color statusBg;
    Color statusText;
    String displayStatus;

    if (status == 'COMPLETED') {
        statusBg = AppColors.success.withOpacity(0.1);
        statusText = AppColors.success;
        displayStatus = 'Completed';
    } else if (status == 'CANCELLED' || status == 'CANCELED') {
        statusBg = AppColors.error.withOpacity(0.1);
        statusText = AppColors.error;
        displayStatus = 'Cancelled';
    } else {
        statusBg = AppColors.primaryGold.withOpacity(0.1);
        statusText = AppColors.primaryGold;
        displayStatus = 'Scheduled';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: statusBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        displayStatus,
        style: AppTextStyles.labelSmall.copyWith(color: statusText, fontWeight: FontWeight.bold),
      ),
    );
  }
}
