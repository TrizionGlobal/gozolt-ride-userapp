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
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Pre-initialize the payment sheet
    _initializePaymentSheet();
  }

  Future<void> _initializePaymentSheet() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1. Get SetupIntent client secret
      final clientSecret = await widget.datasource.createSetupIntent();

      // 2. Initialize Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          setupIntentClientSecret: clientSecret,
          merchantDisplayName: 'Gozolt Ride',
          style: ThemeMode.dark,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: AppColors.primaryGold,
              background: AppColors.surfaceDark,
              componentBackground: AppColors.cardDark,
              componentBorder: AppColors.borderDark,
              componentDivider: AppColors.borderDark,
              primaryText: Colors.white,
              secondaryText: AppColors.textMuted,
              placeholderText: AppColors.textMuted,
              icon: AppColors.primaryGold,
              error: AppColors.error,
            ),
          ),
        ),
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) print('[Stripe] Init error: $e');
      setState(() {
        _error = 'Failed to initialize Stripe. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _presentPaymentSheet() async {
    try {
      // 3. Show Payment Sheet
      await Stripe.instance.presentPaymentSheet();

      // 4. Success — notify parent
      if (mounted) {
        widget.onCardAdded();
        Navigator.of(context).pop();
      }
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        // User cancelled — ignore
        return;
      }
      setState(() {
        _error = e.error.localizedMessage ?? 'Failed to save payment method.';
      });
    } catch (e) {
      setState(() {
        _error = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderDark,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          
          Icon(Icons.payment_rounded, color: AppColors.primaryGold, size: 48),
          const SizedBox(height: 16),
          
          Text(
            'Secure Payment Method',
            style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your card or UPI ID for seamless ride booking. Your details are encrypted and securely stored by Stripe.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          
          const SizedBox(height: 32),
          
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_error!, style: TextStyle(color: AppColors.error, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _presentPaymentSheet,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: AppColors.backgroundDark,
                disabledBackgroundColor: AppColors.cardDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.backgroundDark),
                    )
                  : Text(
                      'Open Secure Payment UI',
                      style: AppTextStyles.button.copyWith(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Powered by Stripe',
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

