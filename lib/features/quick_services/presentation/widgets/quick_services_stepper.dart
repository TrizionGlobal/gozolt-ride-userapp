import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class QuickServicesStepper extends StatelessWidget {
  final int currentStep; // 1 = Details, 2 = Review, 3 = Payment

  const QuickServicesStepper({
    super.key,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerTheme.color ?? AppColors.textMuted.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildStep(context, 1, 'Details', isActive: currentStep >= 1),
          _buildConnector(isActive: currentStep >= 2),
          _buildStep(context, 2, 'Review', isActive: currentStep >= 2),
          _buildConnector(isActive: currentStep >= 3),
          _buildStep(context, 3, 'Payment', isActive: currentStep >= 3),
        ],
      ),
    );
  }

  Widget _buildStep(BuildContext context, int step, String label, {required bool isActive}) {
    final bool isCurrent = step == currentStep;
    final bool isCompleted = step < currentStep;
    
    final Color circleColor = isActive ? AppColors.primaryGold : (Theme.of(context).dividerTheme.color ?? AppColors.textMuted.withOpacity(0.2));
    final Color textColor = isActive ? (isCurrent ? AppColors.primaryGold : AppColors.textPrimary) : AppColors.textMuted;
    final Color iconColor = Colors.black;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: circleColor,
            boxShadow: isCurrent ? [
              BoxShadow(
                color: AppColors.primaryGold.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              )
            ] : null,
          ),
          child: Center(
            child: isCompleted
                ? Icon(Icons.check, size: 16, color: iconColor)
                : Text(
                    step.toString(),
                    style: TextStyle(
                      color: isActive ? iconColor : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: textColor,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildConnector({required bool isActive}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20, left: 8, right: 8), // offset for the label
        color: isActive ? AppColors.primaryGold : (AppColors.textMuted.withOpacity(0.2)),
      ),
    );
  }
}
