import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── State ────────────────────────────────────────────────────────────────────

enum EmergencyPhase { idle, breathing, countdown, resolved }

class EmergencyState {
  final EmergencyPhase phase;
  final int secondsRemaining;
  final bool urgeAcknowledged;

  const EmergencyState({
    this.phase = EmergencyPhase.idle,
    this.secondsRemaining = 0,
    this.urgeAcknowledged = false,
  });

  EmergencyState copyWith({
    EmergencyPhase? phase,
    int? secondsRemaining,
    bool? urgeAcknowledged,
  }) {
    return EmergencyState(
      phase: phase ?? this.phase,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      urgeAcknowledged: urgeAcknowledged ?? this.urgeAcknowledged,
    );
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final emergencyProvider =
    StateNotifierProvider<EmergencyNotifier, EmergencyState>(
      (ref) => EmergencyNotifier(),
    );

// ─── Notifier ─────────────────────────────────────────────────────────────────

class EmergencyNotifier extends StateNotifier<EmergencyState> {
  EmergencyNotifier() : super(const EmergencyState());

  void trigger() {
    state = state.copyWith(
      phase: EmergencyPhase.breathing,
      secondsRemaining: 60,
      urgeAcknowledged: false,
    );
  }

  void advanceToCountdown() {
    state = state.copyWith(
      phase: EmergencyPhase.countdown,
      secondsRemaining: 60,
    );
  }

  void tickCountdown() {
    if (state.secondsRemaining <= 1) {
      state = state.copyWith(
        phase: EmergencyPhase.resolved,
        secondsRemaining: 0,
      );
    } else {
      state = state.copyWith(secondsRemaining: state.secondsRemaining - 1);
    }
  }

  void acknowledge() {
    state = state.copyWith(urgeAcknowledged: true);
  }

  void reset() {
    state = const EmergencyState();
  }
}
