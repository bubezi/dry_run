class AppDateUtils {
  static String key(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.toIso8601String().split('T').first;
  }

  static DateTime normalize(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime yesterday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - 1);
  }
}