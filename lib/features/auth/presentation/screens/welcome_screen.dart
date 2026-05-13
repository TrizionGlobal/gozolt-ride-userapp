import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/asset_paths.dart';
import '../../../../core/providers/storage_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/gozolt_button.dart';
import '../providers/auth_provider.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 3),

              // ── Logo with text ─────────────────────────────
              Image.asset(
                AssetPaths.gozoltLogoWithText,
                width: 240,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 16),

              // ── Tagline ────────────────────────────────────
              Text(
                'Together shaping the future of convenience',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),

              const Spacer(flex: 2),

              // ── Log In button (filled gold) ────────────────
              GozoltButton(
                label: 'Log In',
                width: double.infinity,
                onPressed: () {
                  ref.read(isRegisterFlowProvider.notifier).state = false;
                  context.pushNamed(RouteNames.phoneEntry);
                },
              ),

              const SizedBox(height: 14),

              // ── "or" divider ─────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Divider(color: Theme.of(context).dividerTheme.color, thickness: 0.5),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'or',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark, thickness: 0.5),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ── Register button (outlined) ─────────────────
              GozoltButton(
                label: 'Register',
                width: double.infinity,
                isOutlined: true,
                onPressed: () {
                  ref.read(isRegisterFlowProvider.notifier).state = true;
                  context.pushNamed(RouteNames.phoneEntry);
                },
              ),

              const Spacer(),

              // ── Dev bypass button ──────────────────────────
              if (AppConstants.kDevBypass)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextButton(
                    onPressed: () async {
                      final storage = ref.read(secureStorageProvider);
                      await storage.saveTokens(
                        accessToken: AppConstants.kDevAccessToken,
                        refreshToken: AppConstants.kDevRefreshToken,
                      );
                      if (!context.mounted) return;
                      context.goNamed(RouteNames.home);
                    },
                    child: Text(
                      'Skip to Home (DEV)',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ),

              // ── Footer ────────────────────────────────────
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'All rights reserved \u00a9 ',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 11,
                      ),
                    ),
                    TextSpan(
                      text: 'PRIMOOO 2025',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primaryGold,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
