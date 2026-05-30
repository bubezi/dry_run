/// Central registry for all notification IDs and channel identifiers.
/// Never use magic numbers anywhere else — always reference these constants.
class NotificationRegistry {
  NotificationRegistry._();

  // ─── Notification IDs ──────────────────────────────────────────────────────
  static const int eveningCheckIn = 1;
  static const int missedCheckIn = 2;
  static const int dailyMotivation = 3;
  static const int streakMilestone = 4;
  static const int newDayPrompt = 5;

  // ─── Channel IDs ───────────────────────────────────────────────────────────
  static const String channelCheckIn = 'checkin';
  static const String channelMissed = 'missed';
  static const String channelMotivation = 'motivation';
  static const String channelMilestone = 'milestone';

  // ─── Channel Names (human-readable) ────────────────────────────────────────
  static const String channelCheckInName = 'Daily Check-in';
  static const String channelMissedName = 'Missed Check-ins';
  static const String channelMotivationName = 'Motivation';
  static const String channelMilestoneName = 'Milestones';

  // ─── Action IDs (notification button actions) ──────────────────────────────
  static const String actionSober = 'action_sober';
  static const String actionDrank = 'action_drank';

  // ─── Scheduled times ───────────────────────────────────────────────────────
  static const int eveningHour = 20;
  static const int eveningMinute = 0;
  static const int morningHour = 9;
  static const int morningMinute = 0;

  // ─── Milestone thresholds ──────────────────────────────────────────────────
  static const List<int> milestones = [3, 7, 14, 30, 60, 90, 180, 365];
}
