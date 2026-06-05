import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/date_utils.dart';

// ─── Current date provider ────────────────────────────────────────────────────
// Rebuilds any widget that watches it whenever the calendar date changes.
// Safe to watch from multiple widgets — only one timer runs.

final currentDateProvider = StateProvider<DateTime>((ref) {
  return AppDateUtils.normalize(DateTime.now());
});

// ─── Day watcher ──────────────────────────────────────────────────────────────
// Runs a 60-second timer while the app is alive.
// Updates currentDateProvider when the date rolls over.
// Also exposes shouldPromptTodayCheckIn so the home screen can react to 8pm.

final dayWatcherProvider = Provider<DayWatcher>((ref) {
  final watcher = DayWatcher(ref);
  watcher.start();
  ref.onDispose(watcher.stop);
  return watcher;
});

class DayWatcher {
  final Ref _ref;
  Timer? _timer;

  DayWatcher(this._ref);

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _tick());
  }

  void stop() {
    _timer?.cancel();
  }

  void _tick() {
    final now = DateTime.now();
    final today = AppDateUtils.normalize(now);
    final current = _ref.read(currentDateProvider);

    // Date rolled over — update the provider so all watchers rebuild
    if (today != current) {
      _ref.read(currentDateProvider.notifier).state = today;
    }
  }

  /// True if it's 8pm or later and the user hasn't logged today yet.
  /// Call this from the home screen to decide whether to show the prompt.
  bool get isPastEveningThreshold => DateTime.now().hour >= 20;
}
