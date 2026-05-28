import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sobriety_data.dart';

final sobrietyProvider =
    StateNotifierProvider<SobrietyNotifier, SobrietyData>(
  (ref) => SobrietyNotifier(),
);

class SobrietyNotifier extends StateNotifier<SobrietyData> {
  SobrietyNotifier()
      : super(
          SobrietyData(
            currentStreak: 0,
            longestStreak: 0,
            totalSoberDays: 0,
            lastCheckIn: null,
            soberToday: false,
          ),
        );

  void checkInSober() {
    final newStreak = state.currentStreak + 1;

    state = state.copyWith(
      currentStreak: newStreak,
      longestStreak:
          newStreak > state.longestStreak
              ? newStreak
              : state.longestStreak,
      totalSoberDays: state.totalSoberDays + 1,
      lastCheckIn: DateTime.now(),
      soberToday: true,
    );
  }

  void checkInDrank() {
    state = state.copyWith(
      currentStreak: 0,
      lastCheckIn: DateTime.now(),
      soberToday: false,
    );
  }
}