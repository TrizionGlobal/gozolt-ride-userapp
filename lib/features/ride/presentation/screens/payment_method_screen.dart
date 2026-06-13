import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/models/saved_payment_method.dart';
import '../providers/ride_providers.dart';
import '../widgets/payment_brand_icon.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../widgets/add_card_sheet.dart';
import '../widgets/stripe_add_card_sheet.dart';

class PaymentMethodScreen extends ConsumerStatefulWidget {
  const PaymentMethodScreen({super.key});

  @override
  ConsumerState<PaymentMethodScreen> createState() =>
      _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends ConsumerState<PaymentMethodScreen> {
  PaymentMethodType _selectedType = PaymentMethodType.cash;
  String? _selectedCardId;

  @override
  void initState() {
    super.initState();
    final booking = ref.read(rideBookingProvider);
    _selectedType = booking.paymentMethodType;
    _selectedCardId = booking.selectedCardId;
  }

  void _confirm() {
    ref.read(rideBookingProvider.notifier).setPaymentMethod(
          _selectedType,
          cardId: _selectedCardId,
        );
    context.pop();
  }

  void _addNewPaymentMethod({double? amount}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        
        final ds = ref.read(paymentRemoteDatasourceProvider);
        return StripeAddCardSheet(
          datasource: ds,
          amount: amount,
          onCardAdded: (paymentMethodId) {
            ref.invalidate(paymentMethodsProvider);
            if (amount != null) {
              // If it was a payment, we should select Card type
              setState(() {
                _selectedType = PaymentMethodType.card;
                _selectedCardId = null; // Stripe handles the card
              });
              _confirm(); // Auto-confirm after payment
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Card added successfully',
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final paymentMethodsAsync = ref.watch(paymentMethodsProvider);
    final booking = ref.watch(rideBookingProvider);
    final totalFare = booking.totalFare;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Payment Method',
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.primaryGold,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, size: 18),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primaryGold,
        backgroundColor: Theme.of(context).cardTheme.color,
        onRefresh: () async {
          ref.invalidate(paymentMethodsProvider);
          await Future.delayed(const Duration(milliseconds: 300));
        },
        child: paymentMethodsAsync.when(
          data: (methods) => _buildContent(methods, totalFare),
          loading: () => buildShimmerList(
            itemBuilder: () => const ShimmerListTile(),
            count: 2,
          ),
          error: (context, error) => _buildContent([], totalFare),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildContent(List<SavedPaymentMethod> methods, double totalFare) {
    if (methods.isEmpty && _selectedType == PaymentMethodType.card && _selectedCardId != null) {
      _selectedType = PaymentMethodType.cash;
      _selectedCardId = null;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Cash option
          _PaymentOption(
            leading: Container(
              width: 40,
              height: 28,
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.payments_outlined,
                  color: AppColors.primaryGold, size: 18),
            ),
            title: 'Cash',
            subtitle: 'Prepare your cash',
            isSelected: _selectedType == PaymentMethodType.cash,
            onTap: () {
              setState(() {
                _selectedType = PaymentMethodType.cash;
                _selectedCardId = null;
              });
            },
          ),

          const SizedBox(height: 12),

          // Saved Cards
          ...methods.map((method) {
            final isSelected = _selectedType == PaymentMethodType.card && _selectedCardId == method.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PaymentOption(
                leading: PaymentBrandIcon(brand: method.brand),
                title: method.displayName,
                subtitle: method.isDefault ? 'Default' : 'Saved card',
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedType = PaymentMethodType.card;
                    _selectedCardId = method.id;
                  });
                },
              ),
            );
          }),

          // Add New Card option
          _PaymentOption(
            leading: Container(
              width: 40,
              height: 28,
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.add_circle_outline,
                  color: AppColors.primaryGold, size: 18),
            ),
            title: 'Add New Card',
            subtitle: 'Credit / Debit Card',
            isSelected: _selectedType == PaymentMethodType.card && _selectedCardId == null && methods.isEmpty,
            onTap: () {
              _addNewPaymentMethod(amount: totalFare);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark, width: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Next / Select button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: Theme.of(context).scaffoldBackgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Next',
                style: AppTextStyles.button
                    .copyWith(color: Theme.of(context).scaffoldBackgroundColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Payment Option Radio Tile ────────────────────────────

class _PaymentOption extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primaryGold : (Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleSmall
                        .copyWith(color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : AppColors.textPrimaryLight),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryGold
                      : AppColors.textMuted,
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
            ),
          ],
        ),
      ),
    );
  }
}
