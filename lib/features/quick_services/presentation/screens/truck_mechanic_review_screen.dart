import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../widgets/quick_services_header.dart';
import '../../data/models/quick_service_booking_data.dart';

class TruckMechanicReviewScreen extends StatefulWidget {
  final QuickServiceBookingData bookingData;
  const TruckMechanicReviewScreen({super.key, required this.bookingData});

  @override
  State<TruckMechanicReviewScreen> createState() => _TruckMechanicReviewScreenState();
}

class _TruckMechanicReviewScreenState extends State<TruckMechanicReviewScreen> {
  bool useCoins = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const QuickServicesHeader(title: 'Review & Book'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Car Details Container
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.withOpacity(0.3)), borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.directions_car, size: 20),
                            const SizedBox(width: 8),
                            Text('Car Mechanic', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Divider(height: 24),
                        _buildDetailRow('Vehicle Type', widget.bookingData.truckType ?? '-'),
                        const SizedBox(height: 8),
                        _buildDetailRow('Make & Model', '${widget.bookingData.vehicleMake ?? ''} ${widget.bookingData.vehicleModel ?? ''}'.trim()),
                        if (widget.bookingData.vehicleYear != null) ...[
                          const SizedBox(height: 8),
                          _buildDetailRow('Year', widget.bookingData.vehicleYear!),
                        ],
                        if (widget.bookingData.vehicleRegistration != null) ...[
                          const SizedBox(height: 8),
                          _buildDetailRow('Registration Number', widget.bookingData.vehicleRegistration!),
                        ],
                        if (widget.bookingData.mileage != null) ...[
                          const SizedBox(height: 8),
                          _buildDetailRow('Mileage', widget.bookingData.mileage!),
                        ],
                        const SizedBox(height: 8),
                        _buildDetailRow('Issue', widget.bookingData.vehicleIssue ?? '-'),
                        const Divider(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.calendar_today, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Schedule\n${_formatDate(widget.bookingData.scheduleDate)} • ${widget.bookingData.scheduleTime.format(context)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Service Address\n${widget.bookingData.location.address}',
                                style: const TextStyle(fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.person, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Customer\n${widget.bookingData.userName}\n${widget.bookingData.userPhone} • ${widget.bookingData.userEmail}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (widget.bookingData.whatYouNeed != null || widget.bookingData.describeIssue != null || (widget.bookingData.uploadedImages?.isNotEmpty ?? false)) ...[
                    const SizedBox(height: 20),
                    Text('Issue Description', style: AppTextStyles.titleSmall),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.withOpacity(0.3)), borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.bookingData.whatYouNeed != null) ...[
                            const Text('What You Need:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF324461))),
                            const SizedBox(height: 4),
                            Text(widget.bookingData.whatYouNeed!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            if (widget.bookingData.describeIssue != null || (widget.bookingData.uploadedImages?.isNotEmpty ?? false)) const SizedBox(height: 12),
                          ],
                          if (widget.bookingData.describeIssue != null) ...[
                            const Text('Issue Description:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF324461))),
                            const SizedBox(height: 4),
                            Text(widget.bookingData.describeIssue!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            if (widget.bookingData.uploadedImages?.isNotEmpty ?? false) const SizedBox(height: 12),
                          ],
                          if (widget.bookingData.uploadedImages?.isNotEmpty ?? false) ...[
                            const Text('Uploaded Photos:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF324461))),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: widget.bookingData.uploadedImages!.map((path) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(path),
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  
                  ...widget.bookingData.selectedAddons.map((addon) {
                    return _buildPriceRow(addon.name, '€${addon.totalPrice.toStringAsFixed(2)}');
                  }).toList(),
                  _buildPriceRow('Visit / Inspection Fee', '€${widget.bookingData.subtotal.toStringAsFixed(2)}'),
                  _buildPriceRow('Estimated Labour', '€40 - €120', valueStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGold)),
                  _buildPriceRow('Replacement Parts', 'Not Included'),
                  const Divider(),
                  const Text('Final quote after inspection', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Available: 250 GO Coins', style: TextStyle(fontSize: 12)),
                            Text('Use 200 coins', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Switch(
                          value: useCoins,
                          activeColor: AppColors.primaryGold,
                          onChanged: (v) => setState(() => useCoins = v),
                        ),
                      ],
                    ),
                  ),
                  if (useCoins) _buildPriceRow('Discount', '-€2.00', isDiscount: true),
                  
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: AppColors.primaryGold),
                      const SizedBox(width: 8),
                      const Text('Pay after service', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: true, // Mock checked state
                        onChanged: (v) {},
                        activeColor: AppColors.primaryGold,
                        checkColor: Colors.black,
                      ),
                      const Expanded(
                        child: Text(
                          'I accept the Service Terms and Cancellation Policy.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: ElevatedButton(
            onPressed: () {
              context.pushNamed(
                RouteNames.quickServicesTruckMechanicConfirmation, // generic confirmation screen
                extra: widget.bookingData,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('CONFIRM BOOKING', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPriceRow(String label, String price, {bool isDiscount = false, TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(price, style: valueStyle ?? TextStyle(fontSize: 14, color: isDiscount ? Colors.red : null)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return '${date.day} ${months[date.month - 1]} ${date.year} • ${weekdays[date.weekday - 1]}';
  }
}
