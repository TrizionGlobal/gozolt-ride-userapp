import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../providers/rewards_providers.dart';

class ReferralBottomSheet extends ConsumerWidget {
  const ReferralBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final referralAsync = ref.watch(referralInfoProvider);
    final rulesAsync = ref.watch(rewardRulesProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Row(
                children: [
                  const Icon(Icons.people,
                      color: AppColors.primaryGold, size: 24),
                  const SizedBox(width: 8),
                  Text('Refer & Earn',
                      style: AppTextStyles.headlineSmall),
                ],
              ),
              const SizedBox(height: 20),

              // Referral code
              referralAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                      color: AppColors.primaryGold, strokeWidth: 2),
                ),
                error: (context, error) => Text(
                  'Failed to load referral info',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.error),
                ),
                data: (referral) => Column(
                  children: [
                    // Large code display
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: referral.referralCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Copied!'),
                            backgroundColor: AppColors.surfaceDark,
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 20),
                        decoration: BoxDecoration(
                          color: AppColors.cardDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primaryGold.withOpacity(0.3),
                            width: 1.5,
                            // No dashed border in Flutter, use solid with gold tint
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              referral.referralCode,
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primaryGold,
                                letterSpacing: 3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap to copy',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Share button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // In production: Share.share(...)
                          final code = referral.referralCode;
                          final bonus = rulesAsync.value
                                  ?.referral.newUserBonus
                                  .toString() ??
                              '100';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Share: "Join Gozolt! Use code $code and get $bonus GoCoins! Download: https://gozolt.com/app"'),
                              backgroundColor: AppColors.surfaceDark,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        },
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text('Share your code'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGold,
                          foregroundColor: AppColors.backgroundDark,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Stats card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderDark),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statColumn('Friends\ninvited',
                              referral.totalReferrals.toString()),
                          Container(
                              width: 1,
                              height: 36,
                              color: AppColors.borderDark),
                          _statColumn('Completed\nfirst ride',
                              referral.completedReferrals.toString()),
                          Container(
                              width: 1,
                              height: 36,
                              color: AppColors.borderDark),
                          _statColumn('Total\nearned',
                              '${referral.earnedPoints} pts'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // How it works
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderDark),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('How it works',
                              style: AppTextStyles.titleSmall),
                          const SizedBox(height: 12),
                          _stepRow('1', 'Share your code with friends'),
                          const SizedBox(height: 8),
                          _stepRow('2',
                              'They sign up and complete their first ride'),
                          const SizedBox(height: 8),
                          _stepRow('3', 'You both earn GoCoins!'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.primaryGold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(fontSize: 10),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _stepRow(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.primaryGold.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primaryGold,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
