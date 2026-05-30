import 'package:dry_run/services/notification_service.dart';
import 'package:dry_run/registry/notification_registry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/check_in.dart';
import '../models/day_status.dart';
import '../services/storage_service.dart';
import '../utils/date_utils.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

final sobrietyProvider =
    StateNotifierProvider<SobrietyNotifier, Map<String, CheckIn>>(
      (ref) => SobrietyNotifier(),
    );

// ─── Streak Stats Model ───────────────────────────────────────────────────────

class StreakStats {
  final int currentStreak;
  final int longestStreak;
  final int totalSoberDays;
  final int totalTrackedDays;

  const StreakStats({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalSoberDays,
    required this.totalTrackedDays,
  });

  /// Recovery percentage — how many of all tracked days were sober.
  double get recoveryPercentage =>
      totalTrackedDays == 0 ? 0 : (totalSoberDays / totalTrackedDays) * 100;

  String get recoveryLabel =>
      '${totalSoberDays} sober days out of $totalTrackedDays';

  String get percentageLabel =>
      '${recoveryPercentage.toStringAsFixed(1)}% consistency';
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class SobrietyNotifier extends StateNotifier<Map<String, CheckIn>> {
  SobrietyNotifier() : super({}) {
    _load();
  }

  DateTime? lastCheckIn;

  // ─── Load / Persist ────────────────────────────────────────────────────────

  Future<void> _load() async {
    final raw = await StorageService.loadCheckIns();
    final loaded = raw.map(
      (key, value) =>
          MapEntry(key, CheckIn.fromJson(Map<String, dynamic>.from(value))),
    );
    lastCheckIn = await StorageService.getLastCheckIn();
    state = loaded;
  }

  Future<void> _persist() async {
    final json = state.map((key, value) => MapEntry(key, value.toJson()));
    await StorageService.saveCheckIns(json);
  }

  // ─── Query ────────────────────────────────────────────────────────────────

  bool hasCheckedIn(DateTime date) =>
      state.containsKey(AppDateUtils.key(date));

  CheckIn? getCheckIn(DateTime date) => state[AppDateUtils.key(date)];

  bool needsYesterdayCheckIn() => !hasCheckedIn(AppDateUtils.yesterday());

  List<CheckIn> getSortedHistory() {
    return state.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  // ─── Streak Computation ───────────────────────────────────────────────────

  int computeStreak() {
    int streak = 0;
    DateTime cursor = DateTime.now();

    while (true) {
      final entry = state[AppDateUtils.key(cursor)];
      if (entry == null) break;
      if (entry.status == DayStatus.sober) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else {
        break; // drank or unknown breaks streak
      }
    }

    return streak;
  }

  /// Full stats object — current, longest, total sober, recovery %.
  StreakStats computeStats() {
    int currentStreak = 0;
    int longestStreak = 0;
    int totalSoberDays = 0;
    int runningStreak = 0;

    if (state.isEmpty) {
      return const StreakStats(
        currentStreak: 0,
        longestStreak: 0,
        totalSoberDays: 0,
        totalTrackedDays: 0,
      );
    }

    // Sort all check-ins chronologically
    final sorted = state.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    for (final checkIn in sorted) {
      if (checkIn.status == DayStatus.sober) {
        totalSoberDays++;
        runningStreak++;
        if (runningStreak > longestStreak) {
          longestStreak = runningStreak;
        }
      } else {
        runningStreak = 0;
      }
    }

    currentStreak = computeStreak();

    return StreakStats(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      totalSoberDays: totalSoberDays,
      totalTrackedDays: state.length,
    );
  }

  // ─── Check-in ─────────────────────────────────────────────────────────────

  Future<void> checkIn(DateTime date, DayStatus status) async {
    final key = AppDateUtils.key(date);

    state = {
      ...state,
      key: CheckIn(date: AppDateUtils.normalize(date), status: status),
    };

    await _persist();
    await _postCheckInBehavior(status);
  }

  Future<void> markCheckIn(bool sober) async {
    final now = DateTime.now();
    await StorageService.saveLastCheckIn(now);
    lastCheckIn = now;
  }

  // ─── Onboarding ───────────────────────────────────────────────────────────

  Map<String, CheckIn> seedHistory(DateTime startDate) {
    final Map<String, CheckIn> seeded = {};
    final today = DateTime.now();
    DateTime cursor = DateTime(startDate.year, startDate.month, startDate.day);

    while (!cursor.isAfter(today)) {
      seeded[AppDateUtils.key(cursor)] = CheckIn(
        date: cursor,
        status: DayStatus.sober,
      );
      cursor = cursor.add(const Duration(days: 1));
    }

    return seeded;
  }

  void initializeFromOnboarding(DateTime startDate) {
    state = seedHistory(startDate);
    _persist();
  }

  // ─── Behavior Mode ────────────────────────────────────────────────────────

  String get behaviorMode {
    final streak = computeStreak();
    final missed = needsYesterdayCheckIn();

    if (missed) return 'recovery';
    if (streak >= 7) return 'stable';
    if (streak >= 3) return 'building';
    return 'fragile';
  }

  String get dynamicMessage {
    switch (behaviorMode) {
      case 'recovery':
        return "You missed a check-in. No drama — just continue today.";
      case 'stable':
        return "You're in control. Keep it steady.";
      case 'building':
        return "Momentum is forming. Don't interrupt it.";
      case 'fragile':
      default:
        return "One decision at a time.";
    }
  }

  int get notificationLevel {
    switch (behaviorMode) {
      case 'recovery':
        return 3;
      case 'fragile':
        return 2;
      case 'building':
        return 1;
      case 'stable':
        return 0;
      default:
        return 1;
    }
  }

  // ─── Post-check-in side-effects ───────────────────────────────────────────

  Future<void> _postCheckInBehavior(DayStatus status) async {
    if (status == DayStatus.drank) {
      await NotificationService().showMissedCheckInReminder();
      return;
    }

    // Milestone celebrations
    final streak = computeStreak();
    if (NotificationRegistry.milestones.contains(streak)) {
      await NotificationService().showMilestoneCelebration(streak);
    }
  }
}
