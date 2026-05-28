import 'package:dry_run/utils/ui_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/day_status.dart';
import '../providers/sobriety_provider.dart';
import '../utils/date_utils.dart';
import 'history_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(sobrietyProvider.notifier);
    ref.watch(sobrietyProvider);

    final streak = notifier.computeStreak();
    final needsYesterday = notifier.needsYesterdayCheckIn();
    final quote = notifier.dynamicMessage;
    final mode = notifier.behaviorMode;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Today",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 6),

              Text(
                DateTime.now().toString().split(' ')[0],
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
              ),

              const SizedBox(height: 25),

              _StreakCard(streak: streak),

              const SizedBox(height: 18),

              _MoodCard(quote: quote, mode: mode),

              const SizedBox(height: 18),

              if (needsYesterday) _YesterdayCard(notifier: notifier),

              const Spacer(),

              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  );
                },
                child: const Text("History"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final int streak;
  const _StreakCard({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            streakColor(streak).withValues(alpha: 0.8),
            const Color(0xFF0F2A1F),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Sober streak", style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 10),
          Text(
            "$streak",
            style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
          ),
          const Text("days", style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _MoodCard extends StatelessWidget {
  final String quote;
  final String mode;

  const _MoodCard({required this.quote, required this.mode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(quote),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: modeColor(mode).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              mode.toUpperCase(),
              style: TextStyle(color: modeColor(mode)),
            ),
          ),
        ],
      ),
    );
  }
}

class _YesterdayCard extends StatelessWidget {
  final dynamic notifier;

  const _YesterdayCard({required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Yesterday check-in"),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    notifier.checkIn(AppDateUtils.yesterday(), DayStatus.sober);
                  },
                  child: const Text("Sober"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    notifier.checkIn(AppDateUtils.yesterday(), DayStatus.drank);
                  },
                  child: const Text("Drank"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
