import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/providers/storage_provider.dart';
import '../../../core/router/route_names.dart';
import '../data/onboarding_data.dart';
import 'widgets/onboarding_page_widget.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
  }

  void _goToNext() {
    if (_currentPage < AppConstants.onboardingPageCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _goToPrevious() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    await ref.read(secureStorageProvider).setOnboardingSeen();
    if (!mounted) return;
    context.goNamed(RouteNames.welcome);
  }

  bool get _isLastPage =>
      _currentPage == AppConstants.onboardingPageCount - 1;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final bottomPadding = isSmallScreen ? 16.0 : 32.0;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF0A0A0A),
                    const Color(0xFF051C34),
                  ]
                : [
                    AppColors.backgroundLight,
                    const Color(0xFFE6EBF1),
                  ],
            stops: const [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top Row: Logo + Skip ───────────────────
              _buildTopBar(isDark),

              // ── Page View ──────────────────────────────
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: AppConstants.onboardingPageCount,
                  onPageChanged: _onPageChanged,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    return OnboardingPageWidget(data: onboardingPages[index]);
                  },
                ),
              ),

              // ── Bottom Controls ────────────────────────
              _buildBottomControls(isDark),

              SizedBox(height: bottomPadding),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top bar with Skip button, then logo below ──────────
  Widget _buildTopBar(bool isDark) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final logoSize = isSmallScreen ? 70.0 : 100.0;

    return Column(
      children: [
        // Skip button row
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: isSmallScreen ? 6 : 12,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: _completeOnboarding,
                child: Text(
                  'Skip',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Logo centered below
        Image.asset(
          AssetPaths.gozoltLogo,
          width: logoSize,
          height: logoSize,
        ),
      ],
    );
  }

  // ── Bottom: arrows + indicator ────────────────────────
  Widget _buildBottomControls(bool isDark) {
    if (_isLastPage) {
      return Padding(
        padding: const EdgeInsets.only(left: 32, right: 32, top: 24),
        child: Column(
          children: [
            // Smaller "Get Started" button
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _completeOnboarding,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: isDark ? AppColors.backgroundDark : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Get Started',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: isDark ? AppColors.backgroundDark : Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Dot indicator
            SmoothPageIndicator(
              controller: _pageController,
              count: AppConstants.onboardingPageCount,
              effect: WormEffect(
                dotWidth: 10,
                dotHeight: 10,
                spacing: 12,
                dotColor: isDark ? AppColors.borderDark : AppColors.borderLight,
                activeDotColor: AppColors.primaryGold,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left arrow (hidden on first page)
          _buildNavArrow(
            icon: Icons.chevron_left,
            onTap: _currentPage > 0 ? _goToPrevious : null,
            visible: _currentPage > 0,
            isDark: isDark,
          ),

          // Dot indicator
          SmoothPageIndicator(
            controller: _pageController,
            count: AppConstants.onboardingPageCount,
            effect: WormEffect(
              dotWidth: 10,
              dotHeight: 10,
              spacing: 12,
              dotColor: isDark ? AppColors.borderDark : AppColors.borderLight,
              activeDotColor: AppColors.primaryGold,
            ),
          ),

          // Right arrow
          _buildNavArrow(
            icon: Icons.chevron_right,
            onTap: _goToNext,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildNavArrow({
    required IconData icon,
    VoidCallback? onTap,
    bool visible = true,
    required bool isDark,
  }) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: visible ? 1.0 : 0.0,
      child: GestureDetector(
        onTap: visible ? onTap : null,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? Colors.transparent : Colors.white.withOpacity(0.8),
            border: Border.all(
              color: AppColors.primaryGold,
              width: 1.5,
            ),
            boxShadow: isDark ? null : [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: AppColors.primaryGold, size: 28),
        ),
      ),
    );
  }

}
