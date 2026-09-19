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
import '../../widgets/quick_services_booking_summary.dart';
import '../../../../ride/data/models/saved_payment_method.dart';

class CarpenterReviewScreen extends ConsumerStatefulWidget {
  final QuickServiceBookingData bookingData;
  const CarpenterReviewScreen({super.key, required this.bookingData});

  @override
  ConsumerState<CarpenterReviewScreen> createState() => _CarpenterReviewScreenState();
}

class _CarpenterReviewScreenState extends ConsumerState<CarpenterReviewScreen> {
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
          const QuickServicesHeader(
            currentStep: 2,title: 'Review & Book', subtitle: 'Carpenter'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              QuickServicesBookingSummary(
                bookingData: _bookingData,
                icon: Icons.carpenter,
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
                onPressed: () {
                  final finalTotal = (_bookingData.upfrontBookingFee - (_useGoCoins ? _bookingData.upfrontBookingFee.clamp(0.0, 6.0) : 0.0)).clamp(0.0, double.infinity);
                      
                  if (finalTotal <= 0.0) {
                    final updatedData = _bookingData.copyWith(
                      paymentMethodType: PaymentMethodType.cash,
                      useGoCoins: _useGoCoins,
                    );
                    context.pushNamed(
                      RouteNames.quickServicesCarpenterConfirmation,
                      extra: updatedData,
                    );
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
                        onConfirm: (type, {cardId}) {
                          final updatedData = _bookingData.copyWith(
                            paymentMethodType: type,
                            paymentMethodId: cardId,
                            useGoCoins: _useGoCoins,
                          );
                          context.pushNamed(
                            RouteNames.quickServicesCarpenterConfirmation,
                            extra: updatedData,
                          );
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
                    child: Text('Confirm Booking', style: AppTextStyles.button.copyWith(color: Colors.black)),
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
