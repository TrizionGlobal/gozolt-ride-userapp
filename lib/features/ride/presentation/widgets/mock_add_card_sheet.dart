import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Mock "Add Card" bottom sheet that simulates a Stripe PaymentSheet.
/// Collects card number (last 4), expiry, and brand — no real payment processing.
class MockAddCardSheet extends StatefulWidget {
  /// Returns a map with keys: brand, last4, expMonth, expYear
  final ValueChanged<Map<String, dynamic>> onCardAdded;

  const MockAddCardSheet({super.key, required this.onCardAdded});

  @override
  State<MockAddCardSheet> createState() => _MockAddCardSheetState();
}

class _MockAddCardSheetState extends State<MockAddCardSheet> {
  final _numberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  String _selectedBrand = 'visa';
  bool _isSaving = false;

  @override
  void dispose() {
    _numberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
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
              const SizedBox(height: 16),

              Row(
                children: [
                  const Icon(Icons.add_card,
                      color: AppColors.primaryGold, size: 24),
                  const SizedBox(width: 8),
                  Text('Add Payment Card',
                      style: AppTextStyles.headlineSmall),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Mock mode \u2022 No real charges',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),

              // Brand selector
              Text('Card Brand',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _brandChip('visa', 'Visa'),
                  const SizedBox(width: 8),
                  _brandChip('mastercard', 'Mastercard'),
                  const SizedBox(width: 8),
                  _brandChip('amex', 'Amex'),
                ],
              ),
              const SizedBox(height: 16),

              // Card number
              TextField(
                controller: _numberController,
                keyboardType: TextInputType.number,
                maxLength: 19,
                inputFormatters: [_CardNumberFormatter()],
                style: AppTextStyles.bodyMedium,
                decoration: _inputDecoration('Card Number', '4242 4242 4242 4242'),
              ),
              const SizedBox(height: 12),

              // Expiry + CVV row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _expiryController,
                      keyboardType: TextInputType.number,
                      maxLength: 5,
                      inputFormatters: [_ExpiryFormatter()],
                      style: AppTextStyles.bodyMedium,
                      decoration: _inputDecoration('Expiry', 'MM/YY'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _cvvController,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      obscureText: true,
                      style: AppTextStyles.bodyMedium,
                      decoration: _inputDecoration('CVV', '123'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Add button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveCard,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    foregroundColor: AppColors.backgroundDark,
                    disabledBackgroundColor:
                        AppColors.primaryGold.withOpacity(0.3),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.backgroundDark),
                        )
                      : const Text('Add Card', style: AppTextStyles.button),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _brandChip(String value, String label) {
    final isSelected = _selectedBrand == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedBrand = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryGold.withOpacity(0.15)
              : AppColors.cardDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primaryGold : AppColors.borderDark,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: isSelected ? AppColors.primaryGold : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      labelStyle:
          AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
      hintText: hint,
      hintStyle:
          AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
      counterText: '',
      filled: true,
      fillColor: AppColors.inputDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryGold),
      ),
    );
  }

  Future<void> _saveCard() async {
    final number = _numberController.text.replaceAll(' ', '');
    final expiry = _expiryController.text;

    if (number.length < 4) {
      _showError('Please enter a valid card number');
      return;
    }
    if (expiry.length < 5) {
      _showError('Please enter a valid expiry date');
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    final parts = expiry.split('/');
    final expMonth = int.tryParse(parts[0]) ?? 12;
    final expYear = 2000 + (int.tryParse(parts[1]) ?? 28);

    widget.onCardAdded({
      'brand': _selectedBrand,
      'last4': number.substring(number.length - 4),
      'expMonth': expMonth,
      'expYear': expYear,
    });

    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }
}

// ── Input formatters ──────────────────────────────────────

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 16; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 4; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
