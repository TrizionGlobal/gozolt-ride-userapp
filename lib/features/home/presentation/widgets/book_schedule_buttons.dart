import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../../ride/presentation/providers/ride_providers.dart';

class BookScheduleButtons extends ConsumerStatefulWidget {
  const BookScheduleButtons({super.key});

  @override
  ConsumerState<BookScheduleButtons> createState() =>
      _BookScheduleButtonsState();
}

class _BookScheduleButtonsState extends ConsumerState<BookScheduleButtons> {
  bool _isBookSelected = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Book a ride
          Expanded(
            child: _PillButton(
              icon: Icons.circle,
              iconSize: 8,
              label: 'Book a ride',
              isSelected: _isBookSelected,
              onTap: () {
                setState(() => _isBookSelected = true);
                ref.read(isScheduleModeProvider.notifier).state = false;
                context.pushNamed(RouteNames.searchDestination);
              },
            ),
          ),
          const SizedBox(width: 12),
          // Schedule ride
          Expanded(
            child: _PillButton(
              icon: Icons.calendar_today_outlined,
              iconSize: 16,
              label: 'Schedule ride',
              isSelected: !_isBookSelected,
              onTap: () {
                setState(() => _isBookSelected = false);
                ref.read(isScheduleModeProvider.notifier).state = true;
                context.pushNamed(RouteNames.searchDestination);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PillButton({
    required this.icon,
    required this.iconSize,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryGold : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: AppColors.primaryGold,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: iconSize,
                color: isSelected
                    ? Theme.of(context).scaffoldBackgroundColor
                    : AppColors.primaryGold,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.titleSmall.copyWith(
                  color: isSelected
                      ? Theme.of(context).scaffoldBackgroundColor
                      : AppColors.primaryGold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
