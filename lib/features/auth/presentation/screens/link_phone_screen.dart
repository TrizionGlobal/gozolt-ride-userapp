import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/asset_paths.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/gozolt_button.dart';
import '../../data/models/country_code.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';
import '../widgets/auth_back_button.dart';
import '../widgets/country_code_picker.dart';
import '../widgets/phone_input_field.dart';

class LinkPhoneScreen extends ConsumerStatefulWidget {
  const LinkPhoneScreen({super.key});

  @override
  ConsumerState<LinkPhoneScreen> createState() => _LinkPhoneScreenState();
}

class _LinkPhoneScreenState extends ConsumerState<LinkPhoneScreen> {
  final _phoneController = TextEditingController();
  CountryCode _selectedCountry = supportedCountryCodes.first; // Malta
  String? _phoneError;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String get _fullPhone => '${_selectedCountry.dialCode}${_phoneController.text.trim()}';

  bool get _isPhoneValid {
    final digits = _phoneController.text.trim();
    return digits.length >= 7 && digits.length <= 12;
  }

  void _onContinue() {
    HapticFeedback.mediumImpact();
    if (!_isPhoneValid) {
      setState(() => _phoneError = 'Please enter a valid phone number');
      return;
    }
    setState(() => _phoneError = null);

    final phone = _fullPhone;
    ref.read(phoneNumberProvider.notifier).state = phone;
    ref.read(selectedDialCodeProvider.notifier).state = _selectedCountry.dialCode;

    ref.read(authProvider.notifier).linkPhone(phone);
  }

  void _showCountryPicker() {
    CountryCodePicker.show(
      context,
      selected: _selectedCountry,
      onSelected: (country) {
        setState(() => _selectedCountry = country);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (prev?.status == AuthStatus.loading &&
          next.status == AuthStatus.otpSent) {
        context.pushNamed(RouteNames.verifyLinkPhone);
      } else if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(authProvider.notifier).clearError();
      }
    });

    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // ── Back button ────────────────────────────────
              AuthBackButton(onTap: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.goNamed(RouteNames.welcome);
                }
              }),

              const SizedBox(height: 24),

              // ── Logo (centered) ────────────────────────────
              Center(
                child: Image.asset(
                  AssetPaths.gozoltLogo,
                  width: 84,
                  height: 84,
                ),
              ),

              const SizedBox(height: 16),

              // ── Title ──────────────────────────────────────
              Center(
                child: Text(
                  'Link Your Phone Number',
                  style: AppTextStyles.headlineMedium,
                ),
              ),

              const SizedBox(height: 8),

              // ── Subtitle ───────────────────────────────────
              Center(
                child: Text(
                  "We need this to connect you with drivers",
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // ── Phone input ────────────────────────────────
              PhoneInputField(
                controller: _phoneController,
                selectedCountry: _selectedCountry,
                onCountryTap: _showCountryPicker,
                errorText: _phoneError,
              ),

              const Spacer(),

              // ── Continue button ────────────────────────────
              GozoltButton(
                label: 'Continue',
                width: double.infinity,
                isLoading: isLoading,
                onPressed: isLoading ? null : _onContinue,
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
