import 'package:flutter/services.dart';

class InputValidators {
  InputValidators._();

  /// Blocks digits in name fields — allows letters, spaces, hyphens, apostrophes
  static final nameInputFormatter =
      FilteringTextInputFormatter.allow(RegExp(r"[a-zA-ZÀ-ÿ\s\-']"));

  /// Strictly blocks any letters from number fields (allows only digits, +, space, hyphen)
  static final phoneInputFormatter =
      FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s-]'));

  /// Allows only decimal numbers (digits and single decimal point)
  static final decimalNumberFormatter =
      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'));

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

  /// Form field email validator
  static String? validateEmail(String? value, {bool required = true}) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return required ? 'Please enter an email address' : null;
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Allows only valid decimal amounts (up to 2 decimal places)
  static final currencyInputFormatter =
      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'));
}

/// Automatically capitalizes the first letter of each word
class CapitalizeWordsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final text = newValue.text;
    final buffer = StringBuffer();
    bool capitalizeNext = true;

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      if (capitalizeNext && RegExp(r'[a-zA-ZÀ-ÿ]').hasMatch(char)) {
        buffer.write(char.toUpperCase());
        capitalizeNext = false;
      } else {
        buffer.write(char);
        if (char == ' ' || char == '-' || char == "'" || char == '(' || char == '[') {
          capitalizeNext = true;
        }
      }
    }

    final capitalized = buffer.toString();
    if (capitalized == text) return newValue;

    return newValue.copyWith(
      text: capitalized,
      selection: newValue.selection,
    );
  }
}

/// Automatically capitalizes the first letter of each sentence
class CapitalizeSentencesFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final text = newValue.text;
    final buffer = StringBuffer();
    bool capitalizeNext = true;

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      if (capitalizeNext && RegExp(r'[a-zA-ZÀ-ÿ]').hasMatch(char)) {
        buffer.write(char.toUpperCase());
        capitalizeNext = false;
      } else {
        buffer.write(char);
        if (char == '.' || char == '!' || char == '?' || char == '\n') {
          capitalizeNext = true;
        }
      }
    }

    final capitalized = buffer.toString();
    if (capitalized == text) return newValue;

    return newValue.copyWith(
      text: capitalized,
      selection: newValue.selection,
    );
  }
}

/// Automatically converts text to uppercase (e.g. Flight numbers)
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final upper = newValue.text.toUpperCase();
    if (upper == newValue.text) return newValue;

    return newValue.copyWith(
      text: upper,
      selection: newValue.selection,
    );
  }
}

