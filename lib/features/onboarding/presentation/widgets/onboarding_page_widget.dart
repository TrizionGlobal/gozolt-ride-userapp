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
    final verticalGap = isSmallScreen ? 20.0 : 40.0;
    final subtitleGap = isSmallScreen ? 12.0 : 20.0;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedImagePath = (data.imagePath == AssetPaths.onboardingTracking && !isDark)
        ? AssetPaths.onboardingTrackingLight
        : data.imagePath;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        
        // Dynamically scale image height to prevent overflow
        final dynamicImageHeight = data.fullWidthImage 
            ? (availableHeight * 0.45).clamp(150.0, 350.0)
            : (availableHeight * 0.45).clamp(200.0, 350.0);

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: availableHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: availableHeight * 0.05),

                // ── Illustration ─────────────────────────────
                if (data.fullWidthImage)
                  _buildFullWidthImage(context, dynamicImageHeight, resolvedImagePath)
                else
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: data.horizontalPadding),
                    child: SizedBox(
                      height: dynamicImageHeight,
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
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                
                SizedBox(height: availableHeight * 0.1),
              ],
            ),
          ),
        );
      }
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
          color: AppColors.textPrimary,
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
