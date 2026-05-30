import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/emergency_provider.dart';
import '../providers/sobriety_provider.dart';
import '../constants/quotes.dart';

class EmergencyScreen extends ConsumerStatefulWidget {
  const EmergencyScreen({super.key});

  @override
  ConsumerState<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends ConsumerState<EmergencyScreen>
    with TickerProviderStateMixin {
  // Breathing animation
  late AnimationController _breathController;
  late Animation<double> _breathScale;

  // Countdown timer
  Timer? _countdownTimer;

  // Random quote shown at the top
  late String _quote;

  @override
  void initState() {
    super.initState();

    final rng = Random();
    _quote = encouragementQuotes[rng.nextInt(encouragementQuotes.length)];

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _breathScale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    // Trigger the state machine
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(emergencyProvider.notifier).trigger();
      _scheduleAdvanceToCountdown();
    });
  }

  void _scheduleAdvanceToCountdown() {
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) {
        ref.read(emergencyProvider.notifier).advanceToCountdown();
        _startCountdownTimer();
      }
    });
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      ref.read(emergencyProvider.notifier).tickCountdown();
    });
  }

  @override
  void dispose() {
    _breathController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _callPartner() async {
    // Opens phone dialer — in production you'd load partner number from prefs
    final uri = Uri(scheme: 'tel', path: '');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final emergency = ref.watch(emergencyProvider);
    final notifier = ref.read(sobrietyProvider.notifier);
    final streak = notifier.computeStreak();

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F14),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () {
                    ref.read(emergencyProvider.notifier).reset();
                    Navigator.pop(context);
                  },
                  child: const Icon(Icons.close, color: Colors.white54, size: 28),
                ),
              ),

              const SizedBox(height: 12),

              // Quote
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Text(
                  _quote,
                  key: ValueKey(_quote),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Breathing orb
              _BreathingOrb(animation: _breathScale, phase: emergency.phase),

              const SizedBox(height: 28),

              // Phase-specific content
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: _phaseContent(emergency, streak),
              ),

              const Spacer(),

              // Streak reminder
              if (streak > 0) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.local_fire_department,
                          color: Color(0xFF2ECC71), size: 22),
                      const SizedBox(width: 8),
                      Text(
                        '$streak day streak — don\'t break it now.',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Call partner button
              OutlinedButton.icon(
                onPressed: _callPartner,
                icon: const Icon(Icons.phone_outlined, size: 18),
                label: const Text("Call accountability partner"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white60,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _phaseContent(EmergencyState emergency, int streak) {
    switch (emergency.phase) {
      case EmergencyPhase.breathing:
        return Column(
          key: const ValueKey('breathing'),
          children: const [
            Text(
              'Breathe.',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'The urge is temporary. Let it pass.',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        );

      case EmergencyPhase.countdown:
        final pct = emergency.secondsRemaining / 60.0;
        return Column(
          key: const ValueKey('countdown'),
          children: [
            Text(
              '${emergency.secondsRemaining}',
              style: const TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'seconds — urges peak and pass',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2ECC71)),
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
            ),
          ],
        );

      case EmergencyPhase.resolved:
        return Column(
          key: const ValueKey('resolved'),
          children: const [
            Icon(Icons.check_circle_outline,
                color: Color(0xFF2ECC71), size: 48),
            SizedBox(height: 12),
            Text(
              'You made it through.',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'The urge passed. It always does.',
              style: TextStyle(color: Colors.white54),
            ),
          ],
        );

      case EmergencyPhase.idle:
      default:
        return const SizedBox.shrink(key: ValueKey('idle'));
    }
  }
}

// ─── Breathing orb widget ─────────────────────────────────────────────────────

class _BreathingOrb extends StatelessWidget {
  final Animation<double> animation;
  final EmergencyPhase phase;

  const _BreathingOrb({required this.animation, required this.phase});

  @override
  Widget build(BuildContext context) {
    final isResolved = phase == EmergencyPhase.resolved;

    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        return Transform.scale(
          scale: isResolved ? 1.0 : animation.value,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: isResolved
                    ? [
                        const Color(0xFF2ECC71).withValues(alpha: 0.6),
                        const Color(0xFF1A4731).withValues(alpha: 0.2),
                      ]
                    : [
                        const Color(0xFF3498DB).withValues(alpha: 0.5),
                        const Color(0xFF0B1A2A).withValues(alpha: 0.2),
                      ],
              ),
            ),
            child: Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isResolved
                      ? const Color(0xFF2ECC71).withValues(alpha: 0.3)
                      : const Color(0xFF3498DB).withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
