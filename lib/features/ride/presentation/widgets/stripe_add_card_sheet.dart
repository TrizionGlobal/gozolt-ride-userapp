import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/datasources/payment_remote_datasource.dart';

class StripeAddCardSheet extends StatefulWidget {
  final PaymentRemoteDatasource datasource;
  final void Function(String? paymentMethodId) onCardAdded;
  final double? amount;

  const StripeAddCardSheet({
    super.key,
    required this.datasource,
    required this.onCardAdded,
    this.amount,
  });

  @override
  State<StripeAddCardSheet> createState() => _StripeAddCardSheetState();
}

class _StripeAddCardSheetState extends State<StripeAddCardSheet> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isCardComplete = false;
  String _selectedCardType = 'Credit'; // 'Credit' or 'Debit'
  Key _cardFieldKey = UniqueKey();
  final TextEditingController _nameController = TextEditingController();
  String? _error;
  String? _clientSecret;

  @override
  void initState() {
    super.initState();
    _fetchIntent();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _fetchIntent() async {
    try {
      if (widget.amount != null) {
        final data = await widget.datasource.createPaymentSheet(widget.amount!);
        _clientSecret = data['paymentIntent'];
      } else {
        final data = await widget.datasource.createSetupIntent();
        _clientSecret = data['clientSecret'];
      }
      setState(() => _isLoading = false);
    } catch (e) {
      if (kDebugMode) print('[Stripe] Fetch intent error: $e');
      setState(() {
        _error = 'Failed to connect to secure server.';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveCard() async {
    if (!_isCardComplete || _clientSecret == null) return;
    
    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      if (widget.amount != null) {
        final paymentIntent = await Stripe.instance.confirmPayment(
          paymentIntentClientSecret: _clientSecret!,
          data: PaymentMethodParams.card(
            paymentMethodData: PaymentMethodData(
              billingDetails: BillingDetails(
                name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
              ),
            ),
          ),
        );
        Navigator.of(context).pop();
        widget.onCardAdded(paymentIntent.paymentMethodId);
      } else {
        final setupIntent = await Stripe.instance.confirmSetupIntent(
          paymentIntentClientSecret: _clientSecret!,
          params: PaymentMethodParams.card(
            paymentMethodData: PaymentMethodData(
              billingDetails: BillingDetails(
                name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
              ),
            ),
          ),
        );
        Navigator.of(context).pop();
        widget.onCardAdded(setupIntent.paymentMethodId);
      }
    } on StripeException catch (e) {
      if (e.error.code != FailureCode.Canceled) {
        setState(() => _error = e.error.localizedMessage ?? 'Payment failed.');
      }
    } catch (e) {
      setState(() => _error = 'An unexpected error occurred.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            
            Text(
              widget.amount != null ? 'Complete Payment' : 'Secure Payment Method',
              style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w800),
            ),
            
            const SizedBox(height: 32),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(child: CircularProgressIndicator(color: AppColors.primaryGold)),
              )
            else ...[
                const SizedBox(height: 20),
                SizedBox(
                  height: 42,
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTypeSelector(
                          title: 'Credit Card',
                          icon: Icons.credit_card,
                          isSelected: _selectedCardType == 'Credit',
                          onTap: () {
                            if (_selectedCardType != 'Credit') {
                              setState(() {
                                _selectedCardType = 'Credit';
                                _cardFieldKey = UniqueKey();
                                _isCardComplete = false;
                              });
                            }
                          },
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTypeSelector(
                          title: 'Debit Card',
                          icon: Icons.account_balance_wallet_outlined,
                          isSelected: _selectedCardType == 'Debit',
                          onTap: () {
                            if (_selectedCardType != 'Debit') {
                              setState(() {
                                _selectedCardType = 'Debit';
                                _cardFieldKey = UniqueKey();
                                _isCardComplete = false;
                              });
                            }
                          },
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: isDark ? AppColors.borderDark : Colors.grey[300]!),
                borderRadius: BorderRadius.circular(20),
                color: isDark ? AppColors.surfaceDark : const Color(0xFFF9FAFB),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CARDHOLDER NAME',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!, width: 1.2),
                      borderRadius: BorderRadius.circular(8),
                      color: isDark ? AppColors.inputDark : Colors.white,
                    ),
                    child: Center(
                      child: TextField(
                        controller: _nameController,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          hintText: 'Name on card',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    'CARD NUMBER & DETAILS',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!, width: 1.2),
                      borderRadius: BorderRadius.circular(8),
                      color: isDark ? AppColors.inputDark : Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black26 : Colors.black.withOpacity(0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Center(
                      child: CardField(
                        key: _cardFieldKey,
                        onCardChanged: (card) {
                          setState(() {
                            _isCardComplete = card?.complete ?? false;
                          });
                        },
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          hintStyle: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[400],
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),

            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: (_isSaving || !_isCardComplete) ? null : _saveCard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: Theme.of(context).scaffoldBackgroundColor,
                  disabledBackgroundColor: Theme.of(context).dividerTheme.color ?? AppColors.cardDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isSaving
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).scaffoldBackgroundColor),
                      )
                    : Text(
                        widget.amount != null ? 'Pay Now' : 'Save Card',
                        style: AppTextStyles.button.copyWith(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Powered by Stripe',
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
        ],
      ),
      ),
    );
  }

  Widget _buildTypeSelector({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark ? AppColors.primaryGold.withOpacity(0.15) : AppColors.primaryGold.withOpacity(0.05))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primaryGold : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? AppColors.primaryGold : (isDark ? Colors.grey[400] : Colors.grey[600])),
            const SizedBox(width: 6),
            Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isSelected ? AppColors.primaryGold : (isDark ? Colors.grey[300] : Colors.grey[800]),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

