import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OnboardingScreen extends StatefulWidget {
  final Function(DateTime startDate) onComplete;

  const OnboardingScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  DateTime selectedDate = DateTime.now();

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatted = DateFormat('yyyy-MM-dd').format(selectedDate);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "When did your last drink happen?",
              style: TextStyle(fontSize: 24),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            Text(
              formatted,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: pickDate,
              child: const Text("Pick Date"),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onComplete(selectedDate);
                },
                child: const Text("Start Tracking"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}