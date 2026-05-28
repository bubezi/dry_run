import 'dart:math';

import 'package:dry_run/screens/history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/day_status.dart';
import '../providers/sobriety_provider.dart';
import '../utils/date_utils.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sobrietyProvider);
    final notifier = ref.read(sobrietyProvider.notifier);

    final streak = notifier.computeStreak();
    final needsYesterday = notifier.needsYesterdayCheckIn();

    final quote = [
      "One day at a time.",
      "Momentum compounds.",
      "You don’t start over, you continue.",
      "Small wins stack.",
      "Progress beats perfection.",
    ][Random().nextInt(5)];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),

              Text(
                "$streak",
                style: const TextStyle(
                  fontSize: 90,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const Text("DAYS SOBER", style: TextStyle(letterSpacing: 2)),

              const SizedBox(height: 30),

              Text(
                quote,
                style: const TextStyle(fontSize: 20, color: Colors.white70),
              ),

              const SizedBox(height: 40),

              if (needsYesterday)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Did you stay sober yesterday?",
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              notifier.checkIn(
                                AppDateUtils.yesterday(),
                                DayStatus.sober,
                              );
                            },
                            child: const Text("Yes"),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton(
                            onPressed: () {
                              notifier.checkIn(
                                AppDateUtils.yesterday(),
                                DayStatus.drank,
                              );
                            },
                            child: const Text("No"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              const Spacer(),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HistoryScreen()),
                    );
                  },
                  child: const Text("View History"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
