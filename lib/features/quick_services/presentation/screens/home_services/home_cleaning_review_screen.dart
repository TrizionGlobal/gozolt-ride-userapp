import '../../providers/quick_services_booking_provider.dart';
import '../../../../../core/widgets/booking_payment_sheet.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/quick_services_payment_selector.dart';
import '../../../../rewards/presentation/providers/rewards_providers.dart';
import '../../../../../core/constants/asset_paths.dart';

import 'package:go_router/go_router.dart';
import '../../widgets/quick_services_additional_details_review.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../widgets/quick_services_header.dart';
import '../../../data/models/quick_service_booking_data.dart';
import '../../widgets/quick_services_price_summary.dart';
import '../../../../ride/data/models/saved_payment_method.dart';


class HomeCleaningReviewScreen extends ConsumerStatefulWidget {
  final QuickServiceBookingData bookingData;
  const HomeCleaningReviewScreen({super.key, required this.bookingData});

  @override
  ConsumerState<HomeCleaningReviewScreen> createState() => _HomeCleaningReviewScreenState();
}

class _HomeCleaningReviewScreenState extends ConsumerState<HomeCleaningReviewScreen> {
  bool _useGoCoins = false;
  bool _isBooking = false;
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
          const QuickServicesHeader(
            currentStep: 2,title: 'Review & Book', subtitle: 'Home Cleaning'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGold.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.cleaning_services,
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
                    const SizedBox(height: 16),
                    // Date & Time
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                        const SizedBox(width: 10),
                        Text('${_formatDate(_bookingData.scheduleDate)} • ${_bookingData.scheduleTime.format(context)}', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Location
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on, size: 18, color: Colors.grey),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _bookingData.location.address,
                            style: AppTextStyles.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Customer
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.person, size: 18, color: Colors.grey),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Customer: ${_bookingData.userName}', style: AppTextStyles.bodySmall),
                              const SizedBox(height: 2),
                              Text('Email: ${_bookingData.userEmail}', style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[600], fontSize: 12)),
                              const SizedBox(height: 2),
                              Text('Phone: ${_bookingData.userPhone}', style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[600], fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_bookingData.materialPreference != null && _bookingData.materialPreference!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 18, color: Colors.grey),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text('Materials: ${_bookingData.materialPreference}', style: AppTextStyles.bodySmall),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              QuickServicesPriceSummary(bookingData: _bookingData, useGoCoins: _useGoCoins, onGoCoinsChanged: (val) => setState(() => _useGoCoins = val),),
              const SizedBox(height: 20),
              
                            
              const SizedBox(height: 8),
              ],
            ),
          )),
          
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
                        context.pushNamed(RouteNames.quickServicesHomeCleaningConfirmation, extra: updatedData.copyWith(bookingId: bookingId));
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
                              context.pushNamed(RouteNames.quickServicesHomeCleaningConfirmation, extra: updatedData.copyWith(bookingId: bookingId));
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
    double total = _bookingData.estimatedTotalMin;
    if (useCoins) total -= 2.00;
    return total > 0 ? total : 0;
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return '${date.day} ${months[date.month - 1]} ${date.year} • ${weekdays[date.weekday - 1]}';
  }
}
