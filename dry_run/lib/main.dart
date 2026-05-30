import 'package:dry_run/providers/background_provider.dart';
import 'package:dry_run/screens/splash_screen.dart';
import 'package:dry_run/services/scheduler_service.dart';
import 'package:dry_run/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';
import 'services/notification_service.dart';

import 'app.dart';

// ─── App entry point ──────────────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService().init();

  Workmanager().initialize(callbackDispatcher);

  Workmanager().registerPeriodicTask(
    'dailyTaskId',
    dailyTask,
    frequency: const Duration(hours: 6),
    constraints: Constraints(
      networkType: NetworkType.notRequired,
      requiresBatteryNotLow: false,
    ),
  );

  runApp(const ProviderScope(child: MyRoot()));
}

// ─── Root widget ──────────────────────────────────────────────────────────────

class MyRoot extends ConsumerStatefulWidget {
  const MyRoot({super.key});

  @override
  ConsumerState<MyRoot> createState() => _MyRootState();
}

class _MyRootState extends ConsumerState<MyRoot> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Run after first frame so Riverpod providers are ready
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final scheduler = ref.read(schedulerProvider);
      // Initial setup: rebuild all scheduled notifications
      await scheduler.rebuildAll();
      // Check if a new day has arrived since last launch
      await scheduler.handleAppForeground();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Called whenever the app comes back to the foreground.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // New day detection on every foreground event
      ref.read(schedulerProvider).handleAppForeground();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dry Run',
      theme: AppTheme.dark(),
      debugShowCheckedModeBanner: false,
      home: SplashScreen(next: const SoberApp()),
    );
  }
}
