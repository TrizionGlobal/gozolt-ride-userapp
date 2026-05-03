import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/asset_paths.dart';
import '../providers/home_providers.dart';

class RewardsHomeBanner extends ConsumerWidget {
  const RewardsHomeBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        // Switch to Rewards tab (index 2)
        ref.read(homeTabIndexProvider.notifier).state = 2;
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primaryGold, width: 1.5),
          gradient: LinearGradient(
            colors: [
              AppColors.primaryGold.withValues(alpha: 0.1),
              AppColors.primaryGold.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Row(
          children: [
            Image.asset(AssetPaths.iconGoCoin, width: 36, height: 36),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  children: [
                    const TextSpan(text: 'Explore our '),
                    TextSpan(
                      text: 'Rewards',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.primaryGold,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const TextSpan(text: ' Points'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Image.asset(AssetPaths.iconGoCoin, width: 28, height: 28),
          ],
        ),
      ),
    );
  }
}
