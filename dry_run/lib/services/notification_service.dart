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
}
