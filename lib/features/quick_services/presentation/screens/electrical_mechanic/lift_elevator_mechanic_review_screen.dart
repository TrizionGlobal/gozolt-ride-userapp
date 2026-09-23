import '../../providers/quick_services_booking_provider.dart';
import '../../../../../core/widgets/booking_payment_sheet.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/quick_services_payment_selector.dart';
import '../../../../rewards/presentation/providers/rewards_providers.dart';
import '../../../../../core/constants/asset_paths.dart';

import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/router/route_names.dart';
import '../../../data/models/quick_service_booking_data.dart';
import '../../widgets/quick_services_price_summary.dart';
import '../../widgets/quick_services_header.dart';
import '../../../../ride/data/models/saved_payment_method.dart';


class LiftElevatorMechanicReviewScreen extends ConsumerStatefulWidget {
  final QuickServiceBookingData bookingData;
  const LiftElevatorMechanicReviewScreen({super.key, required this.bookingData});

  @override
  ConsumerState<LiftElevatorMechanicReviewScreen> createState() => _LiftElevatorMechanicReviewScreenState();
}

class _LiftElevatorMechanicReviewScreenState extends ConsumerState<LiftElevatorMechanicReviewScreen> {
  bool _useGoCoins = false;
  bool _isBooking = false;
  late QuickServiceBookingData _bookingData;
  bool _useCoins = false;

  @override
  void initState() {
    super.initState();
    _bookingData = widget.bookingData;
  }

