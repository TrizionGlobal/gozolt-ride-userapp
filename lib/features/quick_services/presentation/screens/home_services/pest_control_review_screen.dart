import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/widgets/booking_payment_sheet.dart';
import '../../../data/models/quick_service_booking_data.dart';
import '../../widgets/quick_services_header.dart';
import '../../widgets/quick_services_booking_summary.dart';
import '../../widgets/quick_services_price_summary.dart';
import '../../../../ride/data/models/saved_payment_method.dart';


class PestControlReviewScreen extends ConsumerStatefulWidget {
  final QuickServiceBookingData bookingData;
  const PestControlReviewScreen({super.key, required this.bookingData});

  @override
  ConsumerState<PestControlReviewScreen> createState() => _PestControlReviewScreenState();
}

class _PestControlReviewScreenState extends ConsumerState<PestControlReviewScreen> {
  late QuickServiceBookingData _bookingData;
  bool _useGoCoins = false;

  @override
  void initState() {
    super.initState();
    _bookingData = widget.bookingData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const QuickServicesHeader(
            currentStep: 2,
            title: 'Review & Book',
            subtitle: 'Pest Control',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  QuickServicesBookingSummary(
                    bookingData: _bookingData,
                    icon: Icons.bug_report,
                  ),
                  const SizedBox(height: 12),
                  QuickServicesPriceSummary(
                    bookingData: _bookingData, 
                    useGoCoins: _useGoCoins, 
                    onGoCoinsChanged: (val) => setState(() => _useGoCoins = val),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: ElevatedButton(
                onPressed: () {
                  final finalTotal = (_bookingData.upfrontBookingFee - (_useGoCoins ? _bookingData.upfrontBookingFee.clamp(0.0, 6.0) : 0.0)).clamp(0.0, double.infinity);
                      
                  if (finalTotal <= 0.0) {
                    final updatedData = _bookingData.copyWith(
                      paymentMethodType: PaymentMethodType.cash,
                      useGoCoins: _useGoCoins,
                    );
                    context.pushNamed(
                      RouteNames.quickServicesPestControlConfirmation,
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
                            RouteNames.quickServicesPestControlConfirmation,
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
}
