import 'package:dry_run/registry/notification_registry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_service.dart';
import '../models/day_status.dart';
import '../providers/sobriety_provider.dart';

// ─── Provider ─────────────────────────────────────────────────────────────────

final schedulerProvider = Provider<SchedulerService>((ref) {
  return SchedulerService(ref);
});

// ─── Service ──────────────────────────────────────────────────────────────────

/// The single source of truth for all notification scheduling.
/// All scheduling goes through here — never call NotificationService directly
/// from UI code or providers except via this class.
class SchedulerService {
  final Ref _ref;
  final NotificationService _notifications = NotificationService();

  SchedulerService(this._ref);

  // ─── Full rebuild (call on app start and after any state change) ───────────

  /// Cancels all previously scheduled notifications and rebuilds from scratch.
  /// Idempotent — safe to call multiple times.
  Future<void> rebuildAll() async {
    await _notifications.cancelAll();
    await _notifications.scheduleEveningCheckIn();
    await _notifications.scheduleDailyMotivation();
  }

  // ─── Day boundary handling ─────────────────────────────────────────────────

  /// Call this on app resume / foreground. Detects if a new day has arrived
  /// since last launch and triggers the appropriate prompts.
  Future<void> handleAppForeground() async {
    final prefs = await SharedPreferences.getInstance();
    final lastLaunchStr = prefs.getString('_last_launch_date');
    final today = _dateKey(DateTime.now());

    if (lastLaunchStr != null && lastLaunchStr != today) {
      // A new day has arrived since last open
      await _onNewDayDetected(prefs);
    }

    await prefs.setString('_last_launch_date', today);
  }

  Future<void> _onNewDayDetected(SharedPreferences prefs) async {
    final notifier = _ref.read(sobrietyProvider.notifier);

    // If yesterday has no check-in, fire the new-day prompt notification
    if (notifier.needsYesterdayCheckIn()) {
      await _notifications.showNewDayCheckInPrompt();
    }

    // Rebuild scheduled notifications for the new day
    await rebuildAll();

    // Check milestones
    final streak = notifier.computeStreak();
    if (NotificationRegistry.milestones.contains(streak)) {
      await _notifications.showMilestoneCelebration(streak);
    }
  }

  // ─── Post check-in hook ───────────────────────────────────────────────────

  /// Call after every check-in. Adjusts notification frequency by behavior mode.
  Future<void> onCheckIn(DayStatus status, String behaviorMode) async {
    // Always rebuild to reset the daily schedule
    await rebuildAll();

    if (status == DayStatus.drank) {
      // Recovery mode: fire an immediate supportive notification
      await _notifications.showMissedCheckInReminder();
    }

    // Adjust motivation message tone based on mode
    String? message;
    switch (behaviorMode) {
      case 'recovery':
        message = "A slip doesn't erase progress. One day at a time.";
        break;
      case 'fragile':
        message = 'Every sober hour counts. Keep going.';
        break;
      case 'building':
        message = 'Momentum is forming. Protect it.';
        break;
      case 'stable':
        message = 'You are in control. Stay steady.';
        break;
    }

    if (message != null) {
      await _notifications.scheduleDailyMotivation(message: message);
    }
  }

  // ─── Notification action handler (from notification panel buttons) ─────────

  /// Handle "Sober" / "Drank" taps from notification actions.
  /// Must be called from the main isolate where Riverpod is available.
  Future<void> handleNotificationAction(String? actionId) async {
    if (actionId == null) return;

    DayStatus? status;
    if (actionId == NotificationRegistry.actionSober) {
      status = DayStatus.sober;
    } else if (actionId == NotificationRegistry.actionDrank) {
      status = DayStatus.drank;
    }

    if (status == null) return;

    final notifier = _ref.read(sobrietyProvider.notifier);
    final yesterday = _yesterday();

    // Log for yesterday if not yet logged, otherwise log today
    final target = notifier.hasCheckedIn(yesterday) ? DateTime.now() : yesterday;
    await notifier.checkIn(target, status);
    await onCheckIn(status, notifier.behaviorMode);
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  DateTime _yesterday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - 1);
  }
}
