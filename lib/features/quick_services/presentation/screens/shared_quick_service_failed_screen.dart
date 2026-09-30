import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/booking_payment_sheet.dart';
import '../../data/models/quick_service_booking_data.dart';
import '../providers/quick_services_booking_provider.dart';

class SharedQuickServiceFailedScreen extends ConsumerStatefulWidget {
  final QuickServiceBookingData bookingData;
  final IconData serviceIcon;
  final String defaultTitle;
  final String onRetrySuccessRouteName;

  const SharedQuickServiceFailedScreen({
    super.key,
    required this.bookingData,
    required this.serviceIcon,
    required this.defaultTitle,
    required this.onRetrySuccessRouteName,
  });

  @override
  ConsumerState<SharedQuickServiceFailedScreen> createState() => _SharedQuickServiceFailedScreenState();
}

class _SharedQuickServiceFailedScreenState extends ConsumerState<SharedQuickServiceFailedScreen> {
  bool _isRetrying = false;

  void _showPaymentSheet() {
    final finalTotal = ((widget.bookingData.upfrontBookingFee + widget.bookingData.materialCost) - 
                        (widget.bookingData.useGoCoins ? (widget.bookingData.upfrontBookingFee + widget.bookingData.materialCost).clamp(0.0, 6.0) : 0.0))
                       .clamp(0.0, double.infinity);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BookingPaymentSheet(
        currentType: widget.bookingData.paymentMethodType,
        currentCardId: widget.bookingData.paymentMethodId,
        isQuickService: true,
        amount: finalTotal,
        onConfirm: (type, {cardId}) async {
          final updatedData = widget.bookingData.copyWith(
            paymentMethodType: type,
            paymentMethodId: cardId,
          );
          
          setState(() => _isRetrying = true);
          final bookingId = await ref.read(quickServicesBookingProvider.notifier).bookQuickService(updatedData);
          if (mounted) setState(() => _isRetrying = false);
          
          if (bookingId != null && mounted) {
            context.replaceNamed(
              widget.onRetrySuccessRouteName,
              extra: updatedData,
            );
            return true;
          } else {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment failed again. Please try another card.')));
            return false;
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 80),
              const SizedBox(height: 24),
              Text(
                'Payment Failed',
                textAlign: TextAlign.center,
                style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'We couldn\'t process your payment for the ${widget.bookingData.selectedServiceTitle ?? widget.defaultTitle} booking.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[700]),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Please try again or use a different payment method to complete your booking.',
                        style: AppTextStyles.bodySmall.copyWith(color: Colors.redAccent[700]),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isRetrying ? null : _showPaymentSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  minimumSize: const Size.fromHeight(50),
                ),
                child: _isRetrying
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                    : const Text('Retry Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => context.pop(), // Go back to review screen
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size.fromHeight(50),
                ),
                child: Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
