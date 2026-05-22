import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class RewardsPlaceholderScreen extends StatelessWidget {
  const RewardsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.card_giftcard_rounded,
              size: 64,
              color: Theme.of(context).brightness == Brightness.dark ? AppColors.textMuted : AppColors.textMutedLight,
            ),
            const SizedBox(height: 16),
            Text(
              'Rewards',
              style: AppTextStyles.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Your GoCoins and rewards will appear here',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
