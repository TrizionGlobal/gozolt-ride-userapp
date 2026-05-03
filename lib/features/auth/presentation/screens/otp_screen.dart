import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/gozolt_button.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';
import '../widgets/auth_back_button.dart';
import '../widgets/otp_input_field.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpKey = GlobalKey<OtpInputFieldState>();
  Timer? _resendTimer;
  int _resendSeconds = AppConstants.otpResendSeconds;
  bool _canResend = false;
  bool _hasError = false;
  String? _errorText;
  String _currentOtp = '';

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    _resendSeconds = AppConstants.otpResendSeconds;
    _canResend = false;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendSeconds > 0) {
          _resendSeconds--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }

  void _onOtpCompleted(String otp) {
    setState(() {
      _currentOtp = otp;
      _hasError = false;
      _errorText = null;
    });
  }

  void _onOtpChanged() {
    if (_hasError) {
      setState(() {
        _hasError = false;
        _errorText = null;
      });
    }
  }

  void _verify() {
    if (_currentOtp.length != AppConstants.otpLength) return;
    HapticFeedback.mediumImpact();

    final phone = ref.read(phoneNumberProvider);
    final isRegister = ref.read(isRegisterFlowProvider);

    if (AppConstants.kDevBypass) {
      // In dev mode: register → profile, login → home
      if (isRegister) {
        context.goNamed(RouteNames.completeProfile);
      } else {
        context.goNamed(RouteNames.home);
      }
      return;
    }

    ref.read(authProvider.notifier).verifyOtp(
          phone: phone,
          otp: _currentOtp,
        );
  }

  void _resendOtp() {
    if (!_canResend) return;
    HapticFeedback.lightImpact();
    final phone = ref.read(phoneNumberProvider);
    // Use resendOtp (not sendOtp) to avoid triggering otpSent state
    // which would push a new OTP screen from the phone entry listener.
    ref.read(authProvider.notifier).resendOtp(phone);
    // Clear input and error, restart timer
    _otpKey.currentState?.clear();
    setState(() {
      _currentOtp = '';
      _hasError = false;
      _errorText = null;
    });
    _startResendTimer();
  }

  String get _formattedTimer {
    final mins = (_resendSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (_resendSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  String get _maskedPhone {
    final phone = ref.read(phoneNumberProvider);
    if (phone.length > 6) {
      return '${phone.substring(0, phone.length - 4)} ${phone.substring(phone.length - 4)}';
    }
    return phone;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    final isRegister = ref.watch(isRegisterFlowProvider);

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.status == AuthStatus.authenticated) {
        // Login flow → go home. Register flow → complete profile.
        if (isRegister) {
          context.goNamed(RouteNames.completeProfile);
        } else {
          context.goNamed(RouteNames.home);
        }
      } else if (next.status == AuthStatus.needsProfile) {
        context.goNamed(RouteNames.completeProfile);
      } else if (next.status == AuthStatus.error && next.errorMessage != null) {
        setState(() {
          _hasError = true;
          _errorText = next.errorMessage;
          _currentOtp = '';
        });
        _otpKey.currentState?.shake();
        // Clear the input field after a short delay so user can re-enter
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            _otpKey.currentState?.clear();
          }
        });
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
              AuthBackButton(onTap: () => context.pop()),

              const SizedBox(height: 40),

              // ── Title ──────────────────────────────────────
              Center(
                child: Text(
                  'Verify Your Number',
                  style: AppTextStyles.headlineMedium,
                ),
              ),

              const SizedBox(height: 12),

              // ── Subtitle with Edit link ────────────────────
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    Text(
                      "We've sent a code to ",
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      _maskedPhone,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Text(
                        'Edit',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primaryGold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // ── OTP Input ──────────────────────────────────
              OtpInputField(
                key: _otpKey,
                onCompleted: _onOtpCompleted,
                hasError: _hasError,
                onChanged: _onOtpChanged,
              ),

              // ── Error text ─────────────────────────────────
              if (_errorText != null) ...[
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    _errorText!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // ── Resend timer ───────────────────────────────
              Center(
                child: _canResend
                    ? GestureDetector(
                        onTap: _resendOtp,
                        child: Text(
                          'Resend Code',
                          style: AppTextStyles.titleSmall.copyWith(
                            color: AppColors.primaryGold,
                          ),
                        ),
                      )
                    : Text(
                        'Resend in $_formattedTimer',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
              ),

              const Spacer(),

              // ── Verify button ──────────────────────────────
              GozoltButton(
                label: 'Verify',
                width: double.infinity,
                isLoading: isLoading,
                onPressed: (_currentOtp.length == AppConstants.otpLength && !isLoading)
                    ? _verify
                    : null,
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
