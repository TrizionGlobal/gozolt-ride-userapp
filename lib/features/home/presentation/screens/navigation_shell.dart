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

import '../../../ride/presentation/providers/active_ride_provider.dart';
import '../widgets/active_ride_banner.dart';

class NavigationShell extends ConsumerStatefulWidget {
  const NavigationShell({super.key});

  @override
  ConsumerState<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends ConsumerState<NavigationShell> {
  final List<int> _tabHistory = [];
  bool _isPopping = false;

  static const _tabs = [
    _TabItem(icon: Icons.home_rounded, label: 'Home'),
    _TabItem(icon: Icons.access_time_rounded, label: 'My Rides'),
    _TabItem(icon: Icons.card_giftcard_rounded, label: 'Rewards'),
    _TabItem(icon: Icons.person_outline_rounded, label: 'Account'),
  ];

  void _handlePop() {
    if (_tabHistory.isNotEmpty) {
      final prevTab = _tabHistory.removeLast();
      setState(() {
        _isPopping = true;
      });
      ref.read(homeTabIndexProvider.notifier).state = prevTab;
      setState(() {
        _isPopping = false;
      });
    } else {
      setState(() {
        _isPopping = true;
      });
      ref.read(homeTabIndexProvider.notifier).state = 0;
      setState(() {
        _isPopping = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(homeTabIndexProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rideState = ref.watch(activeRideProvider);
    final hasActiveRide = rideState.ride != null &&
        !rideState.isCompleted &&
        !rideState.isCancelled;

    // Listen to tab changes to build history
    ref.listen<int>(homeTabIndexProvider, (previous, next) {
      if (_isPopping) return;
      if (previous != null && previous != next) {
        setState(() {
          _tabHistory.remove(next);
          _tabHistory.add(previous);
        });
      }
    });

    return PopScope(
      canPop: currentIndex == 0 && _tabHistory.isEmpty,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _handlePop();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        extendBody: true,
        body: Stack(
          children: [
            IndexedStack(
              index: currentIndex,
              children: const [
                HomeScreen(),
                MyRidesScreen(),
                RewardsScreen(),
                AccountScreen(),
              ],
            ),
            if (hasActiveRide)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 88,
                left: 0,
                right: 0,
                child: const ActiveRideBanner(),
              ),
          ],
        ),
        bottomNavigationBar: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                color: isDark 
                    ? AppColors.surfaceDark.withOpacity(0.7) 
                    : AppColors.surfaceLight.withOpacity(0.85),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark 
                      ? AppColors.primaryGold.withOpacity(0.15)
                      : AppColors.primaryGold.withOpacity(0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark 
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.1),
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
      ),
    );
  }

  Widget _buildNavItem({
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
