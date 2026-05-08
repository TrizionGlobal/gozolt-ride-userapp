import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
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

class PhoneEntryScreen extends ConsumerStatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  ConsumerState<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends ConsumerState<PhoneEntryScreen> {
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

    final isRegister = ref.read(isRegisterFlowProvider);
    ref.read(authProvider.notifier).sendOtp(phone, isRegister: isRegister);
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
        context.pushNamed(RouteNames.otp);
      } else if (next.status == AuthStatus.authenticated) {
        context.goNamed(RouteNames.home);
      } else if (next.status == AuthStatus.needsProfile) {
        context.pushNamed(RouteNames.completeProfile);
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
      backgroundColor: AppColors.backgroundDark,
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
                  width: 72,
                  height: 72,
                ),
              ),

              const SizedBox(height: 28),

              // ── Title ──────────────────────────────────────
              Center(
                child: Text(
                  'Enter Your Phone Number',
                  style: AppTextStyles.headlineMedium,
                ),
              ),

              const SizedBox(height: 8),

              // ── Subtitle ───────────────────────────────────
              Center(
                child: Text(
                  "We'll send you a verification code",
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

              // ── "Or sign in with" divider + icon buttons ───
              _buildSocialIconRow(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialIconRow() {
    return Column(
      children: [
        // Divider with "or"
        Row(
          children: [
            const Expanded(child: Divider(color: AppColors.borderDark)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'or sign in with',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const Expanded(child: Divider(color: AppColors.borderDark)),
          ],
        ),

        const SizedBox(height: 20),

        // Google + Apple logos side by side
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialIcon(AssetPaths.googleLogo, () => _handleSocial('GOOGLE')),
            const SizedBox(width: 24),
            _buildSocialIcon(AssetPaths.appleLogo, () => _handleSocial('APPLE')),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialIcon(String logoPath, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surfaceDark,
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Center(
          child: Image.asset(logoPath, width: 26, height: 26),
        ),
      ),
    );
  }

  Future<void> _handleSocial(String provider) async {
    try {
      if (provider == 'GOOGLE') {
        await _handleGoogleSignIn();
      } else if (provider == 'APPLE') {
        await _handleAppleSignIn();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign in failed: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
    );

    final GoogleSignInAccount? account = await googleSignIn.signIn();
    if (account == null) return; // User cancelled

    final GoogleSignInAuthentication auth = await account.authentication;
    final String? idToken = auth.idToken;

    if (idToken == null) {
      throw Exception('Failed to get Google ID token');
    }

    ref.read(authProvider.notifier).socialLogin(
      provider: 'GOOGLE',
      idToken: idToken,
      firstName: account.displayName?.split(' ').first,
      lastName: account.displayName?.split(' ').skip(1).join(' '),
    );
  }

  Future<void> _handleAppleSignIn() async {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final String? idToken = credential.identityToken;
    if (idToken == null) {
      throw Exception('Failed to get Apple ID token');
    }

    ref.read(authProvider.notifier).socialLogin(
      provider: 'APPLE',
      idToken: idToken,
      firstName: credential.givenName,
      lastName: credential.familyName,
    );
  }
}
