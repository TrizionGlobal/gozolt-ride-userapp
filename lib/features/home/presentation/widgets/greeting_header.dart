import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/asset_paths.dart';
import '../../../../core/router/route_names.dart';
import '../../../rewards/presentation/providers/rewards_providers.dart';
import '../providers/home_providers.dart';

class GreetingHeader extends ConsumerStatefulWidget {
  const GreetingHeader({super.key});

  @override
  ConsumerState<GreetingHeader> createState() => _GreetingHeaderState();
}

class _GreetingHeaderState extends ConsumerState<GreetingHeader> {
  OverlayEntry? _popupEntry;
  final _avatarKey = GlobalKey();

  void _togglePopup() {
    HapticFeedback.lightImpact();
    if (_popupEntry != null) {
      _dismissPopup();
      return;
    }

    final renderBox =
        _avatarKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    // Gather data from providers
    final profile = ref.read(userProfileProvider).valueOrNull;
    final reward = ref.read(rewardSummaryProvider).valueOrNull;

    final fullName =
        '${profile?.firstName ?? ''} ${profile?.lastName ?? ''}'.trim();
    final location = [
      if (profile?.city != null && profile!.city!.isNotEmpty) profile.city!,
      if (profile?.country != null && profile!.country!.isNotEmpty)
        profile.country!,
    ].join(', ');

    final isDark = Theme.of(context).brightness == Brightness.dark;

    _popupEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _dismissPopup,
        child: Stack(
          children: [
            Positioned.fill(child: Container(color: Colors.transparent)),
            Positioned(
              top: offset.dy + size.height + 8,
              right: 16,
              child: GestureDetector(
                onTap: () {}, // absorb tap on popup
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 220,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark 
                          ? AppColors.surfaceDark.withOpacity(0.95)
                          : AppColors.surfaceLight.withOpacity(0.98),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primaryGold.withOpacity(0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark 
                              ? Colors.black.withOpacity(0.4)
                              : Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Avatar
                        (profile?.avatarUrl != null && profile!.avatarUrl!.isNotEmpty)
                            ? CircleAvatar(
                                radius: 28,
                                backgroundImage: NetworkImage(ApiConstants.fullUrl(profile.avatarUrl!)),
                                onBackgroundImageError: (_, __) {},
                                backgroundColor: Theme.of(context).cardTheme.color,
                                child: Text(
                                  profile.initials,
                                  style: const TextStyle(
                                    color: AppColors.primaryGold,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 20,
                                  ),
                                ),
                              )
                            : CircleAvatar(
                                radius: 28,
                                backgroundColor: AppColors.primaryGold,
                                child: Text(
                                  profile?.initials ?? 'U',
                                  style: TextStyle(
                                    color: Theme.of(context).scaffoldBackgroundColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                        const SizedBox(height: 10),
                        // Name
                        Text(
                          fullName.isEmpty ? 'User' : fullName,
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        // Location
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_on,
                                size: 14,
                                color: AppColors.primaryGold
                                    .withOpacity(0.8)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                location.isEmpty
                                    ? 'Location not set'
                                    : location,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(height: 1, color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
                        const SizedBox(height: 12),
                        // GoCoins
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color:
                                AppColors.primaryGold.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.stars_rounded,
                                  color: AppColors.primaryGold, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                '${reward?.currentPoints ?? 0}',
                                style: AppTextStyles.titleSmall.copyWith(
                                  color: AppColors.primaryGold,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'GoCoins',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.primaryGold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Tier badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.primaryGold
                                  .withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            '${reward?.tier ?? 'BRONZE'} Member',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                              fontSize: 10,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Overlay.of(context).insert(_popupEntry!);
  }

  void _dismissPopup() {
    _popupEntry?.remove();
    _popupEntry = null;
  }

  @override
  void dispose() {
    _dismissPopup();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final unreadAsync = ref.watch(unreadNotificationCountProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // ── Logo + brand ────────────────────────────────
          Image.asset(AssetPaths.gozoltLogo, width: 32, height: 32),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    'GO',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.primaryGold,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'ZOLT',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              Text(
                'The Super App',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primaryGold,
                  fontSize: 8,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),

          const Spacer(),

          // ── Notification bell ───────────────────────────
          Stack(
            children: [
              Semantics(
                label: 'Notifications',
                button: true,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.pushNamed(RouteNames.notifications);
                  },
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.notifications_outlined,
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimaryLight,
                        size: 26,
                      ),
                    ),
                ),
              ),
              unreadAsync.when(
                data: (count) {
                  if (count == 0) return const SizedBox.shrink();
                  return Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        count > 9 ? '9+' : '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),

          const SizedBox(width: 4),

          // ── Avatar (tappable for popup) ──────────────────
          GestureDetector(
            key: _avatarKey,
            onTap: _togglePopup,
            child: profileAsync.when(
              data: (profile) {
                if (profile.avatarUrl != null &&
                    profile.avatarUrl!.isNotEmpty) {
                  return CircleAvatar(
                    radius: 18,
                    backgroundImage: NetworkImage(ApiConstants.fullUrl(profile.avatarUrl!)),
                    onBackgroundImageError: (_, __) {},
                    backgroundColor: Theme.of(context).cardTheme.color,
                    // No child — image takes full space, initials not shown
                  );
                }
                return CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryGold,
                    child: Text(
                      profile.initials,
                      style: TextStyle(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                );
              },
              loading: () => CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(context).cardTheme.color,
              ),
              error: (_, __) => CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(this.context).cardTheme.color,
                child:
                    Icon(Icons.person, color: Theme.of(this.context).brightness == Brightness.dark ? AppColors.textMuted : AppColors.textMutedLight, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
