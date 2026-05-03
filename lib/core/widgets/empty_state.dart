import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// Reusable empty state widget for list screens.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? ctaLabel;
  final VoidCallback? onCtaTap;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.ctaLabel,
    this.onCtaTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textMuted, size: 56),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTextStyles.titleMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (ctaLabel != null && onCtaTap != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onCtaTap,
                icon: const Icon(Icons.add, size: 18),
                label: Text(ctaLabel!),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryGold,
                  side: const BorderSide(color: AppColors.primaryGold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
