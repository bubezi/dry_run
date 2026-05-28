import 'package:dry_run/services/notification_service.dart';
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

  DateTime? lastCheckIn;

  Future<void> _load() async {
    final raw = await StorageService.loadCheckIns();

    final loaded = raw.map((key, value) {
      return MapEntry(key, CheckIn.fromJson(Map<String, dynamic>.from(value)));
    });
    lastCheckIn = await StorageService.getLastCheckIn();

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

    _postCheckInBehavior(status);
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

  Future<void> checkMissedDay() async {
    if (lastCheckIn == null) return;

    final now = DateTime.now();
    final diff = now.difference(lastCheckIn!).inDays;

    if (diff >= 2) {
      await NotificationService().showMissedDayReminder();
    }
  }

  Future<void> markCheckIn(bool sober) async {
    final now = DateTime.now();

    await StorageService.saveLastCheckIn(now);
    lastCheckIn = now;
  }

  String get behaviorMode {
    final streak = computeStreak();
    final missed = needsYesterdayCheckIn();

    if (missed) return "recovery";
    if (streak >= 7) return "stable";
    if (streak >= 3) return "building";

    return "fragile";
  }

  String get dynamicMessage {
    switch (behaviorMode) {
      case "recovery":
        return "You missed a check-in. No drama — just continue today.";
      case "stable":
        return "You’re in control. Keep it steady.";
      case "building":
        return "Momentum is forming. Don’t interrupt it.";
      case "fragile":
      default:
        return "One decision at a time.";
    }
  }

  int get notificationLevel {
    switch (behaviorMode) {
      case "recovery":
        return 3; // high frequency / urgency
      case "fragile":
        return 2; // normal reminders
      case "building":
        return 1; // gentle
      case "stable":
        return 0; // minimal
      default:
        return 1;
    }
  }

  void _postCheckInBehavior(DayStatus status) {
    if (status == DayStatus.drank) {
      // relapse event
      _triggerRecoveryMode();
    } else {
      // positive reinforcement path
      _triggerStabilityFeedback();
    }
  }

  void _triggerRecoveryMode() {
    // This is where UI + notifications shift tone

    NotificationService().showMissedDayReminder();

    // future hook: could reset streak weighting or soften UI
  }

  void _triggerStabilityFeedback() {
    final streak = computeStreak();

    if (streak == 3 || streak == 7 || streak == 14) {
      // milestone reinforcement (optional notification hook)
      NotificationService().showMissedDayReminder();
      // (you can replace later with “milestone” notification)
    }
  }
}
