import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/quotes.dart';
import '../providers/sobriety_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(sobrietyProvider);

    final quote =
        encouragementQuotes[
          Random().nextInt(encouragementQuotes.length)
        ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              Text(
                '${data.currentStreak}',
                style: const TextStyle(
                  fontSize: 88,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const Text(
                'DAYS SOBER',
                style: TextStyle(
                  fontSize: 20,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 40),

              Text(
                quote,
                style: const TextStyle(
                  fontSize: 22,
                  color: Colors.white70,
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ref
                        .read(sobrietyProvider.notifier)
                        .checkInSober();
                  },
                  child: const Text("Stayed Sober Today"),
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    ref
                        .read(sobrietyProvider.notifier)
                        .checkInDrank();
                  },
                  child: const Text("I Drank"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}