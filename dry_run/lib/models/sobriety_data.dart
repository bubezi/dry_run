class SobrietyData {
  final int currentStreak;
  final int longestStreak;
  final int totalSoberDays;
  final DateTime? lastCheckIn;
  final bool soberToday;

  SobrietyData({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalSoberDays,
    required this.lastCheckIn,
    required this.soberToday,
  });

  SobrietyData copyWith({
    int? currentStreak,
    int? longestStreak,
    int? totalSoberDays,
    DateTime? lastCheckIn,
    bool? soberToday,
  }) {
    return SobrietyData(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalSoberDays: totalSoberDays ?? this.totalSoberDays,
      lastCheckIn: lastCheckIn ?? this.lastCheckIn,
      soberToday: soberToday ?? this.soberToday,
    );
  }
}