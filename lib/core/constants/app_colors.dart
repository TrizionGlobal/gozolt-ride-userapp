import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Brand ──────────────────────────────────────────────
  static const Color primaryGold = Color(0xFFF5C518);
  static const Color primaryGoldDark = Color(0xFFD4A843);

  // ── Backgrounds ────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF0D1117);
  static const Color surfaceDark = Color(0xFF161B22);
  static const Color cardDark = Color(0xFF1C2333);
  static const Color inputDark = Color(0xFF21262D);

  // ── Text ───────────────────────────────────────────────
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color textMuted = Color(0xFF6E7681);

  // ── Borders ────────────────────────────────────────────
  static const Color borderDark = Color(0xFF30363D);
  static const Color borderSubtle = Color(0xFF21262D);

  // ── Status ─────────────────────────────────────────────
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);

  // ── Light Theme ────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFF6F8FA);
  static const Color surfaceLight = Colors.white;
  static const Color cardLight = Colors.white;
  static const Color textPrimaryLight = Color(0xFF1F2328);
  static const Color textSecondaryLight = Color(0xFF656D76);
  static const Color borderLight = Color(0xFFD0D7DE);
}
