extension StringCasingExtension on String {
  /// Converts string to Title Case (e.g. 'chicken Biryani' -> 'Chicken Biryani',
  /// 'extra piece' -> 'Extra Piece', 'PRICE SUMMARY' -> 'Price Summary').
  String toTitleCase() {
    if (trim().isEmpty) return this;
    return split(' ').map((word) {
      if (word.isEmpty) return word;
      final isAllUpper = word.length > 1 && word == word.toUpperCase();
      final rest = isAllUpper ? word.substring(1).toLowerCase() : word.substring(1);
      return word[0].toUpperCase() + rest;
    }).join(' ');
  }

  /// Capitalizes the first letter of the string.
  String toCapitalized() {
    if (trim().isEmpty) return this;
    final trimmed = trim();
    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }
}
