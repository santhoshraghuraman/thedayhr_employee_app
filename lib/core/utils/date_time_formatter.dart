import 'package:intl/intl.dart';

/// Shared date, time, and duration formatters powered by `intl`.
abstract final class DateTimeFormatter {
  static final DateFormat _dateFormat = DateFormat('EEE, dd MMM yyyy');
  static final DateFormat _shortDateFormat = DateFormat('dd MMM');
  static final DateFormat _timeFormat = DateFormat('hh:mm a');
  static final DateFormat _clockFormat = DateFormat('hh:mm:ss a');
  static final DateFormat _dateKeyFormat = DateFormat('yyyy-MM-dd');

  /// Formats a date such as `Thu, 26 Nov 2026`.
  static String formatDate(DateTime dateTime) => _dateFormat.format(dateTime);

  /// Formats a human-friendly day label (`Today`, `Yesterday`, or full date)
  /// for chat conversation date separators.
  static String formatChatDaySeparator(
    DateTime dateTime,
    DateTime referenceNow,
  ) {
    final targetKey = toDateKey(dateTime);
    final todayKey = toDateKey(referenceNow);
    if (targetKey == todayKey) {
      return 'Today';
    }
    final yesterday = referenceNow.subtract(const Duration(days: 1));
    if (targetKey == toDateKey(yesterday)) {
      return 'Yesterday';
    }
    return formatDate(dateTime);
  }

  /// Formats a compact timestamp for chat contact list previews.
  static String formatContactTimestamp(
    DateTime dateTime,
    DateTime referenceNow,
  ) {
    final targetKey = toDateKey(dateTime);
    if (targetKey == toDateKey(referenceNow)) {
      return formatTime(dateTime);
    }
    final yesterday = referenceNow.subtract(const Duration(days: 1));
    if (targetKey == toDateKey(yesterday)) {
      return 'Yesterday';
    }
    return _shortDateFormat.format(dateTime);
  }

  /// Formats a short time such as `09:30 AM`.
  static String formatTime(DateTime dateTime) => _timeFormat.format(dateTime);

  /// Formats a live clock with seconds such as `09:30:45 AM`.
  static String formatLiveClock(DateTime dateTime) =>
      _clockFormat.format(dateTime);

  /// Stable calendar day key such as `2026-11-26`.
  static String toDateKey(DateTime dateTime) => _dateKeyFormat.format(dateTime);

  /// Formats a duration as `08h 15m`.
  static String formatHoursMinutes(Duration duration) {
    final safeDuration = duration.isNegative ? Duration.zero : duration;
    final hours = safeDuration.inHours.toString().padLeft(2, '0');
    final minutes = (safeDuration.inMinutes % 60).toString().padLeft(2, '0');
    return '${hours}h ${minutes}m';
  }

  /// Formats a live elapsed duration as `HH:MM:SS`.
  static String formatElapsedClock(Duration duration) {
    final safeDuration = duration.isNegative ? Duration.zero : duration;
    final hours = safeDuration.inHours.toString().padLeft(2, '0');
    final minutes = (safeDuration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (safeDuration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}

