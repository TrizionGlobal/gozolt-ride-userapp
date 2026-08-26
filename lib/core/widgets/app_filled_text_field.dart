import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class AppFilledTextField extends StatelessWidget {
  final String hint;
  final IconData icon;
  final VoidCallback? onTap;
  final bool readOnly;
  final TextEditingController? controller;
  final String? value;

  const AppFilledTextField({
    super.key,
    required this.hint,
    required this.icon,
    this.onTap,
    this.readOnly = false,
    this.controller,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPicker = onTap != null;
    
    // For pickers, we can dynamically build a controller based on the selected value
    final activeController = controller ?? 
        (isPicker && value != null && value!.isNotEmpty 
            ? TextEditingController(text: value) 
            : null);

    return TextField(
      readOnly: isPicker || readOnly,
      onTap: onTap,
      controller: activeController,
      style: AppTextStyles.bodyMedium.copyWith(
        color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
        fontSize: 13,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 13, 
          color: isDark ? Colors.white38 : Colors.black38,
        ),
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), 
          borderSide: BorderSide(color: isDark ? AppColors.borderDark : Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), 
          borderSide: const BorderSide(color: AppColors.primaryGold),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), 
          borderSide: BorderSide(color: isDark ? AppColors.borderDark : Colors.grey.shade300),
        ),
        suffixIcon: Icon(icon, color: AppColors.primaryGold, size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
