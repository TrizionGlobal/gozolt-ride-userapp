import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/datasources/payment_remote_datasource.dart';

class StripeAddCardSheet extends StatefulWidget {
  final PaymentRemoteDatasource datasource;
  final VoidCallback onCardAdded;

  const StripeAddCardSheet({
    super.key,
    required this.datasource,
    required this.onCardAdded,
  });

  @override
  State<StripeAddCardSheet> createState() => _StripeAddCardSheetState();
}

class _StripeAddCardSheetState extends State<StripeAddCardSheet> {
  bool _cardComplete = false;
  bool _isLoading = false;
  String? _error;

  Future<void> _saveCard() async {
    if (!_cardComplete || _isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1. Get SetupIntent client secret from backend
      final clientSecret = await widget.datasource.createSetupIntent();

      // 2. Confirm the SetupIntent with Stripe (card data never touches our server)
      await Stripe.instance.confirmSetupIntent(
        paymentIntentClientSecret: clientSecret,
        params: const PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(),
        ),
      );

      // 3. Success — notify parent to refresh
      if (mounted) {
        widget.onCardAdded();
        Navigator.of(context).pop();
      }
    } on StripeException catch (e) {
      if (kDebugMode) print('[Stripe] Error: ${e.error.localizedMessage}');
      setState(() {
        _error = e.error.localizedMessage ?? 'Failed to save card. Please try again.';
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) print('[Stripe] Unexpected error: $e');
      setState(() {
        _error = 'Something went wrong. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderDark,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            'Add Payment Card',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your card details are securely handled by Stripe. We never store your card number.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // Stripe CardFormField
          CardFormField(
            enablePostalCode: false,
            style: CardFormStyle(
              backgroundColor: AppColors.cardDark,
              textColor: AppColors.textPrimary,
              placeholderColor: AppColors.textMuted,
              borderColor: AppColors.borderDark,
              borderWidth: 1,
              borderRadius: 12,
              cursorColor: AppColors.primaryGold,
              textErrorColor: AppColors.error,
            ),
            onCardChanged: (card) {
              setState(() {
                _cardComplete = card?.complete ?? false;
              });
            },
          ),
          const SizedBox(height: 8),

          // Error message
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _error!,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
              ),
            ),

          const SizedBox(height: 12),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _cardComplete && !_isLoading ? _saveCard : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: AppColors.backgroundDark,
                disabledBackgroundColor: AppColors.cardDark,
                disabledForegroundColor: AppColors.textMuted,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.backgroundDark,
                      ),
                    )
                  : Text(
                      'Save Card',
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.backgroundDark,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
