import 'package:dry_run/providers/background_provider.dart';
import 'package:dry_run/providers/day_watcher_provider.dart';
import 'package:dry_run/screens/splash_screen.dart';
import 'package:dry_run/services/scheduler_service.dart';
import 'package:dry_run/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';
import 'services/notification_service.dart';
import 'utils/date_utils.dart';

import 'app.dart';

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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Start the in-app day watcher
      ref.read(dayWatcherProvider);

      final scheduler = ref.read(schedulerProvider);
      await scheduler.rebuildAll();
      await scheduler.handleAppForeground();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Sync the date provider in case the day changed while suspended
      final today = AppDateUtils.normalize(DateTime.now());
      final current = ref.read(currentDateProvider);
      if (today != current) {
        ref.read(currentDateProvider.notifier).state = today;
      }

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
