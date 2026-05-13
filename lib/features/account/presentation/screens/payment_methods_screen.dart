import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../ride/data/models/saved_payment_method.dart';
import '../providers/account_providers.dart';
import '../../../ride/presentation/providers/ride_providers.dart';
import '../../../ride/presentation/widgets/mock_add_card_sheet.dart';
import '../../../ride/presentation/widgets/stripe_add_card_sheet.dart';

class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pmState = ref.watch(accountPaymentMethodsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ─────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFD4A843), Color(0xFFF5C518)],
                ),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 20, 20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.05),
                          ),
                          child: Icon(Icons.arrow_back,
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Payment Methods',
                        style: AppTextStyles.headlineSmall.copyWith(
                          color: Theme.of(context).scaffoldBackgroundColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Content ────────────────────────────────
          if (pmState.isLoading)
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => const ShimmerListTile(),
                  childCount: 4,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Cash option (always shown)
                  _paymentTile(
                    context,
                    icon: Icons.money,
                    iconColor: AppColors.success,
                    title: 'Cash',
                    subtitle: 'Pay with cash after your ride',
                    isDefault: pmState.methods.isEmpty,
                  ),
                  const SizedBox(height: 8),

                  // Saved cards
                  ...pmState.methods.map((pm) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                          },
                          child: _cardTile(context, ref, pm),
                        ),
                      )),

                  // UPI Option
                  _paymentTile(
                    context,
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: AppColors.info,
                    title: 'UPI',
                    subtitle: 'Pay via GPay, PhonePe, or BHIM',
                    isDefault: false,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('UPI will be available during ride booking'),
                          backgroundColor: Theme.of(context).cardTheme.color,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),

                  // Add new card
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _addCard(context, ref),

                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primaryGold.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_card,
                              color: AppColors.primaryGold, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Add New Card',
                            style: AppTextStyles.titleSmall.copyWith(
                              color: AppColors.primaryGold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.info.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_outline,
                            color: AppColors.info, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Your payment information is securely processed by Stripe. We never store your full card details.',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.info),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _paymentTile(BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    bool isDefault = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Row(
          children: [

          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleSmall.copyWith(color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : AppColors.textPrimaryLight)),
                Text(subtitle,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
          if (isDefault)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'DEFAULT',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                  fontSize: 9,
                ),
              ),
            ),
        ],
      ),
    ),
    );
  }


  Widget _cardTile(
      BuildContext context, WidgetRef ref, SavedPaymentMethod pm) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: pm.isDefault
              ? AppColors.primaryGold.withOpacity(0.3)
              : AppColors.borderDark,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _brandColor(pm.brand).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                _brandLetter(pm.brand),
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: _brandColor(pm.brand),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pm.displayName, style: AppTextStyles.titleSmall.copyWith(color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : AppColors.textPrimaryLight)),
                Text(
                    'Expires ${pm.expMonth.toString().padLeft(2, '0')}/${pm.expYear.toString().substring(2)}',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
          if (pm.isDefault)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'DEFAULT',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primaryGold,
                  fontWeight: FontWeight.w700,
                  fontSize: 9,
                ),
              ),
            ),
          GestureDetector(
            onTap: () => _confirmDelete(context, ref, pm),
            child: const Icon(Icons.delete_outline,
                color: AppColors.error, size: 20),
          ),
        ],
      ),
    );
  }

  Color _brandColor(CardBrand brand) {
    return switch (brand) {
      CardBrand.visa => const Color(0xFF1A1F71),
      CardBrand.mastercard => const Color(0xFFEB001B),
      CardBrand.amex => const Color(0xFF2E77BC),
      CardBrand.unknown => AppColors.textSecondary,
    };
  }

  String _brandLetter(CardBrand brand) {
    return switch (brand) {
      CardBrand.visa => 'V',
      CardBrand.mastercard => 'M',
      CardBrand.amex => 'A',
      CardBrand.unknown => 'C',
    };
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, SavedPaymentMethod pm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Remove Card', style: AppTextStyles.headlineSmall.copyWith(color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : AppColors.textPrimaryLight)),
        content: Text(
          'Remove ${pm.displayName}?',
          style: AppTextStyles.bodyMedium
              .copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(ctx);
              ref
                  .read(accountPaymentMethodsProvider.notifier)
                  .deleteMethod(pm.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _addCard(BuildContext context, WidgetRef ref) {
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
                  backgroundColor: Theme.of(context).cardTheme.color,
                ),
              );
              ref.read(accountPaymentMethodsProvider.notifier).load();
            },
          );
        }
        final ds = ref.read(paymentRemoteDatasourceProvider);
        return StripeAddCardSheet(
          datasource: ds,
          onCardAdded: (paymentMethodId) {
            if (paymentMethodId != null) {
              ref.read(accountPaymentMethodsProvider.notifier).confirmSetup(paymentMethodId);
            } else {
              ref.read(accountPaymentMethodsProvider.notifier).load();
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Card added successfully'),
                backgroundColor: Theme.of(context).cardTheme.color,
              ),
            );
          },
        );
      },
    );
  }
}
