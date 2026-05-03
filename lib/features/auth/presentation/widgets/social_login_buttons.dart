import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/asset_paths.dart';

class SocialLoginButtons extends StatelessWidget {
  final VoidCallback? onGoogleTap;
  final VoidCallback? onAppleTap;
  final bool isLoading;

  const SocialLoginButtons({
    super.key,
    this.onGoogleTap,
    this.onAppleTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Divider with "or"
        Row(
          children: [
            const Expanded(child: Divider(color: AppColors.borderDark)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'or',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const Expanded(child: Divider(color: AppColors.borderDark)),
          ],
        ),

        const SizedBox(height: 24),

        // Google button
        _SocialButton(
          onTap: isLoading ? null : onGoogleTap,
          logoPath: AssetPaths.googleLogo,
          label: 'Continue with Google',
        ),

        const SizedBox(height: 12),

        // Apple button (only show on iOS, but always render for now)
        _SocialButton(
          onTap: isLoading ? null : onAppleTap,
          logoPath: AssetPaths.appleLogo,
          label: 'Continue with Apple',
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String logoPath;
  final String label;

  const _SocialButton({
    this.onTap,
    required this.logoPath,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(logoPath, width: 22, height: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
