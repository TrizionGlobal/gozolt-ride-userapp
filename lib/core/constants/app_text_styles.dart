import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract final class AppTextStyles {
  // ── Display ────────────────────────────────────────────
  static final TextStyle displayLarge = GoogleFonts.poppins(
    fontSize: 57,
    fontWeight: FontWeight.w900,
    color: null,
  );

  // ── Headlines ──────────────────────────────────────────
  static final TextStyle headlineLarge = GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: null,
  );

  static final TextStyle headlineMedium = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: null,
  );

  static final TextStyle headlineSmall = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: null,
  );

  // ── Titles ─────────────────────────────────────────────
  static final TextStyle titleLarge = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: null,
  );

  static final TextStyle titleMedium = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: null,
  );

  static final TextStyle titleSmall = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: null,
  );

  // ── Body ───────────────────────────────────────────────
  static final TextStyle bodyLarge = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: null,
  );

  static final TextStyle bodyMedium = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: null,
  );

  static final TextStyle bodySmall = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: null,
  );

  // ── Labels ─────────────────────────────────────────────
  static final TextStyle labelLarge = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: null,
    letterSpacing: 0.5,
  );

  static final TextStyle labelSmall = GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: null,
    letterSpacing: 0.5,
  );

  // ── Splash / Branding ─────────────────────────────────
  static final TextStyle splashBrandGo = GoogleFonts.poppins(
    fontSize: 42,
    fontWeight: FontWeight.w900,
    color: AppColors.primaryGold,
    letterSpacing: 2,
  );

  static final TextStyle splashBrandZolt = GoogleFonts.poppins(
    fontSize: 42,
    fontWeight: FontWeight.w900,
    color: null,
    letterSpacing: 2,
  );

  static final TextStyle splashSubtitle = GoogleFonts.poppins(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryGold,
    letterSpacing: 3,
  );

  // ── Onboarding ─────────────────────────────────────────
  static final TextStyle onboardingTitle = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: null,
    height: 1.3,
  );

  static final TextStyle onboardingSubtitle = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: null,
    height: 1.6,
  );

  // ── Button ─────────────────────────────────────────────
  static final TextStyle button = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );
}
