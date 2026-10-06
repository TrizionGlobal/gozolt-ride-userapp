import '../../providers/quick_services_booking_provider.dart';
import '../../../../../core/widgets/booking_payment_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../widgets/quick_services_header.dart';
import '../../../data/models/quick_service_booking_data.dart';
import '../../widgets/quick_services_price_summary.dart';
import '../../widgets/quick_services_booking_summary.dart';
import '../../../../ride/data/models/saved_payment_method.dart';

class BeautyWellnessReviewScreen extends ConsumerStatefulWidget {
  final QuickServiceBookingData bookingData;
  const BeautyWellnessReviewScreen({super.key, required this.bookingData});

  @override
  ConsumerState<BeautyWellnessReviewScreen> createState() => _BeautyWellnessReviewScreenState();
}

class _BeautyWellnessReviewScreenState extends ConsumerState<BeautyWellnessReviewScreen> {
  bool _useGoCoins = false;
  bool _isBooking = false;
  late QuickServiceBookingData _bookingData;

  @override
  void initState() {
    super.initState();
    _bookingData = widget.bookingData;
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
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
            subtitle: 'Beauty & Wellness • ${_bookingData.selectedServiceTitle ?? 'Female'}',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  QuickServicesBookingSummary(
                    bookingData: _bookingData,
                    icon: Icons.spa,
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
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
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
                      context.pushNamed(RouteNames.quickServicesBeautyWellnessConfirmation, extra: updatedData.copyWith(bookingId: bookingId));
                    } else {
                      if (mounted) _showErrorSnackBar('Failed to book service');
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
                            context.pushNamed(RouteNames.quickServicesBeautyWellnessConfirmation, extra: updatedData.copyWith(bookingId: bookingId));
                            return true;
                          } else {
                            if (mounted) _showErrorSnackBar('Failed to book service');
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
}
