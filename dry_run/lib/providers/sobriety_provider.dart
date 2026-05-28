import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/check_in.dart';
import '../models/day_status.dart';
import '../services/storage_service.dart';
import '../utils/date_utils.dart';

final sobrietyProvider =
    StateNotifierProvider<SobrietyNotifier, Map<String, CheckIn>>(
      (ref) => SobrietyNotifier(),
    );

class SobrietyNotifier extends StateNotifier<Map<String, CheckIn>> {
  SobrietyNotifier() : super({}) {
    _load();
  }

  Future<void> _load() async {
    final raw = await StorageService.loadCheckIns();

    final loaded = raw.map((key, value) {
      return MapEntry(key, CheckIn.fromJson(Map<String, dynamic>.from(value)));
    });

    state = loaded;
  }

  Future<void> _persist() async {
    final json = state.map((key, value) {
      return MapEntry(key, value.toJson());
    });

    await StorageService.saveCheckIns(json);
  }

  bool hasCheckedIn(DateTime date) {
    return state.containsKey(AppDateUtils.key(date));
  }

  CheckIn? getCheckIn(DateTime date) {
    return state[AppDateUtils.key(date)];
  }

  Future<void> checkIn(DateTime date, DayStatus status) async {
    final key = AppDateUtils.key(date);

    state = {
      ...state,
      key: CheckIn(date: AppDateUtils.normalize(date), status: status),
    };

    await _persist();
  }

  int computeStreak() {
    int streak = 0;

    DateTime cursor = DateTime.now();

    while (true) {
      final key = AppDateUtils.key(cursor);
      final entry = state[key];

      if (entry == null) break;

      if (entry.status == DayStatus.sober) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
        continue;
      }

      // drank OR unknown breaks streak
      break;
    }

    return streak;
  }

  bool needsYesterdayCheckIn() {
    final y = AppDateUtils.yesterday();
    return !hasCheckedIn(y);
  }

  List<CheckIn> getSortedHistory() {
    final list = state.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return list;
  }

  Map<String, CheckIn> seedHistory(DateTime startDate) {
    final Map<String, CheckIn> seeded = {};

    final today = DateTime.now();
    DateTime cursor = DateTime(startDate.year, startDate.month, startDate.day);

    while (!cursor.isAfter(today)) {
      final key = AppDateUtils.key(cursor);

      seeded[key] = CheckIn(date: cursor, status: DayStatus.sober);

      cursor = cursor.add(const Duration(days: 1));
    }

    return seeded;
  }

  void initializeFromOnboarding(DateTime startDate) {
    state = seedHistory(startDate);
    _persist();
  }
}
