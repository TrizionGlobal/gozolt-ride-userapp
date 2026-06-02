import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../ride/data/models/saved_payment_method.dart';
import '../providers/account_providers.dart';
import '../../../ride/presentation/providers/ride_providers.dart';
import '../../../ride/presentation/widgets/mock_add_card_sheet.dart';
import '../../../ride/presentation/widgets/stripe_add_card_sheet.dart';
import '../../../ride/presentation/widgets/payment_brand_icon.dart';

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
                        onTap: () => context.pop(),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.backgroundDark.withOpacity(0.15),
                          ),
                          child: const Icon(Icons.arrow_back,
                              color: AppColors.backgroundDark, size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Payment Methods',
                        style: AppTextStyles.headlineSmall.copyWith(
                          color: AppColors.backgroundDark,
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
                  childCount: 3,
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
          border: Border.all(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
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
              : (Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
        ),
      ),
      child: Row(
        children: [
          PaymentBrandIcon(brand: pm.brand, size: 40),
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
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Cancel', style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(ctx);
              ref.read(accountPaymentMethodsProvider.notifier).deleteMethod(pm.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Remove', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
                  content: Text('${cardData['brand'].toString().toUpperCase()} ****${cardData['last4']} added', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                  backgroundColor: AppColors.success,
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
              const SnackBar(
                content: Text('Card added successfully', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                backgroundColor: AppColors.success,
              ),
            );
          },
        );
      },
    );
  }
}
