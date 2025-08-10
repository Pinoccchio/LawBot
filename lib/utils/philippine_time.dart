import 'package:intl/intl.dart';

class PhilippineTime {
  // Philippine timezone offset is UTC+8
  static const int philippineOffsetHours = 8;

  /// Get current Philippine time
  static DateTime now() {
    final utcNow = DateTime.now().toUtc();
    return utcNow.add(const Duration(hours: philippineOffsetHours));
  }

  /// Convert UTC DateTime to Philippine time
  static DateTime fromUtc(DateTime utcDateTime) {
    return utcDateTime.add(const Duration(hours: philippineOffsetHours));
  }

  /// Convert Philippine time to UTC for database storage
  static DateTime toUtc(DateTime philippineDateTime) {
    return philippineDateTime.subtract(const Duration(hours: philippineOffsetHours));
  }

  /// Format Philippine time for display (e.g., "6:05 PM")
  static String formatTime(DateTime philippineDateTime) {
    return DateFormat('h:mm a').format(philippineDateTime);
  }

  /// Format Philippine date and time for display (e.g., "June 4, 2025 6:05 PM")
  static String formatDateTime(DateTime philippineDateTime) {
    return DateFormat('MMMM d, yyyy h:mm a').format(philippineDateTime);
  }

  /// Format Philippine date for display (e.g., "June 4, 2025")
  static String formatDate(DateTime philippineDateTime) {
    return DateFormat('MMMM d, yyyy').format(philippineDateTime);
  }

  /// Get current Philippine time as formatted string
  static String getCurrentTimeString() {
    return formatTime(now());
  }

  /// Get current Philippine date and time as formatted string
  static String getCurrentDateTimeString() {
    return formatDateTime(now());
  }

  /// Convert database timestamp (UTC string) to Philippine time display
  static String formatDatabaseTime(String? utcTimeString) {
    if (utcTimeString == null) return 'Unknown time';

    try {
      final utcDateTime = DateTime.parse(utcTimeString);
      final philippineDateTime = fromUtc(utcDateTime);
      return formatDateTime(philippineDateTime);
    } catch (e) {
      return 'Invalid time';
    }
  }

  /// Convert database timestamp to Philippine DateTime object
  static DateTime? parseDatabaseTime(String? utcTimeString) {
    if (utcTimeString == null) return null;

    try {
      final utcDateTime = DateTime.parse(utcTimeString);
      return fromUtc(utcDateTime);
    } catch (e) {
      return null;
    }
  }

  /// Get Philippine time as ISO string for metadata
  static String toPhilippineIsoString(DateTime philippineDateTime) {
    return philippineDateTime.toIso8601String();
  }

  /// Check if a date is today in Philippine time
  static bool isToday(DateTime philippineDateTime) {
    final today = now();
    return philippineDateTime.year == today.year &&
        philippineDateTime.month == today.month &&
        philippineDateTime.day == today.day;
  }

  /// Check if a date is yesterday in Philippine time
  static bool isYesterday(DateTime philippineDateTime) {
    final yesterday = now().subtract(const Duration(days: 1));
    return philippineDateTime.year == yesterday.year &&
        philippineDateTime.month == yesterday.month &&
        philippineDateTime.day == yesterday.day;
  }

  /// Get specific time string - always shows full date and time for clarity
  static String getSpecificTimeString(DateTime philippineDateTime) {
    return formatDateTime(philippineDateTime);
  }

  /// Get relative time string (e.g., "Today 6:05 PM", "Yesterday 3:30 PM", "June 3, 2025 2:15 PM")
  /// DEPRECATED: Use getSpecificTimeString() for consistent specific times
  static String getRelativeTimeString(DateTime philippineDateTime) {
    if (isToday(philippineDateTime)) {
      return 'Today ${formatTime(philippineDateTime)}';
    } else if (isYesterday(philippineDateTime)) {
      return 'Yesterday ${formatTime(philippineDateTime)}';
    } else {
      return formatDateTime(philippineDateTime);
    }
  }

  /// Format time for specific display - always shows full date and time
  static String formatSpecificTime(String? utcTimeString) {
    final philippineTime = parseDatabaseTime(utcTimeString);
    if (philippineTime == null) return 'Unknown time';

    return getSpecificTimeString(philippineTime);
  }

  /// Format time for chat history display
  /// DEPRECATED: Use formatSpecificTime() for consistent specific times
  static String formatChatHistoryTime(String? utcTimeString) {
    final philippineTime = parseDatabaseTime(utcTimeString);
    if (philippineTime == null) return 'Unknown time';

    return getRelativeTimeString(philippineTime);
  }
}