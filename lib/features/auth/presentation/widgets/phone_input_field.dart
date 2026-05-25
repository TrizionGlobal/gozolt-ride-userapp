import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/models/country_code.dart';

class PhoneInputField extends StatelessWidget {
  final TextEditingController controller;
  final CountryCode selectedCountry;
  final VoidCallback onCountryTap;
  final String? errorText;
  final FocusNode? focusNode;

  const PhoneInputField({
    super.key,
    required this.controller,
    required this.selectedCountry,
    required this.onCountryTap,
    this.errorText,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: errorText != null
                  ? AppColors.error
                  : (Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
            ),
          ),
          child: Row(
            children: [
              // Country code selector
              GestureDetector(
                onTap: onCountryTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  height: double.infinity,
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
                      ),
                    ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        selectedCountry.flag,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        selectedCountry.dialCode,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

              // Phone number input
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: TextInputType.phone,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(12),
                  ],
                  decoration: InputDecoration(
                    hintText: 'Enter Mobile Number',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textMuted,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              errorText!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
