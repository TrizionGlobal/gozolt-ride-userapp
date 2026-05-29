import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/providers/storage_provider.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../providers/account_providers.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../rewards/presentation/providers/rewards_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  DateTime? _lastRateAppTap;
  int _profileRetryCount = 0;
  static const int _maxProfileRetries = 3;

  void _showPremiumSnackBar(String message, {IconData icon = Icons.info_outline}) {
    final isDark = ref.read(isDarkModeProvider);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: AppColors.primaryGold, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final isDark = ref.watch(isDarkModeProvider);
    final rewardSummaryAsync = ref.watch(rewardSummaryProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        color: AppColors.primaryGold,
        backgroundColor: Theme.of(context).colorScheme.surface,
        onRefresh: () async {
          _profileRetryCount = 0; // reset retry cap on manual refresh
          ref.invalidate(userProfileProvider);
          await Future.delayed(const Duration(milliseconds: 300));
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
          // ── Gold Header with Profile ────────────────
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFD4A843), Color(0xFFF5C518)],
                ),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: profileAsync.when(
                    loading: () => SizedBox(
                      height: 64,
                      child: ShimmerWrap(
                        child: Row(
                          children: [
                            const ShimmerCircle(radius: 30),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                ShimmerText(width: 120, height: 14),
                                SizedBox(height: 8),
                                ShimmerText(width: 160, height: 10),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    error: (error, __) {
                      // Auto-retry with exponential backoff, capped at _maxProfileRetries.
                      // When the server is completely unreachable we stop retrying to
                      // avoid hammering the network with an infinite loop.
                      if (_profileRetryCount < _maxProfileRetries) {
                        _profileRetryCount++;
                        // Backoff: 3s → 10s → 30s
                        final delays = [3, 10, 30];
                        final delaySecs = delays[(_profileRetryCount - 1).clamp(0, delays.length - 1)];
                        Future.delayed(Duration(seconds: delaySecs), () {
                          if (mounted) ref.invalidate(userProfileProvider);
                        });
                      }
                      // Show shimmer while waiting for retry — no broken UI shown
                      return SizedBox(
                        height: 64,
                        child: ShimmerWrap(
                          child: Row(
                            children: [
                              const ShimmerCircle(radius: 30),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  ShimmerText(width: 120, height: 14),
                                  SizedBox(height: 8),
                                  ShimmerText(width: 160, height: 10),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },

                    data: (profile) => Row(
                      children: [
                        (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty)
                            ? ClipOval(
                                child: Image.network(
                                  ApiConstants.fullUrl(profile.avatarUrl!),
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(profile, 60),
                                ),
                              )
                            : _buildAvatarPlaceholder(profile, 60),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${profile.firstName ?? ''} ${profile.lastName ?? ''}'
                                    .trim(),
                                style: AppTextStyles.headlineSmall.copyWith(
                                  color: AppColors.backgroundDark,
                                ),
                              ),
                              if (profile.phone != null)
                                Text(
                                  profile.phone!,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.backgroundDark
                                        .withOpacity(0.7),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Semantics(
                          label: 'Edit profile',
                          button: true,
                          child: GestureDetector(
                            onTap: () =>
                                context.pushNamed(RouteNames.editProfile),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.backgroundDark
                                    .withOpacity(0.15),
                              ),
                              child: const Icon(Icons.edit,
                                  color: AppColors.backgroundDark, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Menu Items ─────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Section: Account
                _sectionLabel('Account'),
                _menuItem(
                  icon: Icons.person_outline,
                  label: 'Edit Profile',
                  onTap: () => context.pushNamed(RouteNames.editProfile),
                ),
                _menuItem(
                  icon: Icons.location_on_outlined,
                  label: 'Saved Places',
                  onTap: () => context.pushNamed(RouteNames.savedPlaces),
                ),

                _menuItem(
                  icon: Icons.credit_card,
                  label: 'Payment Methods',
                  onTap: () => context.pushNamed(RouteNames.accountPaymentMethods),
                ),
                 _menuItem(
                  icon: Icons.stars_outlined,
                  label: 'Rewards/Tier',
                  onTap: () => ref.read(homeTabIndexProvider.notifier).state = 2,
                  trailing: rewardSummaryAsync.when(
                    data: (summary) {
                      final tierName = summary.tier.toUpperCase();
                      final formattedTier = tierName.isNotEmpty 
                          ? (tierName.substring(0, 1) + tierName.substring(1).toLowerCase())
                          : 'Bronze';
                      final tierColor = _getTierColor(tierName);
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: tierColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          formattedTier,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: tierColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
                _menuItem(
                  icon: Icons.history,
                  label: 'Your Latest Ride',
                  onTap: () {
                    // Switch to My Rides tab
                    ref.read(homeTabIndexProvider.notifier).state = 1;
                  },
                ),

                const SizedBox(height: 16),
                _sectionLabel('Preferences'),
                _menuItem(
                  icon: Icons.language,
                  label: 'Language',
                  trailing: Text(
                    'English',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textMuted),
                  ),
                  showChevron: false,
                ),
                _menuItem(
                  icon: Icons.notifications_outlined,
                  label: 'Notification Preferences',
                  onTap: () =>
                      context.pushNamed(RouteNames.notificationPreferences),
                ),
                _toggleItem(
                  icon: Icons.dark_mode_outlined,
                  label: 'Dark Mode',
                  value: isDark,
                  onChanged: (v) {
                    ref.read(themeModeProvider.notifier).setThemeMode(
                      v ? ThemeMode.dark : ThemeMode.light,
                    );
                  },
                ),

                const SizedBox(height: 16),
                _sectionLabel('Support'),
                _menuItem(
                  icon: Icons.security_outlined,
                  label: 'Emergency Contacts',
                  onTap: () => context.pushNamed(RouteNames.emergencyContacts),
                ),
                _menuItem(
                  icon: Icons.confirmation_number_outlined,
                  label: 'My Tickets',
                  subtitle: 'View support requests',
                  onTap: () => context.pushNamed(RouteNames.support),
                ),
                _menuItem(
                  icon: Icons.help_outline,
                  label: 'Help Center',
                  onTap: () => context.pushNamed(RouteNames.helpCenter),
                ),
                _menuItem(
                  icon: Icons.chat_outlined,
                  label: 'Contact Support',
                  subtitle: 'Chat on WhatsApp',
                  onTap: () => _openWhatsApp(),
                ),
                _menuItem(
                  icon: Icons.star_border,
                  label: 'Rate App',
                  onTap: () => _rateApp(),
                ),

                const SizedBox(height: 16),
                _sectionLabel('Legal & Data'),
                _menuItem(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Privacy Policy',
                  onTap: () => context.pushNamed(RouteNames.privacyPolicy),
                ),
                _menuItem(
                  icon: Icons.description_outlined,
                  label: 'Terms & Conditions',
                  onTap: () => context.pushNamed(RouteNames.terms),
                ),

                _menuItem(
                  icon: Icons.delete_outline,
                  label: 'Delete Account',
                  textColor: AppColors.error,
                  onTap: () => context.pushNamed(RouteNames.deleteAccount),
                ),

                const SizedBox(height: 24),

                // Log Out
                Semantics(
                  label: 'Log out',
                  button: true,
                  child: Center(
                    child: OutlinedButton.icon(
                      onPressed: () => _logOut(),
                      icon: const Icon(Icons.logout, size: 16),
                      label: Text('Log Out', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 32),
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error, width: 1.0),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Gozolt v1.0.1',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String label,
    String? subtitle,
    Widget? trailing,
    Color? textColor,
    VoidCallback? onTap,
    bool showChevron = true,
  }) {
    return Semantics(
      label: label,
      button: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap?.call();
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: textColor ?? (Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : AppColors.textSecondaryLight), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textMuted, fontSize: 11),
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing,
            if (showChevron) ...[
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right,
                  color: AppColors.textMuted, size: 20),
            ],
          ],
        ),
      ),
      ),
    );
  }

  Widget _toggleItem({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : AppColors.textSecondaryLight, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Semantics(
            label: 'Dark mode toggle',
            toggled: value,
            child: Transform.scale(
              scale: 0.7,
              child: Switch.adaptive(
                value: value,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  onChanged(v);
                },
                activeTrackColor: AppColors.primaryGold,
                inactiveTrackColor: Theme.of(context).dividerTheme.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageSheet() {
    final current = ref.read(languageProvider);
    final isDark = ref.read(isDarkModeProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerTheme.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text('Select Language', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 16),
              _languageOption(
                label: 'English',
                code: 'en',
                isSelected: current == 'en',
                onTap: () {
                  ref.read(languageProvider.notifier).state = 'en';
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
              _languageOption(
                label: 'Maltese',
                code: 'mt',
                isSelected: current == 'mt',
                onTap: () {
                  ref.read(languageProvider.notifier).state = 'mt';
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _languageOption({
    required String label,
    required String code,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primaryGold.withOpacity(0.1) 
              : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? AppColors.primaryGold 
                : (Theme.of(context).dividerTheme.color ?? Colors.transparent),
          ),
        ),
        child: Row(
          children: [
            Text(code == 'en' ? '🇬🇧' : '🇲🇹', style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: AppTextStyles.titleSmall),
            ),
            if (isSelected)
              const Icon(Icons.check_circle,
                  color: AppColors.primaryGold, size: 22),
          ],
        ),
      ),
    );
  }

  Future<void> _openWhatsApp() async {
    final uri = Uri.parse('https://wa.me/35612345678');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        _showPremiumSnackBar(
          'WhatsApp is not installed. Please install it or email us at support@gozolt.com',
          icon: Icons.chat_outlined,
        );
      }
    }
  }


  void _rateApp() {
    final now = DateTime.now();
    if (_lastRateAppTap != null && now.difference(_lastRateAppTap!).inSeconds < 5) {
      _showPremiumSnackBar(
        'Please wait a moment before trying again',
        icon: Icons.timer_outlined,
      );
      return;
    }
    _lastRateAppTap = now;
    _showPremiumSnackBar(
      'App Store rating coming soon!',
      icon: Icons.star_outline,
    );
  }

  void _logOut() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Log Out', style: AppTextStyles.headlineSmall),
        content: Text(
          'Are you sure you want to log out?',
          style: AppTextStyles.bodyMedium
              .copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  
                  // First update auth state to unauthenticated and clear tokens
                  await ref.read(authProvider.notifier).logout();
                  
                  // Invalidate stale cached data from the old session
                  ref.invalidate(userProfileProvider);
                  ref.invalidate(savedAddressesProvider);
                  ref.invalidate(unreadNotificationCountProvider);
                  ref.invalidate(rewardSummaryProvider);
                  
                  if (context.mounted) {
                    context.goNamed(RouteNames.welcome);
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                ),
                child: Text('Log Out',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getTierColor(String tier) {
    switch (tier.toUpperCase()) {
      case 'SILVER':
        return Colors.blueGrey;
      case 'GOLD':
        return AppColors.primaryGold;
      case 'PLATINUM':
        return const Color(0xFFB0C4DE); // Platinum color
      case 'BRONZE':
      default:
        return const Color(0xFFCD7F32); // Bronze color
    }
  }

  Widget _buildAvatarPlaceholder(dynamic profile, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.backgroundDark.withOpacity(0.2),
      ),
      child: Center(
        child: Text(
          profile?.initials ?? 'U',
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.backgroundDark,
          ),
        ),
      ),
    );
  }
}
