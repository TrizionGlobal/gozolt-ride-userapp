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
import '../widgets/mock_add_card_sheet.dart';
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

  void _addNewPaymentMethod() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        if (AppConstants.kDevBypass) {
          return MockAddCardSheet(
            onCardAdded: (cardData) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${cardData['brand'].toString().toUpperCase()} ****${cardData['last4']} added'),
                  backgroundColor: AppColors.surfaceDark,
                ),
              );
              ref.invalidate(paymentMethodsProvider);
            },
          );
        }
        final ds = ref.read(paymentRemoteDatasourceProvider);
        return StripeAddCardSheet(
          datasource: ds,
          onCardAdded: () {
            ref.invalidate(paymentMethodsProvider);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Card added successfully'),
                backgroundColor: AppColors.surfaceDark,
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final paymentMethodsAsync = ref.watch(paymentMethodsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGold,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Payment Method',
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.backgroundDark,
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
                color: AppColors.backgroundDark.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close,
                  color: AppColors.backgroundDark, size: 18),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primaryGold,
        backgroundColor: AppColors.surfaceDark,
        onRefresh: () async {
          ref.invalidate(paymentMethodsProvider);
          await Future.delayed(const Duration(milliseconds: 300));
        },
        child: paymentMethodsAsync.when(
          data: (methods) => _buildContent(methods),
          loading: () => buildShimmerList(
            itemBuilder: () => const ShimmerListTile(),
            count: 3,
          ),
          error: (context, error) => _buildContent([]),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(paymentMethodsAsync),
    );
  }

  Widget _buildContent(List<SavedPaymentMethod> methods) {
    if (methods.isEmpty && _selectedType == PaymentMethodType.card) {
      _selectedType = PaymentMethodType.cash;
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
                color: AppColors.cardDark,
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

          // Card options
          if (methods.isNotEmpty)
            ...methods.map((method) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Dismissible(
                    key: Key(method.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.delete_outline,
                          color: Colors.white),
                    ),
                    confirmDismiss: (_) async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: AppColors.surfaceDark,
                          title: Text('Remove Card',
                              style: AppTextStyles.titleMedium
                                  .copyWith(color: AppColors.textPrimary)),
                          content: Text(
                            'Remove ${method.displayName}?',
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textSecondary),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Remove',
                                  style: TextStyle(color: AppColors.error)),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        try {
                          final ds = ref.read(paymentRemoteDatasourceProvider);
                          await ds.deletePaymentMethod(method.id);
                          ref.invalidate(paymentMethodsProvider);
                        } catch (_) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to remove card'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                          return false;
                        }
                      }
                      return confirmed ?? false;
                    },
                    child: _PaymentOption(
                      leading: PaymentBrandIcon(brand: method.brand),
                      title: method.displayName,
                      subtitle: method.maskedNumber,
                      isSelected: _selectedType == PaymentMethodType.card &&
                          _selectedCardId == method.id,
                      onTap: () {
                        setState(() {
                          _selectedType = PaymentMethodType.card;
                          _selectedCardId = method.id;
                        });
                      },
                    ),
                  ),
                )),

          if (methods.isEmpty) ...[
            const SizedBox(height: 60),
            Text(
              'No Payment Method Available',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar(AsyncValue<List<SavedPaymentMethod>> methodsAsync) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(
          top: BorderSide(color: AppColors.borderDark, width: 0.5),
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
                foregroundColor: AppColors.backgroundDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Next',
                style: AppTextStyles.button
                    .copyWith(color: AppColors.backgroundDark),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Add New Payment Method
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: _addNewPaymentMethod,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryGold,
                side: const BorderSide(color: AppColors.primaryGold, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Add New Payment Method',
                style: AppTextStyles.button
                    .copyWith(color: AppColors.primaryGold),
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
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primaryGold : AppColors.borderDark,
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
                        .copyWith(color: AppColors.textPrimary),
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
