import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/socket_service.dart';
import '../../../ride/presentation/providers/active_ride_provider.dart';
import '../providers/home_providers.dart';
import '../widgets/greeting_header.dart';
import '../widgets/promo_banner.dart';
import '../widgets/book_schedule_buttons.dart';
import '../widgets/transport_grid.dart';
import '../widgets/rewards_home_banner.dart';
import '../widgets/active_ride_banner.dart';
import '../widgets/go_places_section.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Connect socket for real-time ride events + check for active ride
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(socketServiceProvider).connect();
      ref.read(activeRideProvider.notifier).checkForActiveRide();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-check for active ride when app comes back to foreground
      ref.read(socketServiceProvider).connect();
      ref.read(activeRideProvider.notifier).checkForActiveRide();
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          // ── Scrollable content (full screen, scrolls behind top bar) ──
          RefreshIndicator(
            color: AppColors.primaryGold,
            backgroundColor: AppColors.surfaceDark,
            edgeOffset: topPadding + 80,
            onRefresh: () async {
              ref.invalidate(userProfileProvider);
              ref.invalidate(savedAddressesProvider);
              ref.invalidate(unreadNotificationCountProvider);
              await Future.delayed(const Duration(milliseconds: 300));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Space for floating top bar
                  SizedBox(height: topPadding + 64),
                  const ActiveRideBanner(),
                  const SizedBox(height: 20),
                  const PromoBanner(),
                  const SizedBox(height: 20),
                  const BookScheduleButtons(),
                  const SizedBox(height: 24),
                  const TransportGrid(),
                  const SizedBox(height: 24),
                  const RewardsHomeBanner(),
                  const SizedBox(height: 24),
                  const GoPlacesSection(),
                  // Extra bottom padding for floating bottom nav
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // ── Floating glass top bar ────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark.withOpacity(0.7),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(20),
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.primaryGold.withOpacity(0.15),
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 4),
                      child: const GreetingHeader(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
