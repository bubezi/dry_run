import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/storage_service.dart';
import 'providers/sobriety_provider.dart';

final onboardingFutureProvider = FutureProvider<bool>((ref) async {
  return await StorageService.isOnboardingDone();
});

class SoberApp extends ConsumerWidget {
  const SoberApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingAsync = ref.watch(onboardingFutureProvider);

    return onboardingAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const Scaffold(
        body: Center(child: Text("Error loading app")),
      ),
      data: (done) {
        if (!done) {
          return OnboardingScreen(
            onComplete: (startDate) async {
              final notifier =
                  ref.read(sobrietyProvider.notifier);

              notifier.initializeFromOnboarding(startDate);

              await StorageService.setOnboardingDone();
              ref.refresh(onboardingFutureProvider).value;
            },
          );
        }

        return const HomeScreen();
      },
    );
  }
}