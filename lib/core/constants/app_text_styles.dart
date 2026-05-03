import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppTextStyles {
  static const String _fontFamily = 'Roboto';

  // ── Display ────────────────────────────────────────────
  static const TextStyle displayLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 57,
    fontWeight: FontWeight.w900,
    color: AppColors.textPrimary,
  );

  // ── Headlines ──────────────────────────────────────────
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // ── Titles ─────────────────────────────────────────────
  static const TextStyle titleLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // ── Body ───────────────────────────────────────────────
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // ── Labels ─────────────────────────────────────────────
  static const TextStyle labelLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );

  // ── Splash / Branding ─────────────────────────────────
  static const TextStyle splashBrandGo = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 42,
    fontWeight: FontWeight.w900,
    color: AppColors.primaryGold,
    letterSpacing: 2,
  );

  static const TextStyle splashBrandZolt = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 42,
    fontWeight: FontWeight.w900,
    color: AppColors.textPrimary,
    letterSpacing: 2,
  );

  static const TextStyle splashSubtitle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryGold,
    letterSpacing: 3,
  );

  // ── Onboarding ─────────────────────────────────────────
  static const TextStyle onboardingTitle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle onboardingSubtitle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.6,
  );

  // ── Button ─────────────────────────────────────────────
  static const TextStyle button = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );
}
