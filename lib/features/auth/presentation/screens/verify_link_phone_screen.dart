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

class VerifyLinkPhoneScreen extends ConsumerStatefulWidget {
  const VerifyLinkPhoneScreen({super.key});

  @override
  ConsumerState<VerifyLinkPhoneScreen> createState() => _VerifyLinkPhoneScreenState();
}

class _VerifyLinkPhoneScreenState extends ConsumerState<VerifyLinkPhoneScreen> {
  final _otpKey = GlobalKey<OtpInputFieldState>();
  Timer? _resendTimer;
  int _resendSeconds = AppConstants.otpResendSeconds;
  int _validitySeconds = 300; // 5 minutes
  bool _canResend = false;
  bool _hasError = false;
  String? _errorText;
  String _currentOtp = '';
  bool _canPop = false;

  @override
  void initState() {
    super.initState();
    _startTimers();
  }

  void _startTimers() {
    _resendSeconds = AppConstants.otpResendSeconds;
    _validitySeconds = 300;
    _canResend = false;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_resendSeconds > 0) {
          _resendSeconds--;
        } else {
          _canResend = true;
        }

        if (_validitySeconds > 0) {
          _validitySeconds--;
        } else {
          // OTP Expired
          _hasError = true;
          _errorText = 'OTP has expired. Please resend.';
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
    if (_validitySeconds <= 0) {
      setState(() {
        _hasError = true;
        _errorText = 'OTP has expired. Please resend.';
      });
      return;
    }
    if (_currentOtp.length != AppConstants.otpLength) return;
    HapticFeedback.mediumImpact();

    final phone = ref.read(phoneNumberProvider);

    ref.read(authProvider.notifier).verifyLinkPhone(
          phoneInput: phone,
          otp: _currentOtp,
        );
  }

  void _resendOtp() {
    if (!_canResend) return;
    HapticFeedback.lightImpact();
    final phone = ref.read(phoneNumberProvider);
    ref.read(authProvider.notifier).linkPhone(phone); // Calling linkPhone again sends OTP
    // Clear input and error, restart timer
    _otpKey.currentState?.clear();
    setState(() {
      _currentOtp = '';
      _hasError = false;
      _errorText = null;
    });
    _startTimers();
  }

  Future<bool> _showExitDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Cancel Verification?', style: AppTextStyles.titleMedium),
          content: Text(
            'If you exit now, this OTP will be invalidated.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Stay', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: Text('Exit', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  void _onBackTapped() async {
    final shouldExit = await _showExitDialog();
    if (shouldExit && mounted) {
      setState(() => _canPop = true);
      // Wait for rebuild to apply canPop = true
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pop();
      });
    }
  }

  String _formatTime(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
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

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.status == AuthStatus.authenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged in successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.goNamed(RouteNames.home);
      } else if (next.status == AuthStatus.needsProfile) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone linked successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
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

    return PopScope(
      canPop: _canPop,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _onBackTapped();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // ── Back button ────────────────────────────────
              AuthBackButton(onTap: _onBackTapped),

              const SizedBox(height: 40),

              // ── Title ──────────────────────────────────────
              Center(
                child: Text(
                  'Verify Phone Link',
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
                      "We've sent a code to",
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _maskedPhone,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _onBackTapped,
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
              const SizedBox(height: 40),

              // ── Timers Section ─────────────────────────────
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color?.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _hasError ? AppColors.error.withOpacity(0.3) : (Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 16,
                            color: _validitySeconds < 60 ? AppColors.error : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'OTP expires in: ',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            _formatTime(_validitySeconds),
                            style: AppTextStyles.titleSmall.copyWith(
                              color: _validitySeconds < 60 ? AppColors.error : AppColors.primaryGold,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _canResend
                            ? TextButton.icon(
                                key: const ValueKey('resend_btn'),
                                onPressed: _resendOtp,
                                icon: const Icon(Icons.refresh, size: 18),
                                label: Text('Resend Code'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primaryGold,
                                  textStyle: AppTextStyles.titleSmall,
                                ),
                              )
                            : Padding(
                                key: const ValueKey('resend_countdown'),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  'Resend code in $_resendSeconds seconds',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // ── Verify button ──────────────────────────────
              GozoltButton(
                label: 'Verify',
                width: double.infinity,
                isLoading: isLoading,
                onPressed: (_currentOtp.length == AppConstants.otpLength && !isLoading && _validitySeconds > 0)
                    ? _verify
                    : null,
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
