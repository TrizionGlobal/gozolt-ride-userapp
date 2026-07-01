import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
      } else if (ModalRoute.of(context)?.isCurrent == true) {
        if (next.status == AuthStatus.authenticated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Logged in successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
          context.goNamed(RouteNames.home);
        } else if (next.status == AuthStatus.needsPhoneLink) {
          context.pushNamed(RouteNames.linkPhone);
        } else if (next.status == AuthStatus.needsProfile) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
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
                  ref.watch(isRegisterFlowProvider)
                      ? 'Create Your Account'
                      : 'Welcome Back',
                  style: AppTextStyles.headlineMedium,
                ),
              ),

              const SizedBox(height: 8),

              // ── Subtitle ───────────────────────────────────
              Center(
                child: Text(
                  ref.watch(isRegisterFlowProvider)
                      ? 'Enter your phone number to register'
                      : 'Enter your phone number to log in',
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
              _buildSocialIconRow(context),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

static const String _googleSvg = '''
<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/>
  <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/>
  <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l2.85-2.22c-.62-.63-1.09-1.39-1.39-2.22z" fill="#FBBC05"/>
  <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84c.87-2.6 3.3-4.52 6.16-4.52z" fill="#EA4335"/>
</svg>
''';

  Widget _buildSocialIconRow(BuildContext context) {
    return Column(
      children: [
        // Divider with "or"
        Row(
          children: [
            Expanded(child: Divider(color: Theme.of(context).dividerTheme.color)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                ref.watch(isRegisterFlowProvider)
                    ? 'or register with'
                    : 'or sign in with',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Expanded(child: Divider(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark)),
          ],
        ),

        const SizedBox(height: 20),

        // Google + Apple logos side by side
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialIcon(
              svgString: _googleSvg,
              onTap: () => _handleSocial('GOOGLE'),
              isGoogle: true,
            ),
            const SizedBox(width: 24),
            _buildSocialIcon(
              iconData: Icons.apple,
              onTap: () => _handleSocial('APPLE'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialIcon({
    IconData? iconData,
    String? svgString,
    required VoidCallback onTap,
    bool isGoogle = false,
  }) {
    final iconColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : const Color(0xFF1F2937);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).cardTheme.color,
          border: Border.all(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
        ),
        child: Center(
          child: iconData != null
              ? Icon(iconData, size: 22, color: iconColor)
              : SvgPicture.string(
                  svgString!,
                  width: 22,
                  height: 22,
                  colorFilter: isGoogle
                      ? null
                      : ColorFilter.mode(iconColor, BlendMode.srcIn),
                ),
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
      serverClientId: '715853709143-003i867cfpfbnn49j38fk08mrvgodd1u.apps.googleusercontent.com',
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
    try {
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
    } catch (e) {
      // Fallback/Mock for Simulator or Android testing
      debugPrint('Native Apple Sign-In failed or unsupported. Using fallback mock. Error: $e');
      final mockIdToken = 'mock_apple_token_${DateTime.now().millisecondsSinceEpoch}';
      
      ref.read(authProvider.notifier).socialLogin(
        provider: 'APPLE',
        idToken: mockIdToken,
        firstName: 'Apple',
        lastName: 'User',
      );
    }
  }
}
