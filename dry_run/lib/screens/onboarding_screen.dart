import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OnboardingScreen extends StatefulWidget {
  final Function(DateTime startDate) onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  DateTime selected = DateTime.now();

  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<double> _scale;

  bool _confirming = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDate: selected,
    );

    if (picked != null) {
      setState(() => selected = picked);

      // subtle “attention shift”
      _controller.forward(from: 0.85);
    }
  }

  Future<void> confirm() async {
    setState(() => _confirming = true);

    await Future.delayed(const Duration(milliseconds: 500));

    widget.onComplete(selected);
  }

  @override
  Widget build(BuildContext context) {
    final formatted = DateFormat('yyyy-MM-dd').format(selected);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "When did you last drink?",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 18),

                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          formatted,
                          key: ValueKey(formatted),
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      ElevatedButton(
                        onPressed: pickDate,
                        child: const Text("Change Date"),
                      ),

                      const SizedBox(height: 40),

                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _confirming ? null : confirm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _confirming
                                ? Colors.green.withValues(alpha: 0.4)
                                : Colors.green,
                          ),
                          child: _confirming
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text("Start"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}