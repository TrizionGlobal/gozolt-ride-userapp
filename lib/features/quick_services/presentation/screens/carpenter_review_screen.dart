import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../widgets/quick_services_header.dart';
import '../../data/models/quick_service_booking_data.dart';

class CarpenterReviewScreen extends StatefulWidget {
  final QuickServiceBookingData bookingData;
  const CarpenterReviewScreen({super.key, required this.bookingData});

  @override
  State<CarpenterReviewScreen> createState() => _CarpenterReviewScreenState();
}

class _CarpenterReviewScreenState extends State<CarpenterReviewScreen> {
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.withOpacity(0.3)), borderRadius: BorderRadius.circular(8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Appointment Summary\n${_formatDate(widget.bookingData.scheduleDate)} • ${widget.bookingData.scheduleTime.format(context)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Service Location\n${widget.bookingData.location.address}',
                            style: const TextStyle(fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (widget.bookingData.whatYouNeed != null || widget.bookingData.describeIssue != null || (widget.bookingData.uploadedImages?.isNotEmpty ?? false)) ...[
                const SizedBox(height: 20),
                Text('Additional Details', style: AppTextStyles.titleSmall),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.withOpacity(0.3)), borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.bookingData.whatYouNeed != null) ...[
                        const Text('What you need:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF324461))),
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
              Text('Selected Services', style: AppTextStyles.titleSmall),
              const SizedBox(height: 10),
              ...widget.bookingData.selectedAddons.map((addon) {
                return _buildPriceRow('${addon.name} (${addon.count})', '€${addon.totalPrice.toStringAsFixed(2)}');
              }).toList(),
              const Divider(),
              _buildPriceRow('Service Subtotal', '€${widget.bookingData.subtotal.toStringAsFixed(2)}'),
              _buildPriceRow(
                'Cleaning Materials (${widget.bookingData.materialPreference ?? "Included"})',
                widget.bookingData.materialCost > 0 ? '+€${widget.bookingData.materialCost.toStringAsFixed(2)}' : 'No extra charge',
              ),
              _buildPriceRow('Taxes (Included)', '€0.00'),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Estimated Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('€${widget.bookingData.estimatedTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
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
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text('€${_calculateTotal().toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              const SizedBox(height: 8),
              const Text('ℹ️ Pay after service', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          )),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: ElevatedButton(
                onPressed: () {
                  context.pushNamed(
                    RouteNames.quickServicesCarpenterConfirmation,
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
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String price, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(price, style: TextStyle(fontSize: 14, color: isDiscount ? Colors.red : null)),
        ],
      ),
    );
  }

  double _calculateTotal() {
    double total = widget.bookingData.estimatedTotal;
    if (useCoins) total -= 2.00;
    return total > 0 ? total : 0;
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return '${date.day} ${months[date.month - 1]} ${date.year} • ${weekdays[date.weekday - 1]}';
  }
}
