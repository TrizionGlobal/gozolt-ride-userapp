import '../../../../../core/widgets/booking_payment_sheet.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/quick_services_payment_selector.dart';
import '../../../../rewards/presentation/providers/rewards_providers.dart';
import '../../../../../core/constants/asset_paths.dart';

import 'package:go_router/go_router.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../widgets/quick_services_header.dart';
import '../../../data/models/quick_service_booking_data.dart';
import '../../widgets/quick_services_price_summary.dart';

class TruckMechanicReviewScreen extends ConsumerStatefulWidget {
  final QuickServiceBookingData bookingData;
  const TruckMechanicReviewScreen({super.key, required this.bookingData});

  @override
  ConsumerState<TruckMechanicReviewScreen> createState() => _TruckMechanicReviewScreenState();
}

class _TruckMechanicReviewScreenState extends ConsumerState<TruckMechanicReviewScreen> {
  bool _useGoCoins = false;
  late QuickServiceBookingData _bookingData;
  bool _useCoins = false;

  @override
  void initState() {
    super.initState();
    _bookingData = widget.bookingData;
  }

  bool useCoins = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const QuickServicesHeader(title: 'Review & Book', subtitle: 'Truck Mechanic'),
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
                        _buildDetailRow('Vehicle Type', _bookingData.truckType ?? '-'),
                        const SizedBox(height: 8),
                        _buildDetailRow('Make & Model', '${_bookingData.vehicleMake ?? ''} ${_bookingData.vehicleModel ?? ''}'.trim()),
                        if (_bookingData.vehicleYear != null) ...[
                          const SizedBox(height: 8),
                          _buildDetailRow('Year', _bookingData.vehicleYear!),
                        ],
                        if (_bookingData.vehicleRegistration != null) ...[
                          const SizedBox(height: 8),
                          _buildDetailRow('Registration Number', _bookingData.vehicleRegistration!),
                        ],
                        if (_bookingData.mileage != null) ...[
                          const SizedBox(height: 8),
                          _buildDetailRow('Mileage', _bookingData.mileage!),
                        ],
                        const SizedBox(height: 8),
                        _buildDetailRow('Issue', _bookingData.vehicleIssue ?? '-'),
                        const Divider(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.calendar_today, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Schedule\n${_formatDate(_bookingData.scheduleDate)} • ${_bookingData.scheduleTime.format(context)}',
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
                                'Service Address\n${_bookingData.location.address}',
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
                                'Customer\n${_bookingData.userName}\n${_bookingData.userPhone} • ${_bookingData.userEmail}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (_bookingData.whatYouNeed != null || _bookingData.describeIssue != null || (_bookingData.uploadedImages?.isNotEmpty ?? false)) ...[
                    const SizedBox(height: 20),
                    Text('Issue Description', style: AppTextStyles.titleSmall),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.withOpacity(0.3)), borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_bookingData.whatYouNeed != null) ...[
                            const Text('What You Need:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF324461))),
                            const SizedBox(height: 4),
                            Text(_bookingData.whatYouNeed!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            if (_bookingData.describeIssue != null || (_bookingData.uploadedImages?.isNotEmpty ?? false)) const SizedBox(height: 12),
                          ],
                          if (_bookingData.describeIssue != null) ...[
                            const Text('Issue Description:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF324461))),
                            const SizedBox(height: 4),
                            Text(_bookingData.describeIssue!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            if (_bookingData.uploadedImages?.isNotEmpty ?? false) const SizedBox(height: 12),
                          ],
                          if (_bookingData.uploadedImages?.isNotEmpty ?? false) ...[
                            const Text('Uploaded Photos:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF324461))),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _bookingData.uploadedImages!.map((path) {
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
                  
                                    QuickServicesPriceSummary(
                    bookingData: _bookingData,
                    useGoCoins: _useGoCoins,
                    onGoCoinsChanged: (val) => setState(() => _useGoCoins = val),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: AppColors.primaryGold),
                      const SizedBox(width: 8),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: ElevatedButton(
            onPressed: () {
                  final finalTotal = _bookingData.upfrontBookingFee - (_useGoCoins ? 2.0 : 0.0);
                      
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => BookingPaymentSheet(
                      currentType: _bookingData.paymentMethodType,
                      currentCardId: _bookingData.paymentMethodId,
                      isQuickService: true,
                      amount: finalTotal,
                      onConfirm: (type, {cardId}) {
                        final updatedData = _bookingData.copyWith(
                          paymentMethodType: type,
                          paymentMethodId: cardId,
                          useGoCoins: _useGoCoins,
                        );
                        context.pushNamed(
                          RouteNames.quickServicesTruckMechanicConfirmation,
                          extra: updatedData,
                        );
                      },
                    ),
                  );
                },
            style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text('Confirm Booking', style: AppTextStyles.button.copyWith(color: Colors.black)),
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
