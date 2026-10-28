class CountryCode {
  final String name;
  final String code;
  final String dialCode;
  final String flag;
  final int maxLength;
  final int minLength;

  const CountryCode({
    required this.name,
    required this.code,
    required this.dialCode,
    required this.flag,
    this.maxLength = 10,
    this.minLength = 7,
  });

  /// Automatically parses a full international phone number (e.g. "+919542281864" or "+35679123456")
  /// into the matched [CountryCode] and the raw national phone number.
  static ({CountryCode country, String nationalNumber}) parsePhoneNumber(String? rawPhone) {
    if (rawPhone == null || rawPhone.trim().isEmpty) {
      return (country: defaultCountry, nationalNumber: '');
    }

    final trimmed = rawPhone.trim();
    final clean = trimmed.startsWith('+') ? trimmed : '+$trimmed';

    // Sort by longest dial code first to match +356 before +35 etc.
    final sorted = List<CountryCode>.from(supportedCountryCodes)
      ..sort((a, b) => b.dialCode.length.compareTo(a.dialCode.length));

    for (final c in sorted) {
      if (clean.startsWith(c.dialCode)) {
        final number = clean.substring(c.dialCode.length).replaceAll(RegExp(r'\D'), '');
        return (country: c, nationalNumber: number);
      }
    }

    // Fallback: extract digits
    final digitsOnly = clean.replaceAll(RegExp(r'\D'), '');
    return (country: defaultCountry, nationalNumber: digitsOnly);
  }

  static CountryCode get defaultCountry => supportedCountryCodes.first; // Malta (+356)
}

