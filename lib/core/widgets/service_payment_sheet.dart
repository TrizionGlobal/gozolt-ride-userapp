import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../../features/ride/presentation/providers/ride_providers.dart';
import '../../features/ride/presentation/widgets/payment_brand_icon.dart';
import '../../features/ride/presentation/widgets/stripe_add_card_sheet.dart';

enum ServicePaymentOption {
  card,
  online,
}

class ServicePaymentSheet extends ConsumerStatefulWidget {
  final double amount;
  final String serviceTitle;
  final String? subtitle;
  final String? initialCardId;
  final ServicePaymentOption initialOption;
  final Future<bool> Function(ServicePaymentOption option, {String? cardId}) onConfirm;

  const ServicePaymentSheet({
    super.key,
    required this.amount,
    required this.serviceTitle,
    this.subtitle,
    this.initialCardId,
    this.initialOption = ServicePaymentOption.card,
    required this.onConfirm,
  });

  @override
  ConsumerState<ServicePaymentSheet> createState() => _ServicePaymentSheetState();
}

class _ServicePaymentSheetState extends ConsumerState<ServicePaymentSheet> {
  late ServicePaymentOption _selectedOption;
  String? _selectedCardId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedOption = widget.initialOption;
    _selectedCardId = widget.initialCardId;

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
        customButtonText: 'Pay €${widget.amount.toStringAsFixed(2)}',
        onCardAdded: (paymentMethodId) async {
          if (paymentMethodId != null) {
            // Automatically process payment directly with the new card without saving it
            final success = await widget.onConfirm(
              ServicePaymentOption.card,
              cardId: paymentMethodId,
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
    if (_selectedOption == ServicePaymentOption.card && _selectedCardId == null) {
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
      final success = await widget.onConfirm(
        _selectedOption,
        cardId: _selectedOption == ServicePaymentOption.card ? _selectedCardId : null,
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (success) {
          Navigator.of(context).pop();
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;
    final secondaryTextColor =
        isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;
    final cardColor = Theme.of(context).cardTheme.color;
    final borderColor =
        Theme.of(context).dividerTheme.color ?? AppColors.borderDark;
    final paymentMethodsAsync = ref.watch(paymentMethodsProvider);

    final resolvedSubtitle =
        widget.subtitle ?? 'Select payment option for ${widget.serviceTitle}';

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

              // Header Title
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
                          resolvedSubtitle,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: Opacity(
                        opacity: _isLoading ? 0.3 : 1.0,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
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
                        // Auto-select default card if none selected
                        if (_selectedCardId == null && methods.isNotEmpty) {
                          final defaultCard = methods.firstWhere(
                            (m) => m.isDefault,
                            orElse: () => methods.first,
                          );
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted && _selectedCardId == null) {
                              setState(() {
                                _selectedCardId = defaultCard.id;
                              });
                            }
                          });
                        }

                        return Column(
                          children: [
                            ...methods.map((pm) {
                              final isSelected =
                                  _selectedOption == ServicePaymentOption.card &&
                                      _selectedCardId == pm.id;
                              final isDisabled = _isLoading && !isSelected;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: AnimatedOpacity(
                                  opacity: isDisabled ? 0.38 : 1.0,
                                  duration: const Duration(milliseconds: 200),
                                  child: GestureDetector(
                                    onTap: _isLoading
                                        ? null
                                        : () => setState(() {
                                              _selectedOption = ServicePaymentOption.card;
                                              _selectedCardId = pm.id;
                                            }),
                                    child: Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: cardColor,
                                        borderRadius: BorderRadius.circular(14),
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
                                                  style: AppTextStyles.titleSmall
                                                      .copyWith(
                                                    color: textColor,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                Text(
                                                  pm.isDefault
                                                      ? 'Default card'
                                                      : 'Saved card',
                                                  style: AppTextStyles.bodySmall
                                                      .copyWith(
                                                    color: secondaryTextColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (pm.isDefault)
                                            Container(
                                              margin:
                                                  const EdgeInsets.only(right: 8),
                                              padding: const EdgeInsets.symmetric(
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
                                                style: AppTextStyles.labelSmall
                                                    .copyWith(
                                                  color: AppColors.primaryGold,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          if (_isLoading && isSelected)
                                            const Padding(
                                              padding: EdgeInsets.only(right: 6),
                                              child: Icon(
                                                Icons.lock_rounded,
                                                size: 16,
                                                color: AppColors.primaryGold,
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
                        final isOnlineSelected = _selectedOption == ServicePaymentOption.online;
                        final isOnlineDisabled = _isLoading && !isOnlineSelected;
                        return AnimatedOpacity(
                          opacity: isOnlineDisabled ? 0.38 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: GestureDetector(
                            onTap: _isLoading
                                ? null
                                : () => setState(() {
                                      _selectedOption = ServicePaymentOption.online;
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
                                      borderRadius: BorderRadius.circular(10),
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
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Online Payment',
                                          style: AppTextStyles.titleSmall.copyWith(
                                            color: textColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          'Pay securely via Stripe Checkout',
                                          style: AppTextStyles.bodySmall.copyWith(
                                            color: secondaryTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_isLoading && isOnlineSelected)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 6),
                                      child: Icon(
                                        Icons.lock_rounded,
                                        size: 16,
                                        color: AppColors.primaryGold,
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

            // Pay Button
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
                          'Pay €${widget.amount.toStringAsFixed(2)}',
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
              color: Colors.grey,
            ),
          ],
        ),
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
          color: isSelected ? AppColors.primaryGold : Colors.grey.shade400,
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

