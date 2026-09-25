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
                            'Present this to service provider',
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
                          const SizedBox(height: 10),
                          ...booking.options.entries.map((e) {
                            IconData iconData = Icons.info_outline;
                            if (e.key.toLowerCase().contains('material')) {
                              iconData = Icons.inventory_2_outlined;
                            } else if (e.key.toLowerCase().contains('wall')) {
                              iconData = Icons.foundation;
                            } else if (e.key.toLowerCase().contains('floor')) {
                              iconData = Icons.stairs;
                            } else if (e.key.toLowerCase().contains('bike')) {
                              iconData = Icons.two_wheeler;
                            } else if (e.key.toLowerCase().contains('truck')) {
                              iconData = Icons.local_shipping;
                            } else if (e.key.toLowerCase().contains('vehicle type')) {
                              iconData = e.value.toString().toLowerCase().contains('truck') || e.value.toString().toLowerCase().contains('lorry') ? Icons.local_shipping : e.value.toString().toLowerCase().contains('bike') ? Icons.two_wheeler : Icons.directions_car;
                            } else if (e.key.toLowerCase().contains('vehicle') || e.key.toLowerCase().contains('car')) {
                              iconData = Icons.directions_car;
                            } else if (e.key.toLowerCase().contains('quantity')) {
                              iconData = Icons.scale;
                            } else if (e.key.toLowerCase().contains('laundry type')) {
                              iconData = Icons.local_laundry_service;
                            } else if (e.key.toLowerCase().contains('gardening')) {
                              iconData = Icons.yard_outlined;
                            } else if (e.key.toLowerCase().contains('service area')) {
                              iconData = Icons.maps_home_work;
                            } else if (e.key.toLowerCase().contains('pest type')) {
                              iconData = Icons.bug_report;
                            } else if (e.key.toLowerCase().contains('location')) {
                              iconData = Icons.home;
                            } else if (e.key.toLowerCase().contains('ac type')) {
                              iconData = Icons.ac_unit;
                            } else if (e.key.toLowerCase().contains('issue')) {
                              iconData = Icons.build;
                            } else if (e.key.toLowerCase().contains('tv type')) {
                              iconData = Icons.tv;
                            } else if (e.key.toLowerCase().contains('cable')) {
                              iconData = Icons.cable;
                            } else if (e.key.toLowerCase().contains('furniture')) {
                              iconData = Icons.chair;
                            } else if (e.key.toLowerCase().contains('bedroom')) {
                              iconData = Icons.bed;
                            } else if (e.key.toLowerCase().contains('sofa')) {
                              iconData = Icons.weekend;
                            } else if (e.key.toLowerCase().contains('carpet')) {
                              iconData = Icons.local_laundry_service;
                            } else if (e.key.toLowerCase().contains('features')) {
                              iconData = Icons.check_circle_outline;
                            } else if (e.key.toLowerCase().contains('what you need')) {
                              iconData = Icons.build_circle;
                            } else if (e.key.toLowerCase().contains('computer') || e.key.toLowerCase().contains('laptop')) {
                              iconData = Icons.computer;
                            } else if (e.key.toLowerCase().contains('phone') || e.key.toLowerCase().contains('mobile')) {
                              iconData = Icons.phone_iphone;
                            } else if (e.key.toLowerCase().contains('printer') || e.key.toLowerCase().contains('scanner')) {
                              iconData = Icons.print;
                            } else if (e.key.toLowerCase().contains('count') || e.key.toLowerCase().contains('people')) {
                              iconData = Icons.people;
                            } else if (e.key.toLowerCase().contains('gender')) {
                              iconData = Icons.wc;
                            } else if (e.key.toLowerCase().contains('duration')) {
                              iconData = Icons.timer;
                            } else if (e.key.toLowerCase().contains('time')) {
                              iconData = Icons.access_time;
                            } else if (e.key.toLowerCase().contains('comment')) {
                              iconData = Icons.comment;
                            } else if (e.key.toLowerCase().contains('security')) {
                              iconData = Icons.security;
                            } else if (e.key.toLowerCase().contains('venue')) {
                              iconData = Icons.event_seat;
                            } else if (e.key.toLowerCase().contains('attendance')) {
                              iconData = Icons.groups;
                            } else if (e.key.toLowerCase().contains('dress')) {
                              iconData = Icons.checkroom;
                            } else if (e.key.toLowerCase().contains('alcohol')) {
                              iconData = Icons.local_bar;
                            } else if (e.key.toLowerCase().contains('date')) {
                              iconData = Icons.calendar_month;
                            } else if (e.key.toLowerCase().contains('paint')) {
                              iconData = Icons.format_paint;
                            } else if (e.key.toLowerCase().contains('property') || e.key.toLowerCase().contains('facility') || e.key.toLowerCase().contains('business')) {
                              iconData = Icons.business;
                            } else if (e.key.toLowerCase().contains('lift') || e.key.toLowerCase().contains('elevator')) {
                              iconData = Icons.elevator;
                            } else if (e.key.toLowerCase().contains('water')) {
                              iconData = Icons.water_drop;
                            } else if (e.key.toLowerCase().contains('electric') || e.key.toLowerCase().contains('power')) {
                              iconData = Icons.electrical_services;
                            } else if (e.key.toLowerCase().contains('contact')) {
                              iconData = Icons.contact_phone;
                            } else if (e.key.toLowerCase().contains('treatment')) {
                              iconData = Icons.spa;
                            } else if (e.key.toLowerCase().contains('professional')) {
                              iconData = Icons.work_outline;
                            } else if (e.key.toLowerCase().contains('event') || e.key.toLowerCase().contains('guest')) {
                              iconData = Icons.celebration;
                            } else if (e.key.toLowerCase().contains('supply') || e.key.toLowerCase().contains('item') || e.key.toLowerCase().contains('requirement')) {
                              iconData = Icons.category;
                            } else if (e.key.toLowerCase().contains('room')) {
                              iconData = Icons.meeting_room;
                            }
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(iconData, size: 18, color: Colors.grey),
                                  const SizedBox(width: 10),
                                  if (e.value is List)
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(e.key, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 6),
                                          ...(e.value as List).map((item) {
                                            if (item is Map) {
                                              return Container(
                                                margin: const EdgeInsets.only(bottom: 8.0, top: 2.0),
                                                padding: const EdgeInsets.all(10.0),
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
                                                      padding: const EdgeInsets.only(bottom: 4.0),
                                                      child: Row(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text('${entry.key}: ', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, fontSize: 12)),
                                                          Expanded(child: Text('${entry.value}', style: AppTextStyles.bodySmall.copyWith(fontSize: 12))),
                                                        ],
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                              );
                                            }
                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 4.0),
                                              child: Text('• ${item}', style: AppTextStyles.bodySmall),
                                            );
                                          }).toList(),
                                        ],
                                      ),
                                    )
                                  else
                                    Expanded(
                                      child: Text('${e.key}: ${e.value}', style: AppTextStyles.bodySmall),
                                    ),
                                ],
                              ),
                            );
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
