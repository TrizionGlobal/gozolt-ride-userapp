import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../features/ride/presentation/widgets/payment_brand_icon.dart';
import '../../features/ride/data/models/saved_payment_method.dart';
import '../../features/ride/data/datasources/payment_remote_datasource.dart';
import '../../features/ride/presentation/providers/ride_providers.dart';
import '../../features/ride/presentation/widgets/stripe_add_card_sheet.dart';

class BookingPaymentSheet extends ConsumerStatefulWidget {
  final PaymentMethodType currentType;
  final String? currentCardId;
  final bool isQuickService;
  final double? amount;
  final Future<bool?> Function(PaymentMethodType type, {String? cardId}) onConfirm;

  const BookingPaymentSheet({
    super.key,
    required this.currentType,
    this.currentCardId,
    this.isQuickService = false,
    this.amount,
    required this.onConfirm,
  });

  @override
  ConsumerState<BookingPaymentSheet> createState() =>
      _BookingPaymentSheetState();
}

class _BookingPaymentSheetState extends ConsumerState<BookingPaymentSheet> {
  late PaymentMethodType _selectedType;
  String? _selectedCardId;
  bool _isLoading = false;
  bool _payFullAmount = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.currentType;
    _selectedCardId = widget.currentCardId;
    if (widget.isQuickService) {
      if (widget.currentType == PaymentMethodType.cash) {
        _selectedCardId = null;
      }
      _selectedType = PaymentMethodType.card;
      // If currentType is card, they paid full amount. If cash, they chose postpaid.
      _payFullAmount = widget.currentType == PaymentMethodType.card;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(paymentMethodsProvider);
    });
  }

  Future<void> _confirm() async {
    if (widget.isQuickService && _selectedCardId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a card to pay the upfront fee.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });
    // Brief loading state for UX
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    
    final result = await widget.onConfirm(_selectedType, cardId: _selectedCardId);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      if (result == true) {
        Navigator.of(context).pop();
      }
    }
  }

  void _addCard() {
    final ds = ref.read(paymentRemoteDatasourceProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StripeAddCardSheet(
        datasource: ds,
        
        amount: widget.isQuickService ? null : widget.amount,
        onCardAdded: (paymentMethodId) async {
          if (paymentMethodId != null) {
            if (widget.isQuickService) {
              // Quick Service: Immediately confirm booking with the new payment method
              final result = await widget.onConfirm(PaymentMethodType.card, cardId: paymentMethodId);
              if (result == true && mounted) {
                Navigator.of(context).pop();
              }
            } else {
              // Live Services (Cab, Car, Bike): Save card and update UI selection
              try {
                await ds.confirmSetupIntent(paymentMethodId);
              } catch (_) {}
              ref.invalidate(paymentMethodsProvider);
              setState(() {
                _selectedType = PaymentMethodType.card;
                _selectedCardId = paymentMethodId;
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Card saved successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;
    final secondaryTextColor =
        isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;
    final cardColor = Theme.of(context).cardTheme.color;
    final borderColor =
        Theme.of(context).dividerTheme.color ?? AppColors.borderDark;
    final paymentMethodsAsync = ref.watch(paymentMethodsProvider);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 16, bottom: 20),
            decoration: BoxDecoration(
              color: borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payment Method',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close,
                        size: 16,
                        color: isDark ? Colors.white70 : Colors.black54),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Options
          paymentMethodsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primaryGold)),
            ),
            error: (_, __) => _buildOptions(
                [], cardColor, borderColor, textColor, secondaryTextColor),
            data: (methods) => _buildOptions(
                methods, cardColor, borderColor, textColor, secondaryTextColor),
          ),

          if (_selectedType == PaymentMethodType.card && !widget.isQuickService)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.primaryGold, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'A temporary pre-authorization hold will be placed on your card for the estimated amount to verify funds. The actual amount will be charged only after the ride completes.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: textColor,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Confirm button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: (_isLoading || paymentMethodsAsync.isLoading) ? null : _confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isLoading 
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : Text(
                        'Confirm',
                        style: AppTextStyles.titleSmall.copyWith(
                            color: Colors.black, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptions(
    List<SavedPaymentMethod> methods,
    Color? cardColor,
    Color borderColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    final cashTitle = widget.isQuickService ? 'Pay After Service (Postpaid)' : 'Cash';
    final cashSubtitle = widget.isQuickService ? 'Pay when the job is done' : 'Pay the driver directly';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          if (!widget.isQuickService) ...[
            // Cash option
          _buildOptionTile(
            icon: Icons.payments_outlined,
            title: cashTitle,
            subtitle: cashSubtitle,
            isSelected: _selectedType == PaymentMethodType.cash,
            cardColor: cardColor,
            borderColor: borderColor,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            onTap: () => setState(() {
              _selectedType = PaymentMethodType.cash;
              _selectedCardId = null;
            }),
          ),
          const SizedBox(height: 10),
          ],
          


          // Saved cards
          ...methods.map((pm) {
            final isSelected = _selectedType == PaymentMethodType.card &&
                _selectedCardId == pm.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => setState(() {
                  _selectedType = PaymentMethodType.card;
                  _selectedCardId = pm.id;
                }),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.primaryGold : borderColor,
                      width: isSelected ? 1.5 : 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      PaymentBrandIcon(brand: pm.brand),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(pm.displayName,
                                style: AppTextStyles.titleSmall
                                    .copyWith(color: textColor)),
                            Text(
                                pm.isDefault ? 'Default card' : 'Saved card',
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: secondaryTextColor)),
                          ],
                        ),
                      ),
                      if (pm.isDefault)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGold.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Default',
                            style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primaryGold,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      _radioCircle(isSelected),
                    ],
                  ),
                ),
              ),
            );
          }),

          // Add New Card
          _buildOptionTile(
            icon: Icons.add_circle_outline,
            title: 'Add New Card',
            subtitle: 'Credit / Debit Card',
            isSelected: false,
            cardColor: cardColor,
            borderColor: borderColor,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            onTap: _addCard,
          ),
          const SizedBox(height: 16),
          if (widget.isQuickService) ...[

          ],
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required Color? cardColor,
    required Color borderColor,
    required Color textColor,
    required Color secondaryTextColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primaryGold : borderColor,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 28,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryGold.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon,
                  color: isSelected
                      ? AppColors.primaryGold
                      : AppColors.textSecondary,
                  size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style:
                          AppTextStyles.titleSmall.copyWith(color: textColor)),
                  Text(subtitle,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: secondaryTextColor)),
                ],
              ),
            ),
            _radioCircle(isSelected),
          ],
        ),
      ),
    );
  }

  Widget _radioCircle(bool isSelected) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? AppColors.primaryGold : AppColors.textMuted,
          width: 2,
        ),
      ),
      child: isSelected
          ? Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryGold,
                ),
              ),
            )
          : null,
    );
  }
}
