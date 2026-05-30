import 'package:workmanager/workmanager.dart';
import 'package:dry_run/services/storage_service.dart';
import 'package:dry_run/services/notification_service.dart';

// ─── Constants ────────────────────────────────────────────────────────────────

const String dailyTask = "daily_check_task";

// ─── Background entry point ───────────────────────────────────────────────────

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == dailyTask) {
      await _runDailyCheck();
    }
    return Future.value(true);
  });
}

// ─── Daily check logic (background isolate safe) ──────────────────────────────

Future<void> _runDailyCheck() async {
  final notification = NotificationService();
  await notification.init(); // required in background isolate

  final lastCheckIn = await StorageService.getLastCheckIn();

  if (lastCheckIn != null) {
    final now = DateTime.now();
    final diff = now.difference(lastCheckIn).inDays;

    if (diff >= 2) {
      // User has not checked in for more than one full day
      await notification.showNewDayCheckInPrompt();
    }
  }

  // Always reschedule daily motivation in the background worker
  await notification.scheduleDailyMotivation();
}
