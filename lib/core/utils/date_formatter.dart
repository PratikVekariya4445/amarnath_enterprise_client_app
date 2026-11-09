/// Utility for formatting timestamps and ISO 8601 strings into user-friendly date strings.
class DateFormatter {
  DateFormatter._();

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// Formats an ISO 8601 date string or epoch millis string into `08 Nov 2026, 02:15 PM`.
  static String formatOrderDateTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return '';
    }

    DateTime? dateTime;

    // Check if it's an epoch millisecond integer
    final millis = int.tryParse(raw.trim());
    if (millis != null && millis > 100000000000) {
      dateTime = DateTime.fromMillisecondsSinceEpoch(millis);
    } else {
      dateTime = DateTime.tryParse(raw.trim());
    }

    if (dateTime == null) {
      return raw;
    }

    final local = dateTime.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = (local.month >= 1 && local.month <= 12)
        ? _months[local.month - 1]
        : 'Nov';
    final year = local.year.toString();

    int hour = local.hour;
    final period = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    final hourStr = hour.toString().padLeft(2, '0');
    final minuteStr = local.minute.toString().padLeft(2, '0');

    return '$day $month $year, $hourStr:$minuteStr $period';
  }
}
