import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../account/presentation/screens/account_screen.dart';
import '../../../history/presentation/screens/my_rides_screen.dart';
import '../../../rewards/presentation/screens/rewards_screen.dart';
import '../providers/home_providers.dart';
import 'home_screen.dart';

class NavigationShell extends ConsumerWidget {
  const NavigationShell({super.key});

  static const _tabs = [
    _TabItem(icon: Icons.home_rounded, label: 'Home'),
    _TabItem(icon: Icons.access_time_rounded, label: 'My Rides'),
    _TabItem(icon: Icons.card_giftcard_rounded, label: 'Rewards'),
    _TabItem(icon: Icons.person_outline_rounded, label: 'Account'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(homeTabIndexProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      extendBody: true,
      body: IndexedStack(
        index: currentIndex,
        children: const [
          HomeScreen(),
          MyRidesScreen(),
          RewardsScreen(),
          AccountScreen(),
        ],
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.primaryGold.withValues(alpha: 0.15),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_tabs.length, (index) {
                  final isSelected = currentIndex == index;
                  return _buildNavItem(
                    ref: ref,
                    tab: _tabs[index],
                    index: index,
                    isSelected: isSelected,
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required WidgetRef ref,
    required _TabItem tab,
    required int index,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        ref.read(homeTabIndexProvider.notifier).state = index;
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              label: '${tab.label} tab',
              selected: isSelected,
              child: Icon(
                tab.icon,
                size: 26,
                color: isSelected ? AppColors.primaryGold : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              tab.label,
              style: AppTextStyles.labelSmall.copyWith(
                color: isSelected ? AppColors.primaryGold : AppColors.textMuted,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final String label;

  const _TabItem({required this.icon, required this.label});
}
