import '../../providers/quick_services_booking_provider.dart';
import '../../../../../core/widgets/booking_payment_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/router/route_names.dart';
import '../../../data/models/quick_service_booking_data.dart';
import '../../../data/models/quick_services_coins_helper.dart';
import '../../widgets/quick_services_price_summary.dart';
import '../../widgets/quick_services_header.dart';
import '../../widgets/quick_services_booking_summary.dart';
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

  @override
  void initState() {
    super.initState();
    _bookingData = widget.bookingData.applyDraft();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          QuickServicesHeader(
            currentStep: 2,
            title: 'Review & Book',
            subtitle: _bookingData.selectedServiceTitle ?? 'Commercial Electric',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  QuickServicesBookingSummary(
                    bookingData: _bookingData,
                    icon: Icons.bolt,
                  ),
                  const SizedBox(height: 12),
                  QuickServicesPriceSummary(
                    bookingData: _bookingData,
                    useGoCoins: _useGoCoins,
                    onGoCoinsChanged: (val) => setState(() => _useGoCoins = val),
                  ),
                  const SizedBox(height: 20),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isBooking ? null : () async {
                    final payment = QuickServicesCoinsHelper.getPaymentDetails(
                      ref: ref,
                      upfrontRaw: _bookingData.upfrontBookingFee + _bookingData.materialCost,
                      useGoCoins: _useGoCoins,
                    );
                    final finalTotal = payment.finalTotal;
                    
                    if (finalTotal <= 0.0) {
                      final updatedData = _bookingData.copyWith(
                          paymentMethodType: PaymentMethodType.cash,
                          useGoCoins: _useGoCoins,
                          discountAmount: payment.discount,
                          coinsUsed: payment.coinsUsed,
                        );
                      
                      setState(() => _isBooking = true);
                      final bookingId = await ref.read(quickServicesBookingProvider.notifier).bookQuickService(updatedData);
                      if (mounted) setState(() => _isBooking = false);
                      if (bookingId != null && mounted) {
                        context.pushNamed(RouteNames.quickServicesLiftElevatorConfirmation, extra: updatedData.copyWith(bookingId: bookingId));
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
                              discountAmount: payment.discount,
                              coinsUsed: payment.coinsUsed,
                            );
                            final bookingId = await ref.read(quickServicesBookingProvider.notifier).bookQuickService(updatedData);
                            if (bookingId != null && mounted) {
                              context.pushNamed(RouteNames.quickServicesLiftElevatorConfirmation, extra: updatedData.copyWith(bookingId: bookingId));
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
                  child: _isBooking
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                        )
                      : Text('Confirm Booking', style: AppTextStyles.button.copyWith(color: Colors.black)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
