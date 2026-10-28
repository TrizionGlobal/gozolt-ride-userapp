import 'package:intl/intl.dart';

/// Reusable Date & Time utility matching Quick Services standards across the GoZolt app.
/// Preserves wall-clock appointment times without timezone distortion.
class AppDateUtils {
  AppDateUtils._();

  /// Parses a date string or DateTime, removing any trailing 'Z'
  /// so that wall-clock scheduled appointments are never shifted by UTC offsets.
  static DateTime? parseCleanDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final str = value.toString().trim();
    if (str.isEmpty || str == 'null' || str == 'N/A') return null;
    return DateTime.tryParse(str.replaceAll('Z', ''));
  }

  /// Format as `26 Oct 2026` ('dd MMM yyyy') - matches Quick Services
  static String formatDate(dynamic value, {String fallback = 'N/A'}) {
    final dt = parseCleanDate(value);
    if (dt == null) return fallback;
    return DateFormat('dd MMM yyyy').format(dt);
  }

  /// Format as `11:45 AM` ('h:mm a') - matches Quick Services
  static String formatTime(dynamic value, {String fallback = 'N/A'}) {
    final dt = parseCleanDate(value);
    if (dt == null) return fallback;
    return DateFormat('h:mm a').format(dt);
  }

  /// Takes a raw storage string like '11:45' or '11:45:00' and formats as '11:45 AM'
  static String formatTimeString(String? timeStr, {String fallback = 'N/A'}) {
    if (timeStr == null || timeStr.trim().isEmpty) return fallback;
    final clean = timeStr.trim();
    if (!clean.contains(':')) return clean;
    final parts = clean.split(':');
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return clean;
    final dt = DateTime(2000, 1, 1, h, m);
    return DateFormat('h:mm a').format(dt);
  }

  /// Format as `26 Oct 2026, 11:45 AM` ('dd MMM yyyy, h:mm a') - matches Quick Services
  static String formatDateTime(dynamic value, {String fallback = 'N/A'}) {
    final dt = parseCleanDate(value);
    if (dt == null) return fallback;
    return DateFormat('dd MMM yyyy, h:mm a').format(dt);
  }

  /// Constructs a DateTime in UTC holding the exact wall-clock year/month/day/hour/minute
  /// selected by the user. When serialized with toIso8601String(), it outputs
  /// `2026-10-26T11:45:00.000Z`, preserving the exact appointment across all clients.
  static DateTime createWallClockUtc(DateTime date, String? timeString) {
    int hour = 12;
    int minute = 0;
    if (timeString != null && timeString.contains(':')) {
      final parts = timeString.split(':');
      hour = int.tryParse(parts[0]) ?? 12;
      minute = int.tryParse(parts[1]) ?? 0;
    }
    return DateTime.utc(date.year, date.month, date.day, hour, minute);
  }
}
