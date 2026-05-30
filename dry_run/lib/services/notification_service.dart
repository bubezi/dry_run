import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(settings: initSettings);

    tz.initializeTimeZones();

    // 🔥 important
    tz.setLocalLocation(tz.getLocation('Africa/Nairobi'));
  }

  Future<void> scheduleEveningCheckIn() async {
    final now = DateTime.now();

    final scheduled = DateTime(now.year, now.month, now.day, 20, 0);

    await _plugin.zonedSchedule(
      id: 0,
      title: 'Evening Check-in',
      body: 'Did you stay sober today?',
      scheduledDate: tz.TZDateTime.from(scheduled, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'checkin',
          'Daily Check-in',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> showMissedDayReminder() async {
    await _plugin.show(
      id: 1,
      title: 'Missed Check-in',
      body: 'You didn’t log yesterday. Want to add it now?',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'missed',
          'Missed Check-ins',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }

  Future<void> scheduleDailyCheckIn() async {
    final now = DateTime.now();

    final scheduled = DateTime(now.year, now.month, now.day, 20, 0);

    final target = scheduled.isBefore(now)
        ? scheduled.add(const Duration(days: 1))
        : scheduled;

    await _plugin.zonedSchedule(
      id: 1, // id
      title: 'Evening Check-in', // title
      body: 'Did you stay sober today?', // body
      scheduledDate: tz.TZDateTime.from(target, tz.local), // scheduledDate
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'checkin',
          'Daily Check-in',
          importance: Importance.max,
          priority: Priority.high,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction('sober', 'Sober'),
            AndroidNotificationAction('drank', 'Drank'),
          ],
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleMotivation() async {
    final messages = [
      "Small wins still count.",
      "One clean decision is enough.",
      "Don’t restart the cycle today.",
      "Momentum beats motivation.",
      "You don’t need perfect. Just present.",
    ];

    messages.shuffle();

    final now = DateTime.now();

    final scheduled = DateTime(now.year, now.month, now.day, 10, 0);

    final target = scheduled.isBefore(now)
        ? scheduled.add(const Duration(days: 1))
        : scheduled;

    await _plugin.zonedSchedule(
      id: 10,
      title: "Daily Focus",
      body: messages.first,
      scheduledDate: tz.TZDateTime.from(target, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'motivation',
          'Motivation',
          importance: Importance.low,
          priority: Priority.low,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
