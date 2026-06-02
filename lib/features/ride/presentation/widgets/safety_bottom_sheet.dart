import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../home/presentation/providers/home_providers.dart';

class SafetyBottomSheet extends ConsumerWidget {
  final VoidCallback onShareTrip;
  final VoidCallback onCallEmergency;
  final VoidCallback onAlertContacts;
  final VoidCallback onReportIssue;

  const SafetyBottomSheet({
    super.key,
    required this.onShareTrip,
    required this.onCallEmergency,
    required this.onAlertContacts,
    required this.onReportIssue,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userProfile = ref.watch(userProfileProvider).valueOrNull;
    final contacts = userProfile?.emergencyContacts;
    
    String alertSubtitle = 'Notify your emergency contacts';
    if (contacts != null && contacts.isNotEmpty) {
      final names = contacts.map((c) => c['name']).join(', ');
      alertSubtitle = 'Alert $names';
    }
    const String callSubtitle = 'Call Malta emergency services (112)';

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 20,
        top: 16,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Safety Toolkit',
            style: AppTextStyles.titleMedium.copyWith(
              color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Get help and share your ride details with trusted contacts.',
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 20),
          
          _SafetyOption(
            icon: Icons.local_phone_rounded,
            title: 'Call Emergency',
            subtitle: callSubtitle,
            iconColor: AppColors.error,
            onTap: onCallEmergency,
            isDark: isDark,
          ),
          
          _SafetyOption(
            icon: Icons.share_rounded,
            title: 'Share Live Trip',
            subtitle: 'Share your location and vehicle details',
            iconColor: AppColors.primaryGold,
            onTap: onShareTrip,
            isDark: isDark,
          ),
          
          _SafetyOption(
            icon: Icons.notification_important_rounded,
            title: 'Alert Contacts',
            subtitle: alertSubtitle,
            iconColor: AppColors.warning,
            onTap: onAlertContacts,
            isDark: isDark,
          ),
          
          _SafetyOption(
            icon: Icons.support_agent_rounded,
            title: 'Contact Support',
            subtitle: 'Get help from our 24/7 team',
            iconColor: AppColors.info,
            onTap: onReportIssue,
            isDark: isDark,
          ),
          
          _SafetyOption(
            icon: Icons.report_problem_rounded,
            title: 'Report Safety Issue',
            subtitle: 'Report a driver or safety concern',
            iconColor: AppColors.textSecondary,
            onTap: onReportIssue,
            isDark: isDark,
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class _SafetyOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final VoidCallback onTap;
  final bool isDark;
  final bool showDivider;

  const _SafetyOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.onTap,
    required this.isDark,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pop(context);
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.titleSmall.copyWith(
                          color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                ),
              ],
            ),
          ),
          if (showDivider)
            Divider(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              height: 1,
            ),
        ],
      ),
    );
  }
}
