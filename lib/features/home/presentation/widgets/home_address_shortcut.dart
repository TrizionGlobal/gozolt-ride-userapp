import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../providers/home_providers.dart';

class HomeAddressShortcut extends ConsumerWidget {
  const HomeAddressShortcut({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(savedAddressesProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: addressesAsync.when(
        data: (addresses) {
          final homeAddr = addresses
              .where((a) => a.label.toLowerCase() == 'home')
              .toList();

          if (homeAddr.isEmpty) {
            return _buildCard(
              icon: Icons.add_rounded,
              iconColor: AppColors.primaryGold,
              title: 'Add Home Address',
              subtitle: 'Set your home for quick booking',
              onTap: () {
                // TODO: Open address editor (Phase 11)
              },
            );
          }

          return _buildCard(
            icon: Icons.home_rounded,
            iconColor: AppColors.primaryGold,
            title: 'Home',
            subtitle: homeAddr.first.address,
            onTap: () {
              // TODO: Quick book to Home address
            },
          );
        },
        loading: () => _buildShimmerCard(),
        error: (_, _) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderDark, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}
