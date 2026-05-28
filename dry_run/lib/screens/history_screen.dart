import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/day_status.dart';
import '../providers/sobriety_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sobrietyProvider);
    final notifier = ref.read(sobrietyProvider.notifier);

    final history = state.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(title: const Text("History")),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: history.length,
        itemBuilder: (context, index) {
          final item = history[index];

          final isSober = item.status == DayStatus.sober;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isSober
                    ? Colors.green.withValues(alpha: 0.2)
                    : Colors.red.withValues(alpha: 0.2),
                child: Icon(
                  isSober ? Icons.check : Icons.close,
                  color: isSober ? Colors.green : Colors.red,
                ),
              ),
              title: Text(item.date.toString().split(' ')[0]),
              subtitle: Text(isSober ? "Sober" : "Drank"),
              onTap: () {
                notifier.checkIn(
                  item.date,
                  isSober ? DayStatus.drank : DayStatus.sober,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
