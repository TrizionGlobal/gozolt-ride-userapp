import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/asset_paths.dart';
import '../../data/onboarding_data.dart';

class OnboardingPageWidget extends StatelessWidget {
  final OnboardingPageData data;

  const OnboardingPageWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    // Scale image height based on screen size, capping for small devices
    final imageHeight = isSmallScreen
        ? (data.imageHeight * 0.65).clamp(180.0, 240.0)
        : data.imageHeight;
    final verticalGap = isSmallScreen ? 20.0 : 40.0;
    final subtitleGap = isSmallScreen ? 12.0 : 20.0;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedImagePath = (data.imagePath == AssetPaths.onboardingTracking && !isDark)
        ? AssetPaths.onboardingTrackingLight
        : data.imagePath;

    return Column(
      children: [
        const Spacer(flex: 2),

        // ── Illustration ─────────────────────────────
        if (data.fullWidthImage)
          _buildFullWidthImage(context, imageHeight, resolvedImagePath)
        else
          Padding(
            padding: EdgeInsets.symmetric(horizontal: data.horizontalPadding),
            child: SizedBox(
              height: imageHeight,
              child: Image.asset(
                resolvedImagePath,
                fit: BoxFit.contain,
              ),
            ),
          ),

        SizedBox(height: verticalGap),

        // ── Title ────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: _buildTitle(context),
        ),

        SizedBox(height: subtitleGap),

        // ── Subtitle ─────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.onboardingSubtitle.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ),

        const Spacer(flex: 3),
      ],
    );
  }

  Widget _buildFullWidthImage(BuildContext context, double imageHeight, String imagePath) {
    final screenWidth = MediaQuery.of(context).size.width;

    Widget imageWidget = SizedBox(
      width: screenWidth,
      height: imageHeight,
      child: Image.asset(
        imagePath,
        width: screenWidth,
        height: imageHeight,
        fit: BoxFit.cover,
      ),
    );

    if (data.fadeTop) {
      imageWidget = ShaderMask(
        shaderCallback: (Rect bounds) {
          return const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.center,
            colors: [Colors.transparent, Colors.white],
            stops: [0.0, 0.35],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: imageWidget,
      );
    }

    return SizedBox(
      width: screenWidth,
      height: imageHeight,
      child: imageWidget,
    );
  }

  Widget _buildTitle(BuildContext context) {
    if (data.titleAllGold) {
      return Text(
        '${data.title}${data.highlightedWord}',
        textAlign: TextAlign.center,
        style: AppTextStyles.onboardingTitle.copyWith(
          color: AppColors.primaryGold,
        ),
      );
    }

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: AppTextStyles.onboardingTitle.copyWith(
          color: Theme.of(context).textTheme.headlineLarge?.color,
        ),
        children: [
          TextSpan(text: data.title),
          TextSpan(
            text: data.highlightedWord,
            style: AppTextStyles.onboardingTitle.copyWith(
              color: AppColors.primaryGold,
            ),
          ),
        ],
      ),
    );
  }
}