  bool useCoins = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      bottomNavigationBar: Column(mainAxisSize: MainAxisSize.min, children: [
          
          const SizedBox(height: 16),
          
          const SizedBox(height: 16),
 SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: ElevatedButton(
            onPressed: _isBooking ? null : () async {

                  final finalTotal = ((_bookingData.upfrontBookingFee + _bookingData.materialCost) - (_useGoCoins ? (_bookingData.upfrontBookingFee + _bookingData.materialCost).clamp(0.0, 6.0) : 0.0)).clamp(0.0, double.infinity);
                      
                  if (finalTotal <= 0.0) {
                    final updatedData = _bookingData.copyWith(
                      paymentMethodType: PaymentMethodType.cash,
                      useGoCoins: _useGoCoins,
                    );
                    
                      setState(() => _isBooking = true);
                      final bookingId = await ref.read(quickServicesBookingProvider.notifier).bookQuickService(updatedData);
                      if (mounted) setState(() => _isBooking = false);
                      if (bookingId != null && mounted) {
                        context.pushNamed(RouteNames.quickServicesLiftElevatorConfirmation, extra: updatedData);
                      } else {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to book service')));
                      }
                    } else {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => BookingPaymentSheet(
                          currentType: _bookingData.paymentMethodType,
                          currentCardId: _bookingData.paymentMethodId,
                          isQuickService: true,
                          amount: finalTotal,
                          onConfirm: (type, {cardId}) async {
                            final updatedData = _bookingData.copyWith(
                            paymentMethodType: type,
                            paymentMethodId: cardId,
                            useGoCoins: _useGoCoins,
                          );
                            final bookingId = await ref.read(quickServicesBookingProvider.notifier).bookQuickService(updatedData);
                            if (bookingId != null && mounted) {
                              context.pushNamed(RouteNames.quickServicesLiftElevatorConfirmation, extra: updatedData);
                              return true;
                            } else {
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to book service')));
                              return false;
                            }
                          },
                        ),
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isBooking ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : Text('Confirm Booking', style: AppTextStyles.button.copyWith(color: Colors.black)),
          ),
        ),
      ),
      ],),
      body: Column(
        children: [
          const QuickServicesHeader(
            currentStep: 2,
            title: 'Review & Book',
            subtitle: 'Commercial Mechanic',
          ),
          
          // Certified technician required banner
          Container(
            width: double.infinity,
            color: AppColors.primaryGold.withOpacity(0.2),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.verified, color: AppColors.primaryGold, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Certified technician required',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Service Summary',
                    style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        _buildSummaryRow('Service', _bookingData.selectedServiceTitle ?? 'N/A'),
                        _buildSummaryRow('Property Type', _bookingData.propertyType ?? 'N/A'),
                        _buildSummaryRow('Lift Type', _bookingData.liftType ?? 'N/A'),
                        _buildSummaryRow('Manufacturer / Model', '${_bookingData.vehicleMake ?? 'Unknown'} ${_bookingData.vehicleModel ?? ''}'.trim()),
                        _buildSummaryRow('Floors Served', _bookingData.floorsServed ?? 'Not specified'),
                        _buildSummaryRow('Issue', _bookingData.vehicleIssue ?? 'N/A'),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  _buildSectionHeader(Icons.calendar_today, 'Schedule'),
                  Padding(
                    padding: const EdgeInsets.only(left: 28.0),
                    child: Text(
                      _formatDate(_bookingData.scheduleDate, _bookingData.scheduleTime),
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  _buildSectionHeader(Icons.location_on, 'Service Address'),
                  Padding(
                    padding: const EdgeInsets.only(left: 28.0),
                    child: Text(
                      _bookingData.location.address,
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  _buildSectionHeader(Icons.person, 'Customer'),
                  Padding(
                    padding: const EdgeInsets.only(left: 28.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _bookingData.userName,
                          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_bookingData.userPhone} • ${_bookingData.userEmail}',
                          style: AppTextStyles.bodySmall.copyWith(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  
                  if (_bookingData.whatYouNeed != null) ...[
                    const SizedBox(height: 16),
                    _buildSectionHeader(Icons.info_outline, 'What You Need'),
                    Padding(
                      padding: const EdgeInsets.only(left: 28.0),
                      child: Text(
                        _bookingData.whatYouNeed!,
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  ],

                  if (_bookingData.describeIssue != null) ...[
                    const SizedBox(height: 16),
                    _buildSectionHeader(Icons.description, 'Issue Description'),
                    Padding(
                      padding: const EdgeInsets.only(left: 28.0),
                      child: Text(
                        _bookingData.describeIssue!,
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  ],

                  if (_bookingData.uploadedImages != null && _bookingData.uploadedImages!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildSectionHeader(Icons.photo_library, 'Uploaded Photos'),
                    Padding(
                      padding: const EdgeInsets.only(left: 28.0),
                      child: SizedBox(
                        height: 60,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _bookingData.uploadedImages!.length,
                          itemBuilder: (context, index) {
                            return Container(
                              width: 60,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: FileImage(File(_bookingData.uploadedImages![index])),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                  
                  QuickServicesPriceSummary(bookingData: _bookingData, useGoCoins: _useGoCoins, onGoCoinsChanged: (val) => setState(() => _useGoCoins = val),),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Image.asset('assets/images/go_coin.png', width: 20, height: 20, errorBuilder: (c, e, s) => const Icon(Icons.monetization_on, size: 20, color: AppColors.primaryGold)),
                                const SizedBox(width: 8),
                                const Text('GO Coins Available', style: TextStyle(fontSize: 14)),
                              ],
                            ),
                            Row(
                              children: [
                                Image.asset('assets/images/go_coin.png', width: 14, height: 14, errorBuilder: (c, e, s) => const Icon(Icons.monetization_on, size: 14, color: AppColors.primaryGold)),
                                const SizedBox(width: 4),
                                const Text('250', style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Use GO Coins', style: TextStyle(fontSize: 14)),
                            Switch(
                              value: useCoins,
                              activeColor: AppColors.primaryGold,
                              onChanged: (v) => setState(() => useCoins = v),
                            ),
                          ],
                        ),
                                              ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isMultiLine = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF324461),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 16.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF324461)),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF324461),
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

  String _formatDate(DateTime date, TimeOfDay time) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return '${date.day} ${months[date.month - 1]} ${date.year} • ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} (${weekdays[date.weekday - 1]})';
  }
}
