import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class MaltaEmergencySheet extends StatelessWidget {
  final void Function(String name, String phone) onCallSelected;

  const MaltaEmergencySheet({
    super.key,
    required this.onCallSelected,
  });

  static const List<Map<String, String>> _services = [
    {
      'name': 'General Emergency',
      'phone': '112',
    },
    {
      'name': 'Ambulance Service',
      'phone': '196',
    },
    {
      'name': 'Police Department',
      'phone': '191',
    },
    {
      'name': 'Civil Protection & Fire',
      'phone': '199',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Malta Emergency Services',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // List of Services
          ..._services.map((service) {
            final name = service['name']!;
            final phone = service['phone']!;
            final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

            return Column(
              children: [
                ListTile(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                    onCallSelected(name, phone);
                  },
                  leading: CircleAvatar(
                    backgroundColor: AppColors.error.withOpacity(0.15),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    name,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    phone,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.call,
                    color: AppColors.error,
                    size: 20,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    height: 1,
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
