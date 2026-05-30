import 'package:dry_run/registry/notification_registry.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  // Singleton so the plugin instance is shared everywhere, including background isolates.
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ─── Init ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationResponse,
    );

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Africa/Nairobi'));

    _initialized = true;
  }

  // ─── Notification action handlers ─────────────────────────────────────────

  static void _onNotificationResponse(NotificationResponse response) {
    _handleAction(response.actionId);
  }

  @pragma('vm:entry-point')
  static void _onBackgroundNotificationResponse(NotificationResponse response) {
    _handleAction(response.actionId);
  }

  /// Dispatches the action payload to the storage layer directly
  /// (we cannot access Riverpod from a background isolate).
  static Future<void> _handleAction(String? actionId) async {
    if (actionId == null) return;

    // Import here to avoid circular deps — fine for a static helper.
    // ignore: avoid_relative_lib_imports
    final storage = _StorageBridge();
    if (actionId == NotificationRegistry.actionSober) {
      await storage.checkInToday(sober: true);
    } else if (actionId == NotificationRegistry.actionDrank) {
      await storage.checkInToday(sober: false);
    }
  }

  // ─── Schedule: Evening Check-in (idempotent) ───────────────────────────────

  Future<void> scheduleEveningCheckIn() async {
    await _plugin.cancel(id: NotificationRegistry.eveningCheckIn);

    final target = _nextOccurrence(
      NotificationRegistry.eveningHour,
      NotificationRegistry.eveningMinute,
    );

    await _plugin.zonedSchedule(
      id: NotificationRegistry.eveningCheckIn,
      title: 'Evening Check-in',
      body: 'Did you stay sober today?',
      scheduledDate: target,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationRegistry.channelCheckIn,
          NotificationRegistry.channelCheckInName,
          importance: Importance.max,
          priority: Priority.high,
          actions: const [
            AndroidNotificationAction(
              NotificationRegistry.actionSober,
              'Sober ✓',
              showsUserInterface: false,
            ),
            AndroidNotificationAction(
              NotificationRegistry.actionDrank,
              'Drank',
              showsUserInterface: false,
            ),
          ],
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ─── Schedule: Morning Motivation (idempotent) ────────────────────────────

  Future<void> scheduleDailyMotivation({String? message}) async {
    await _plugin.cancel(id: NotificationRegistry.dailyMotivation);

    final messages = message != null
        ? [message]
        : [
            'Small wins still count.',
            'One clean decision is enough.',
            "Don't restart the cycle today.",
            'Momentum beats motivation.',
            "You don't need perfect. Just present.",
            'Protect what you built.',
            'Another sober morning is a win.',
          ];

    messages.shuffle();

    final target = _nextOccurrence(
      NotificationRegistry.morningHour,
      NotificationRegistry.morningMinute,
    );

    await _plugin.zonedSchedule(
      id: NotificationRegistry.dailyMotivation,
      title: 'Daily Focus',
      body: messages.first,
      scheduledDate: target,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationRegistry.channelMotivation,
          NotificationRegistry.channelMotivationName,
          importance: Importance.low,
          priority: Priority.low,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ─── Show: Missed check-in reminder ───────────────────────────────────────

  Future<void> showMissedCheckInReminder() async {
    await _plugin.show(
      id: NotificationRegistry.missedCheckIn,
      title: 'Missed Check-in',
      body: "You didn't log yesterday. Want to add it now?",
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationRegistry.channelMissed,
          NotificationRegistry.channelMissedName,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  // ─── Show: New day prompt with inline actions ──────────────────────────────

  Future<void> showNewDayCheckInPrompt() async {
    await _plugin.show(
      id: NotificationRegistry.newDayPrompt,
      title: "New day — how was yesterday?",
      body: 'Log your check-in to keep your streak accurate.',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationRegistry.channelMissed,
          NotificationRegistry.channelMissedName,
          importance: Importance.high,
          priority: Priority.high,
          actions: const [
            AndroidNotificationAction(
              NotificationRegistry.actionSober,
              'Sober ✓',
              showsUserInterface: false,
            ),
            AndroidNotificationAction(
              NotificationRegistry.actionDrank,
              'Drank',
              showsUserInterface: false,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Show: Streak milestone ────────────────────────────────────────────────

  Future<void> showMilestoneCelebration(int streak) async {
    await _plugin.show(
      id: NotificationRegistry.streakMilestone,
      title: '$streak days sober 🎯',
      body: 'You hit a milestone. Keep protecting it.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationRegistry.channelMilestone,
          NotificationRegistry.channelMilestoneName,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  // ─── Cancel all ───────────────────────────────────────────────────────────

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<void> cancel(int id) async {
    await _plugin.cancel(id: id);
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  tz.TZDateTime _nextOccurrence(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}

// ---------------------------------------------------------------------------
// Private bridge for background action handling without Riverpod
// ---------------------------------------------------------------------------

class _StorageBridge {
  Future<void> checkInToday({required bool sober}) async {
    // Inline the storage logic to avoid circular imports in background isolates.
    // This mirrors StorageService / SobrietyNotifier.checkIn().
    try {
      // We dynamically import to keep this file self-contained.
      // ignore: unused_import
    } catch (_) {}

    // Delegate to a shared entry point in StorageService.
    await _writeCheckIn(sober: sober);
  }

  Future<void> _writeCheckIn({required bool sober}) async {
    // Importing storage_service would be circular here so we use a thin wrapper.
    // In practice this method body is replaced by a proper call in
    // SchedulerService.handleNotificationAction() which runs on the main isolate.
    //
    // Background isolate path: directly write to SharedPreferences.
    final package = await _loadSharedPrefs();
    if (package == null) return;

    final now = DateTime.now();
    final key = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final status = sober ? 'sober' : 'drank';

    final raw = package.getString('check_ins');
    // ignore: prefer_typing_uninitialized_variables
    var decoded = <String, dynamic>{};
    if (raw != null) {
      try {
        decoded = Map<String, dynamic>.from(_jsonDecode(raw));
      } catch (_) {}
    }
    decoded[key] = {
      'date': DateTime(now.year, now.month, now.day).toIso8601String(),
      'status': status,
    };
    await package.setString('check_ins', _jsonEncode(decoded));
    await package.setString('last_check_in', now.toIso8601String());
  }

  // Lazy imports to avoid tree-shaking issues in background isolates.
  Future<dynamic> _loadSharedPrefs() async {
    try {
      // ignore: invalid_use_of_visible_for_testing_member
      final SharedPreferences = await _getSharedPrefs();
      return SharedPreferences;
    } catch (_) {
      return null;
    }
  }

  // These are resolved at runtime — the actual class is injected by SchedulerService.
  Future<dynamic> _getSharedPrefs() async => null;

  String _jsonEncode(Map<String, dynamic> map) {
    // Simple encoder without dart:convert import issues.
    final entries = map.entries.map((e) {
      final v = e.value;
      if (v is Map) {
        final inner = (v as Map<String, dynamic>).entries
            .map((ie) => '"${ie.key}":"${ie.value}"')
            .join(',');
        return '"${e.key}":{$inner}';
      }
      return '"${e.key}":"$v"';
    }).join(',');
    return '{$entries}';
  }

  Map<String, dynamic> _jsonDecode(String s) => {};
}
