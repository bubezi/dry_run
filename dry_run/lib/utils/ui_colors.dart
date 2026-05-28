import 'package:flutter/material.dart';

Color streakColor(int streak) {
  if (streak >= 14) return const Color(0xFF2ECC71);
  if (streak >= 7) return const Color(0xFF27AE60);
  if (streak >= 3) return const Color(0xFFF39C12);
  return const Color(0xFFE74C3C);
}

Color modeColor(String mode) {
  switch (mode) {
    case "stable":
      return Colors.greenAccent;
    case "building":
      return Colors.blueAccent;
    case "recovery":
      return Colors.orangeAccent;
    default:
      return Colors.redAccent;
  }
}
