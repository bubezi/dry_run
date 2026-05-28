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
    final sorted = state.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    int streak = 0;

    for (final entry in sorted) {
      if (entry.status == DayStatus.sober) {
        streak++;
      } else {
        break;
      }
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
}
