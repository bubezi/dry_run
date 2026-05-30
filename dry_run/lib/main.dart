import 'package:dry_run/providers/background_provider.dart';
import 'package:dry_run/screens/splash_screen.dart';
import 'package:dry_run/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';
import 'services/notification_service.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService().init();

  Workmanager().initialize(
    callbackDispatcher,
  );

  Workmanager().registerPeriodicTask(
    "dailyTaskId",
    dailyTask,
    frequency: const Duration(hours: 6), // Android minimum is ~15 min but OS batches it
    constraints: Constraints(
      networkType: NetworkType.notRequired,
      requiresBatteryNotLow: false,
    ),
  );

  runApp(const ProviderScope(child: MyRoot()));
}

class MyRoot extends StatelessWidget {
  const MyRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Dry Run",
      theme: AppTheme.dark(),
      debugShowCheckedModeBanner: false,
      home: SplashScreen(next: const SoberApp()),
    );
  }
}
