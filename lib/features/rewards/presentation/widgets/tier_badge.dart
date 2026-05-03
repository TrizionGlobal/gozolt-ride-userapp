import 'package:flutter/material.dart';
import '../../../../core/constants/app_text_styles.dart';

class TierBadge extends StatelessWidget {
  final String tier;
  final bool small;

  const TierBadge({super.key, required this.tier, this.small = false});

  @override
  Widget build(BuildContext context) {
    final colors = _tierColors(tier);
    final displayName = _tierDisplayName(tier);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 14,
        vertical: small ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(small ? 6 : 12),
        border: Border.all(color: colors.$2, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _tierIcon(tier),
            size: small ? 12 : 14,
            color: colors.$3,
          ),
          SizedBox(width: small ? 3 : 5),
          Text(
            small ? displayName.toUpperCase() : '$displayName Tier',
            style: (small ? AppTextStyles.labelSmall : AppTextStyles.labelLarge)
                .copyWith(
              color: colors.$3,
              fontWeight: FontWeight.w700,
              fontSize: small ? 10 : 12,
              letterSpacing: small ? 0.5 : 1,
            ),
          ),
        ],
      ),
    );
  }

  static String _tierDisplayName(String tier) {
    switch (tier) {
      case 'BRONZE':
        return 'Bronze';
      case 'SILVER':
        return 'Silver';
      case 'GOLD':
        return 'Gold';
      case 'PLATINUM':
        return 'Platinum';
      default:
        return tier;
    }
  }

  static IconData _tierIcon(String tier) {
    switch (tier) {
      case 'BRONZE':
        return Icons.shield_outlined;
      case 'SILVER':
        return Icons.shield;
      case 'GOLD':
        return Icons.workspace_premium;
      case 'PLATINUM':
        return Icons.diamond;
      default:
        return Icons.shield_outlined;
    }
  }

  /// Returns (background, border, text/icon) colors.
  static (Color, Color, Color) _tierColors(String tier) {
    switch (tier) {
      case 'BRONZE':
        return (
          const Color(0xFF3D2B1F),
          const Color(0xFFCD7F32),
          const Color(0xFFCD7F32),
        );
      case 'SILVER':
        return (
          const Color(0xFF2A2A30),
          const Color(0xFFC0C0C0),
          const Color(0xFFC0C0C0),
        );
      case 'GOLD':
        return (
          const Color(0xFF3D3415),
          const Color(0xFFF5C518),
          const Color(0xFFF5C518),
        );
      case 'PLATINUM':
        return (
          const Color(0xFF2A1F3D),
          const Color(0xFFB388FF),
          const Color(0xFFB388FF),
        );
      default:
        return (
          const Color(0xFF3D2B1F),
          const Color(0xFFCD7F32),
          const Color(0xFFCD7F32),
        );
    }
  }
}
