import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/day_status.dart';
import '../providers/sobriety_provider.dart';
import '../utils/date_utils.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  String label(DateTime date) {
    final now = DateTime.now();
    final d = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(d).inDays;

    if (diff == 0) return "Today";
    if (diff == 1) return "Yesterday";
    return "${date.year}-${date.month}-${date.day}";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(sobrietyProvider.notifier);
    final history = notifier.getSortedHistory();

    return Scaffold(
      appBar: AppBar(title: const Text("History")),
      body: ListView.builder(
        itemCount: history.length,
        itemBuilder: (context, index) {
          final item = history[index];

          Color color;
          String text;

          switch (item.status) {
            case DayStatus.sober:
              color = Colors.green;
              text = "Sober";
              break;
            case DayStatus.drank:
              color = Colors.red;
              text = "Drank";
              break;
            default:
              color = Colors.grey;
              text = "Unknown";
          }

          return ListTile(
            title: Text(label(item.date)),
            subtitle: Text(text),
            trailing: Icon(Icons.edit, color: color),
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (_) {
                  return Wrap(
                    children: [
                      ListTile(
                        title: const Text("Sober"),
                        onTap: () {
                          notifier.checkIn(item.date, DayStatus.sober);
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        title: const Text("Drank"),
                        onTap: () {
                          notifier.checkIn(item.date, DayStatus.drank);
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        title: const Text("Clear"),
                        onTap: () {
                          notifier.checkIn(item.date, DayStatus.unknown);
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