const List<CountryCode> supportedCountryCodes = [
  CountryCode(name: 'Malta', code: 'MT', dialCode: '+356', flag: '\u{1F1F2}\u{1F1F9}', maxLength: 8, minLength: 8),
  CountryCode(name: 'Italy', code: 'IT', dialCode: '+39', flag: '\u{1F1EE}\u{1F1F9}', maxLength: 10, minLength: 9),
  CountryCode(name: 'Germany', code: 'DE', dialCode: '+49', flag: '\u{1F1E9}\u{1F1EA}', maxLength: 11, minLength: 10),
  CountryCode(name: 'France', code: 'FR', dialCode: '+33', flag: '\u{1F1EB}\u{1F1F7}', maxLength: 9, minLength: 9),
  CountryCode(name: 'Spain', code: 'ES', dialCode: '+34', flag: '\u{1F1EA}\u{1F1F8}', maxLength: 9, minLength: 9),
  CountryCode(name: 'Portugal', code: 'PT', dialCode: '+351', flag: '\u{1F1F5}\u{1F1F9}', maxLength: 9, minLength: 9),
  CountryCode(name: 'Netherlands', code: 'NL', dialCode: '+31', flag: '\u{1F1F3}\u{1F1F1}', maxLength: 9, minLength: 9),
  CountryCode(name: 'Belgium', code: 'BE', dialCode: '+32', flag: '\u{1F1E7}\u{1F1EA}', maxLength: 9, minLength: 9),
  CountryCode(name: 'Austria', code: 'AT', dialCode: '+43', flag: '\u{1F1E6}\u{1F1F9}', maxLength: 11, minLength: 9),
  CountryCode(name: 'Greece', code: 'GR', dialCode: '+30', flag: '\u{1F1EC}\u{1F1F7}', maxLength: 10, minLength: 10),
  CountryCode(name: 'Ireland', code: 'IE', dialCode: '+353', flag: '\u{1F1EE}\u{1F1EA}', maxLength: 9, minLength: 9),
  CountryCode(name: 'Sweden', code: 'SE', dialCode: '+46', flag: '\u{1F1F8}\u{1F1EA}', maxLength: 9, minLength: 9),
  CountryCode(name: 'Finland', code: 'FI', dialCode: '+358', flag: '\u{1F1EB}\u{1F1EE}', maxLength: 10, minLength: 9),
  CountryCode(name: 'Denmark', code: 'DK', dialCode: '+45', flag: '\u{1F1E9}\u{1F1F0}', maxLength: 8, minLength: 8),
  CountryCode(name: 'Poland', code: 'PL', dialCode: '+48', flag: '\u{1F1F5}\u{1F1F1}', maxLength: 9, minLength: 9),
  CountryCode(name: 'Czech Republic', code: 'CZ', dialCode: '+420', flag: '\u{1F1E8}\u{1F1FF}', maxLength: 9, minLength: 9),
  CountryCode(name: 'Romania', code: 'RO', dialCode: '+40', flag: '\u{1F1F7}\u{1F1F4}', maxLength: 10, minLength: 9),
  CountryCode(name: 'Hungary', code: 'HU', dialCode: '+36', flag: '\u{1F1ED}\u{1F1FA}', maxLength: 9, minLength: 9),
  CountryCode(name: 'Croatia', code: 'HR', dialCode: '+385', flag: '\u{1F1ED}\u{1F1F7}', maxLength: 9, minLength: 8),
  CountryCode(name: 'Cyprus', code: 'CY', dialCode: '+357', flag: '\u{1F1E8}\u{1F1FE}', maxLength: 8, minLength: 8),
  CountryCode(name: 'United Kingdom', code: 'GB', dialCode: '+44', flag: '\u{1F1EC}\u{1F1E7}', maxLength: 10, minLength: 10),

  // ── Asia ──────────────────────────────────────
  CountryCode(name: 'India', code: 'IN', dialCode: '+91', flag: '\u{1F1EE}\u{1F1F3}', maxLength: 10, minLength: 10),
  CountryCode(name: 'Pakistan', code: 'PK', dialCode: '+92', flag: '\u{1F1F5}\u{1F1F0}', maxLength: 10, minLength: 10),
  CountryCode(name: 'Bangladesh', code: 'BD', dialCode: '+880', flag: '\u{1F1E7}\u{1F1E9}', maxLength: 10, minLength: 10),
  CountryCode(name: 'Sri Lanka', code: 'LK', dialCode: '+94', flag: '\u{1F1F1}\u{1F1F0}', maxLength: 9, minLength: 9),
  CountryCode(name: 'Nepal', code: 'NP', dialCode: '+977', flag: '\u{1F1F3}\u{1F1F5}', maxLength: 10, minLength: 10),
  CountryCode(name: 'Philippines', code: 'PH', dialCode: '+63', flag: '\u{1F1F5}\u{1F1ED}', maxLength: 10, minLength: 10),
  CountryCode(name: 'Indonesia', code: 'ID', dialCode: '+62', flag: '\u{1F1EE}\u{1F1E9}', maxLength: 12, minLength: 9),
  CountryCode(name: 'Malaysia', code: 'MY', dialCode: '+60', flag: '\u{1F1F2}\u{1F1FE}', maxLength: 10, minLength: 9),
  CountryCode(name: 'Thailand', code: 'TH', dialCode: '+66', flag: '\u{1F1F9}\u{1F1ED}', maxLength: 9, minLength: 9),
  CountryCode(name: 'Vietnam', code: 'VN', dialCode: '+84', flag: '\u{1F1FB}\u{1F1F3}', maxLength: 10, minLength: 9),
  CountryCode(name: 'China', code: 'CN', dialCode: '+86', flag: '\u{1F1E8}\u{1F1F3}', maxLength: 11, minLength: 11),
  CountryCode(name: 'Japan', code: 'JP', dialCode: '+81', flag: '\u{1F1EF}\u{1F1F5}', maxLength: 10, minLength: 10),
  CountryCode(name: 'South Korea', code: 'KR', dialCode: '+82', flag: '\u{1F1F0}\u{1F1F7}', maxLength: 10, minLength: 9),
  CountryCode(name: 'Singapore', code: 'SG', dialCode: '+65', flag: '\u{1F1F8}\u{1F1EC}', maxLength: 8, minLength: 8),
  CountryCode(name: 'UAE', code: 'AE', dialCode: '+971', flag: '\u{1F1E6}\u{1F1EA}', maxLength: 9, minLength: 9),
  CountryCode(name: 'Saudi Arabia', code: 'SA', dialCode: '+966', flag: '\u{1F1F8}\u{1F1E6}', maxLength: 9, minLength: 9),
  CountryCode(name: 'Turkey', code: 'TR', dialCode: '+90', flag: '\u{1F1F9}\u{1F1F7}', maxLength: 10, minLength: 10),

  // ── South America ──────────────────────────────
  CountryCode(name: 'Brazil', code: 'BR', dialCode: '+55', flag: '\u{1F1E7}\u{1F1F7}', maxLength: 11, minLength: 10),
  CountryCode(name: 'Argentina', code: 'AR', dialCode: '+54', flag: '\u{1F1E6}\u{1F1F7}', maxLength: 11, minLength: 10),
  CountryCode(name: 'Colombia', code: 'CO', dialCode: '+57', flag: '\u{1F1E8}\u{1F1F4}', maxLength: 10, minLength: 10),
  CountryCode(name: 'Chile', code: 'CL', dialCode: '+56', flag: '\u{1F1E8}\u{1F1F1}', maxLength: 9, minLength: 9),
  CountryCode(name: 'Peru', code: 'PE', dialCode: '+51', flag: '\u{1F1F5}\u{1F1EA}', maxLength: 9, minLength: 9),
  CountryCode(name: 'Mexico', code: 'MX', dialCode: '+52', flag: '\u{1F1F2}\u{1F1FD}', maxLength: 10, minLength: 10),

  // ── Africa ──────────────────────────────────────
  CountryCode(name: 'Nigeria', code: 'NG', dialCode: '+234', flag: '\u{1F1F3}\u{1F1EC}', maxLength: 10, minLength: 10),
  CountryCode(name: 'South Africa', code: 'ZA', dialCode: '+27', flag: '\u{1F1FF}\u{1F1E6}', maxLength: 9, minLength: 9),
  CountryCode(name: 'Egypt', code: 'EG', dialCode: '+20', flag: '\u{1F1EA}\u{1F1EC}', maxLength: 10, minLength: 10),
  CountryCode(name: 'Kenya', code: 'KE', dialCode: '+254', flag: '\u{1F1F0}\u{1F1EA}', maxLength: 9, minLength: 9),

  // ── North America ───────────────────────────────
  CountryCode(name: 'United States', code: 'US', dialCode: '+1', flag: '\u{1F1FA}\u{1F1F8}', maxLength: 10, minLength: 10),
  CountryCode(name: 'Canada', code: 'CA', dialCode: '+1', flag: '\u{1F1E8}\u{1F1E6}', maxLength: 10, minLength: 10),

  // ── Oceania ─────────────────────────────────────
  CountryCode(name: 'Australia', code: 'AU', dialCode: '+61', flag: '\u{1F1E6}\u{1F1FA}', maxLength: 9, minLength: 9),
  CountryCode(name: 'New Zealand', code: 'NZ', dialCode: '+64', flag: '\u{1F1F3}\u{1F1FF}', maxLength: 10, minLength: 8),
];
