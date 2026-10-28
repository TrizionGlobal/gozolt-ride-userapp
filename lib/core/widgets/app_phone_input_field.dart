import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../../features/auth/data/models/country_code.dart';
import '../../features/auth/presentation/widgets/country_code_picker.dart';

/// A universal, reusable mobile number input field with country code selection
/// and per-country length restriction.
///
/// Can be used across all services (Airport Transfers, Rentals, Quick Services, Auth).
class AppPhoneInputField extends StatefulWidget {
  final TextEditingController controller;
  final CountryCode? initialCountry;
  final ValueChanged<CountryCode>? onCountryChanged;
  final String? label;
  final String? hintText;
  final String? errorText;
  final FormFieldValidator<String>? validator;
  final bool readOnly;
  final Color? fillColor;
  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;

  const AppPhoneInputField({
    super.key,
    required this.controller,
    this.initialCountry,
    this.onCountryChanged,
    this.label,
    this.hintText,
    this.errorText,
    this.validator,
    this.readOnly = false,
    this.fillColor,
    this.focusNode,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
  });

  @override
  State<AppPhoneInputField> createState() => AppPhoneInputFieldState();
}

class AppPhoneInputFieldState extends State<AppPhoneInputField> {
  late CountryCode _selectedCountry;
  final GlobalKey<FormFieldState<String>> _fieldKey =
      GlobalKey<FormFieldState<String>>();

  CountryCode get selectedCountry => _selectedCountry;

  /// Returns the full international phone number e.g. "+35679123456" or "+919876543210"
  String get fullPhoneNumber =>
      '${_selectedCountry.dialCode}${widget.controller.text.trim()}';

  @override
  void initState() {
    super.initState();
    _selectedCountry = widget.initialCountry ?? CountryCode.defaultCountry;
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fieldKey.currentState?.didChange(widget.controller.text);
        if (_fieldKey.currentState?.hasError == true) {
          _fieldKey.currentState?.validate();
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant AppPhoneInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCountry != null &&
        widget.initialCountry != oldWidget.initialCountry &&
        widget.initialCountry != _selectedCountry) {
      _selectedCountry = widget.initialCountry!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _fieldKey.currentState?.didChange(widget.controller.text);
          if (_fieldKey.currentState?.hasError == true) {
            _fieldKey.currentState?.validate();
          }
        }
      });
    }
  }

  void _openCountryPicker() {
    if (widget.readOnly) return;
    CountryCodePicker.show(
      context,
      selected: _selectedCountry,
      onSelected: (newCountry) {
        setState(() {
          _selectedCountry = newCountry;
          // Trim if current text exceeds the new country's maximum length
          if (widget.controller.text.length > newCountry.maxLength) {
            widget.controller.text =
                widget.controller.text.substring(0, newCountry.maxLength);
          }
        });
        _fieldKey.currentState?.didChange(widget.controller.text);
        if (_fieldKey.currentState?.hasError == true) {
          _fieldKey.currentState?.validate();
        }
        widget.onCountryChanged?.call(newCountry);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = widget.fillColor ??
        (isDark ? const Color(0xFF141414) : const Color(0xFFF9FAFB));
    final borderColor = isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7);

    return FormField<String>(
      key: _fieldKey,
      initialValue: widget.controller.text,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) {
        final raw = widget.controller.text.trim();
        if (widget.validator != null) {
          return widget.validator!(raw);
        }
        if (raw.isEmpty) {
          return 'Phone number is required';
        }
        if (raw.length < _selectedCountry.minLength) {
          return 'Enter a valid ${_selectedCountry.maxLength}-digit phone number';
        }
        return null;
      },
      builder: (fieldState) {
        final effectiveError = widget.errorText ?? fieldState.errorText;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: effectiveError != null
                      ? AppColors.error
                      : borderColor,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.label != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 14, top: 8),
                      child: Text(
                        widget.label!,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.textSecondary
                              : AppColors.textSecondaryLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      // Country Picker Trigger Button
                      InkWell(
                        onTap: _openCountryPicker,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _selectedCountry.flag,
                                style: const TextStyle(fontSize: 18),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _selectedCountry.dialCode,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.textPrimary
                                      : AppColors.textPrimaryLight,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 18,
                                color: isDark
                                    ? AppColors.textSecondary
                                    : AppColors.textSecondaryLight,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Divider
                      Container(
                        height: 24,
                        width: 1,
                        color: borderColor,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      // National Phone Input
                      Expanded(
                        child: TextField(
                          controller: widget.controller,
                          focusNode: widget.focusNode,
                          readOnly: widget.readOnly,
                          keyboardType: TextInputType.phone,
                          textInputAction: widget.textInputAction,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isDark
                                ? AppColors.textPrimary
                                : AppColors.textPrimaryLight,
                            fontWeight: FontWeight.w500,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(
                                _selectedCountry.maxLength),
                          ],
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                            hintText: widget.hintText ??
                                'Enter ${_selectedCountry.maxLength} digits',
                            hintStyle: AppTextStyles.bodyMedium.copyWith(
                              color: isDark
                                  ? AppColors.textSecondary
                                  : AppColors.textMutedLight,
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                          ),
                          onChanged: (val) {
                            fieldState.didChange(val);
                            if (fieldState.hasError) {
                              fieldState.validate();
                            }
                            widget.onChanged?.call(val);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (effectiveError != null) ...[
              const SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(
                  effectiveError,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
