import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// Reusable error display widget.
class GozoltErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final bool compact;
  final IconData icon;

  const GozoltErrorWidget({
    super.key,
    this.message = 'Something went wrong',
    this.onRetry,
    this.compact = false,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              message,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: const Text(
                'Retry',
                style: TextStyle(color: AppColors.primaryGold),
              ),
            ),
        ],
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textMuted, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Try Again'),
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
