import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../ride/data/models/saved_payment_method.dart';
import '../../../ride/presentation/providers/ride_providers.dart';
import '../../../ride/presentation/widgets/payment_brand_icon.dart';
import '../../../ride/presentation/widgets/stripe_add_card_sheet.dart';

enum FoodGroceryPaymentSelection {
  card,
  online,
}

class FoodGroceryPaymentSheet extends ConsumerStatefulWidget {
  const FoodGroceryPaymentSheet({
    super.key,
    required this.currentType,
    this.currentCardId,
    this.isOnline = false,
    this.amount,
    required this.onConfirm,
  });

  final PaymentMethodType currentType;
  final String? currentCardId;
  final bool isOnline;
  final double? amount;
  final Future<bool> Function(
    PaymentMethodType type, {
    String? cardId,
    String? cardDisplayName,
    CardBrand? cardBrand,
    bool isOnline,
  }) onConfirm;

  @override
  ConsumerState<FoodGroceryPaymentSheet> createState() =>
      _FoodGroceryPaymentSheetState();
}

class _FoodGroceryPaymentSheetState
    extends ConsumerState<FoodGroceryPaymentSheet> {
  late FoodGroceryPaymentSelection _selectedOption;
  String? _selectedCardId;
  String? _selectedCardDisplayName;
  CardBrand? _selectedCardBrand;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isOnline) {
      _selectedOption = FoodGroceryPaymentSelection.online;
      _selectedCardId = null;
    } else {
      _selectedOption = FoodGroceryPaymentSelection.card;
      _selectedCardId = widget.currentCardId;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(paymentMethodsProvider);
    });
  }

  Future<void> _addCard() async {
    final ds = ref.read(paymentRemoteDatasourceProvider);
    bool paymentDone = false;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StripeAddCardSheet(
        datasource: ds,
        customTitle: 'Payment Details',
        customButtonText: widget.amount != null
            ? 'Pay €${widget.amount!.toStringAsFixed(2)}'
            : 'Pay Now',
        amount: widget.amount,
        onCardAdded: (paymentMethodId) async {
          if (paymentMethodId != null) {
            try {
              await ds.confirmSetupIntent(paymentMethodId);
            } catch (_) {}
            ref.invalidate(paymentMethodsProvider);

            // Directly process payment with the newly added card
            final success = await widget.onConfirm(
              PaymentMethodType.card,
              cardId: paymentMethodId,
              cardDisplayName: 'Card',
              isOnline: false,
            );
            if (success) {
              paymentDone = true;
            } else {
              throw Exception('Payment could not be processed. Please try again.');
            }
          }
        },
      ),
    );

    if (paymentDone && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleConfirm() async {
    if (_selectedOption == FoodGroceryPaymentSelection.card &&
        _selectedCardId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a saved card or choose Online Payment.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_selectedOption == FoodGroceryPaymentSelection.online) {
        final success = await widget.onConfirm(
          PaymentMethodType.card,
          cardId: null,
          cardDisplayName: 'Online Payment (Stripe)',
          isOnline: true,
        );

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          if (success) {
            Navigator.of(context).pop();
          }
        }
      } else {
        // Saved Card payment
        final success = await widget.onConfirm(
          PaymentMethodType.card,
          cardId: _selectedCardId,
          cardDisplayName: _selectedCardDisplayName,
          cardBrand: _selectedCardBrand,
          isOnline: false,
        );

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          if (success) {
            Navigator.of(context).pop();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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

    return PopScope(
      canPop: !_isLoading,
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(top: 14, bottom: 18),
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header Title Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Method',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Select payment option for Food & Groceries',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Opacity(
                        opacity: _isLoading ? 0.3 : 1.0,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.10)
                                : Colors.black.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 18,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Options List
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Saved Cards
                      Row(
                        children: [
                          const Icon(
                            Icons.credit_card_rounded,
                            size: 18,
                            color: AppColors.primaryGold,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'SAVED CARDS',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primaryGold,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      paymentMethodsAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primaryGold,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        error: (_, __) => _buildAddCardButton(
                          cardColor,
                          borderColor,
                          textColor,
                          secondaryTextColor,
                        ),
                        data: (methods) {
                          // Auto-select card if card was previously selected
                          if (_selectedOption ==
                                  FoodGroceryPaymentSelection.card &&
                              _selectedCardId == null &&
                              methods.isNotEmpty) {
                            final defaultCard = methods.firstWhere(
                              (m) => m.isDefault,
                              orElse: () => methods.first,
                            );
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted && _selectedCardId == null) {
                                setState(() {
                                  _selectedCardId = defaultCard.id;
                                  _selectedCardDisplayName =
                                      defaultCard.displayName;
                                  _selectedCardBrand = defaultCard.brand;
                                });
                              }
                            });
                          }

                          return Column(
                            children: [
                              ...methods.map((pm) {
                                final isSelected = _selectedOption ==
                                        FoodGroceryPaymentSelection.card &&
                                    _selectedCardId == pm.id;
                                final isDisabled = _isLoading && !isSelected;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: AnimatedOpacity(
                                    opacity: isDisabled ? 0.38 : 1.0,
                                    duration:
                                        const Duration(milliseconds: 200),
                                    child: GestureDetector(
                                      onTap: _isLoading
                                          ? null
                                          : () => setState(() {
                                                _selectedOption =
                                                    FoodGroceryPaymentSelection
                                                        .card;
                                                _selectedCardId = pm.id;
                                                _selectedCardDisplayName =
                                                    pm.displayName;
                                                _selectedCardBrand = pm.brand;
                                              }),
                                      child: Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: cardColor,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                            color: isSelected
                                                ? AppColors.primaryGold
                                                : borderColor,
                                            width: isSelected ? 1.5 : 0.6,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            PaymentBrandIcon(brand: pm.brand),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    pm.displayName,
                                                    style: AppTextStyles
                                                        .titleSmall
                                                        .copyWith(
                                                      color: textColor,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  Text(
                                                    pm.isDefault
                                                        ? 'Default card'
                                                        : 'Saved card',
                                                    style: AppTextStyles
                                                        .bodySmall
                                                        .copyWith(
                                                      color:
                                                          secondaryTextColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (pm.isDefault)
                                              Container(
                                                margin: const EdgeInsets.only(
                                                    right: 8),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primaryGold
                                                      .withValues(alpha: 0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  'Default',
                                                  style: AppTextStyles
                                                      .labelSmall
                                                      .copyWith(
                                                    color:
                                                        AppColors.primaryGold,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            _radioCircle(isSelected),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              _buildAddCardButton(
                                cardColor,
                                borderColor,
                                textColor,
                                secondaryTextColor,
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 18),

                      // Section 2: Online Payment
                      Row(
                        children: [
                          const Icon(
                            Icons.language_rounded,
                            size: 18,
                            color: AppColors.primaryGold,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ONLINE PAYMENT',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primaryGold,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      Builder(
                        builder: (context) {
                          final isOnlineSelected = _selectedOption ==
                              FoodGroceryPaymentSelection.online;
                          final isOnlineDisabled =
                              _isLoading && !isOnlineSelected;
                          return AnimatedOpacity(
                            opacity: isOnlineDisabled ? 0.38 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            child: GestureDetector(
                              onTap: _isLoading
                                  ? null
                                  : () => setState(() {
                                        _selectedOption =
                                            FoodGroceryPaymentSelection.online;
                                        _selectedCardId = null;
                                        _selectedCardDisplayName = null;
                                        _selectedCardBrand = null;
                                      }),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isOnlineSelected
                                        ? AppColors.primaryGold
                                        : borderColor,
                                    width: isOnlineSelected ? 1.5 : 0.6,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryGold
                                            .withValues(alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.payment_rounded,
                                        color: AppColors.primaryGold,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Online Payment',
                                            style: AppTextStyles.titleSmall
                                                .copyWith(
                                              color: textColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            'Pay securely via Stripe Checkout',
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                              color: secondaryTextColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    _radioCircle(isOnlineSelected),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Confirm / Pay Button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.black,
                            ),
                          )
                        : Text(
                            widget.amount != null
                                ? 'Pay €${widget.amount!.toStringAsFixed(2)}'
                                : 'Pay Now',
                            style: AppTextStyles.titleSmall.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddCardButton(
    Color? cardColor,
    Color borderColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return AnimatedOpacity(
      opacity: _isLoading ? 0.38 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: _isLoading ? null : _addCard,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
              width: 0.6,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.add_circle_outline_rounded,
                  color: AppColors.primaryGold,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add New Card',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Credit / Debit Card via Stripe',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primaryGold,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _radioCircle(bool selected) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.primaryGold : Colors.grey,
          width: 2,
        ),
      ),
      child: selected
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
