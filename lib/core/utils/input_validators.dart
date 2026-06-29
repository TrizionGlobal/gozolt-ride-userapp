import 'package:flutter/services.dart';

class InputValidators {
  InputValidators._();

  /// Blocks digits in name fields — allows letters, spaces, hyphens, apostrophes
  static final nameInputFormatter =
      FilteringTextInputFormatter.allow(RegExp(r"[a-zA-ZÀ-ÿ\s\-']"));

  /// Rejects empty, numbers-only, or special-chars-only names
  static bool isValidName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    if (RegExp(r'^[\d\s]+$').hasMatch(trimmed)) return false;
    if (RegExp(r"^[^a-zA-ZÀ-ÿ]+$").hasMatch(trimmed)) return false;
    return true;
  }

  /// Basic email validation — x@x.x pattern
  static bool isValidEmail(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return true; // email is optional
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(trimmed);
  }

  /// Allows only valid decimal amounts (up to 2 decimal places)
  static final currencyInputFormatter =
      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'));
}
