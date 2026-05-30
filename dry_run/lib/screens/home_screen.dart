import 'package:dry_run/utils/ui_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/day_status.dart';
import '../providers/sobriety_provider.dart';
import '../providers/emergency_provider.dart';
import '../utils/date_utils.dart';
import 'history_screen.dart';
import 'emergency_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(sobrietyProvider.notifier);
    ref.watch(sobrietyProvider);

    final stats = notifier.computeStats();
    final needsYesterday = notifier.needsYesterdayCheckIn();
    final quote = notifier.dynamicMessage;
    final mode = notifier.behaviorMode;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Header ────────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Today",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateTime.now().toString().split(' ')[0],
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 13),
                      ),
                    ],
                  ),
                  // Emergency button — subtle but accessible
                  _EmergencyButton(),
                ],
              ),

              const SizedBox(height: 20),

              // ─── Main streak card ─────────────────────────────────────────
              _StreakCard(streak: stats.currentStreak),

              const SizedBox(height: 14),

              // ─── Stats row ─────────────────────────────────────────────────
              _StatsRow(stats: stats),

              const SizedBox(height: 14),

              // ─── Mood / mode card ─────────────────────────────────────────
              _MoodCard(quote: quote, mode: mode),

              const SizedBox(height: 14),

              // ─── Yesterday check-in ───────────────────────────────────────
              if (needsYesterday) ...[
                _YesterdayCard(notifier: notifier),
                const SizedBox(height: 14),
              ],

              // ─── History button ───────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const HistoryScreen()),
                    );
                  },
                  child: const Text("View History"),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Streak Card ──────────────────────────────────────────────────────────────

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
          const Text("Current streak", style: TextStyle(color: Colors.white70)),
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

// ─── Stats Row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final StreakStats stats;
  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: "Longest streak",
                value: "${stats.longestStreak}d",
                icon: Icons.emoji_events_outlined,
                iconColor: const Color(0xFFF39C12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                label: "Total sober days",
                value: "${stats.totalSoberDays}",
                icon: Icons.calendar_today_outlined,
                iconColor: const Color(0xFF3498DB),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _RecoveryTile(stats: stats),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

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
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecoveryTile extends StatelessWidget {
  final StreakStats stats;
  const _RecoveryTile({required this.stats});

  @override
  Widget build(BuildContext context) {
    final pct = stats.recoveryPercentage / 100;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                stats.recoveryLabel,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
              Text(
                stats.percentageLabel,
                style: const TextStyle(
                  color: Color(0xFF2ECC71),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(
                pct >= 0.8
                    ? const Color(0xFF2ECC71)
                    : pct >= 0.5
                        ? const Color(0xFFF39C12)
                        : const Color(0xFFE74C3C),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mood Card ────────────────────────────────────────────────────────────────

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
              style: TextStyle(color: modeColor(mode), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Yesterday Card ───────────────────────────────────────────────────────────

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
        border: Border.all(
          color: const Color(0xFFF39C12).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, color: Color(0xFFF39C12), size: 16),
              const SizedBox(width: 6),
              const Text(
                "Yesterday needs a check-in",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 12),
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

// ─── Emergency Button ─────────────────────────────────────────────────────────

class _EmergencyButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const EmergencyScreen(),
            transitionsBuilder: (_, anim, __, child) {
              return FadeTransition(opacity: anim, child: child);
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE74C3C).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE74C3C).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFFE74C3C),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              "I want to drink",
              style: TextStyle(
                color: Color(0xFFE74C3C),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
